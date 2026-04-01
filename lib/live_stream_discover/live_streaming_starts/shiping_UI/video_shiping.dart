import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'package:video_live_stream/live_stream_discover/live_streaming_starts/logic_layer_data/beauty_provider.dart';
import 'package:video_live_stream/live_stream_discover/live_streaming_starts/logic_layer_data/logic_layer.dart';
import 'package:video_live_stream/live_stream_discover/select_Album/dialogbox.dart';
import 'package:video_live_stream/live_stream_discover/select_Album/select_Album.dart';
import 'package:video_live_stream/live_stream_discover/live_streaming_starts/shiping_UI/preview.dart';
import 'package:video_live_stream/start_video/beauty.dart';

//直播预览
final stars = StateProvider<bool>((ref) => false); // 美颜状态，默认为关闭
final sunmax = StateProvider<bool>((ref) => false); // 闪光灯状态，默认为关闭

class VideoShipingPage extends ConsumerWidget {
  const VideoShipingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取摄像头列表，用于传给 switchCamera 方法
    final starsState = ref.watch(stars); //用于监听美颜的颜色变化
    final bottomPadding = MediaQuery.of(context).size.height * 0.15;
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        const VideoPreviewPage(), //调用摄像头的预览组件
        const SelectAlbum(mode: LiveMode.video), //顶部封面，所有人可见，定位
        //封面
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomPadding,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center, //居中按钮
                children: [
                  //切换摄像头
                  _buildActionButton(
                    icon: CupertinoIcons.camera_viewfinder,
                    color: Colors.white,
                    onTap: () {
                      //点击后切换摄像头
                      debugPrint('点击后切换摄像头');
                      final cameras = ref.read(camersProvider).value;
                      if (cameras != null && cameras.isNotEmpty) {
                        ref
                            .read(cameraStateProvider.notifier)
                            .switchCamera(cameras);
                      } else {
                        debugPrint('摄像头未准备好');
                      }
                    },
                    label: '翻转',
                  ),
                  SizedBox(width: 15),
                  //美颜
                  _buildActionButton(
                    icon: CupertinoIcons.wand_stars,
                    color: starsState
                        ? Colors.pink
                        : Colors.white, //根据美颜状态改变图标颜色
                    onTap: () {
                      ref
                          .read(stars.notifier)
                          .update((state) => !state); //切换美颜状态
                      ref.read(beautyProvider.notifier).toggleBeauty();
                      if (!starsState) {
                        _showBeautyPanel(context);
                      }
                      debugPrint('点击了美颜');
                    },
                    label: '美颜',
                  ),
                  SizedBox(width: 15),
                  //闪光灯
                  _buildActionButton(
                    icon: ref
                        .watch(cameraStateProvider)
                        .maybeWhen(
                          data: (c) => c.value.flashMode == FlashMode.torch
                              ? CupertinoIcons
                                    .bolt_fill //
                              : CupertinoIcons.bolt_slash_fill,
                          orElse: () => CupertinoIcons.bolt_slash_fill,
                        ),
                    color: ref
                        .watch(cameraStateProvider)
                        .maybeWhen(
                          data: (c) => c.value.flashMode == FlashMode.torch
                              ? Colors.yellow
                              : Colors.white, //
                          orElse: () => Colors.white,
                        ), //根据闪光灯状态改变图标颜色
                    onTap: () {
                      ref
                          .read(cameraStateProvider.notifier)
                          .toggleFlash(); // 切换闪光灯模式
                      debugPrint('点击了闪光灯');
                    },
                    label: '闪光灯',
                  ),
                  SizedBox(width: 15),
                  //麦克风
                  _buildActionButton(
                    icon: ref.watch(isMicOpenProvider)
                        ? CupertinoIcons.mic_fill
                        : CupertinoIcons.mic_slash_fill, //
                    color: ref.read(isMicOpenProvider)
                        ? Colors.white
                        : Colors.redAccent,
                    label: '麦克风',
                    onTap: () => ref
                        .read(cameraStateProvider.notifier)
                        .toggleMicrophone(),
                  ),
                ],
              ),
              SizedBox(height: 20),
              // 1. 开始直播按钮（宽度设为屏幕的 80%）
              Center(child: StartVideo(width: screenWidth * 0.8)),
            ],
          ),
        ),
      ],
    );
  }

  //美颜弹出面板
  void _showBeautyPanel(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      isScrollControlled: true, //
      context: context,
      builder: (context) => const BeautyControlPanel(),
    );
  }

  //美颜
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? label,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Icon(icon, color: color, size: 23),
        ),
        Text(
          label ?? '',
          style: const TextStyle(
            color: Color.fromARGB(255, 242, 241, 241),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

//开始直播按钮
class StartVideo extends ConsumerWidget {
  final double width;
  const StartVideo({super.key, required this.width});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        //先弹出确认的弹窗
        final bool? shoulbEnter = await _enterthelivestream(context);
        //判断用户是否点击了开启直播
        if (shoulbEnter == true && context.mounted) {
          final liveId = ref.read(meProvider).uid ?? '';
          if (liveId.isEmpty) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('直播间ID为空，暂时无法直播')));
            }
            return;
          }
          final me = ref.read(meProvider);
          final title = ref.read(liveTitleProvider(LiveMode.video));
          final region = ref.read(positioningProvider(LiveMode.video));
          final cover = me.avatar ?? 'assets/image/002.png';
          // 关闭预览页会话开关，避免后台自动重启 camera 插件
          ref.read(previewCameraActiveProvider.notifier).state = false;
          // 关键：释放 camera 插件占用的摄像头，避免与 WebRTC 抢占导致黑屏
          await ref.read(cameraStateProvider.notifier).releaseCamera();
          if (!context.mounted) return;
          // 释放 camera 插件的摄像头，避免和 WebRTC 冲突
          ref
              .read(liverecommendProvider.notifier)
              .startUpdata(
                liveID: liveId,
                hostname: me.name ?? '主播',
                title: title.isEmpty ? '${me.name ?? '主播'}的直播间' : title, //
                cover: cover,
                region: region,
              );
          if (!context.mounted) return;
          // 跳转到直播间
          context.pushNamed(
            'StartVideo',
            extra: {"id": liveId, 'isHost': true},
          );
        }
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            colors: [Colors.redAccent, Colors.red],
          ),
        ),
        width: width,
        height: 50,
        child: Text(
          '开启视频直播',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  //进入直播的一个弹窗
  Future<bool?> _enterthelivestream(BuildContext context) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('开始视频直播'),
        content: const Text('即将进入直播间开启直播，请确认网络状态良好。'),
        actions: [
          CupertinoDialogAction(
            child: const Text('我再想想'),
            onPressed: () => context.pop(false),
          ),
          CupertinoDialogAction(
            child: const Text('确认进入'),
            onPressed: () => context.pop(true),
          ),
        ],
      ),
    );
  }
}
