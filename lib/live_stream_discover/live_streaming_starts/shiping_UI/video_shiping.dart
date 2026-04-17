import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/live_stream_discover/live_streaming_starts/shiping_UI/agora_preview_page.dart';
import 'package:video_live_stream/start_video/logic/agora_preview_service.dart';
import 'package:video_live_stream/library.dart';

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
        const AgoraPreviewPage(), // Agora 摄像头预览（仅预览，不推流）
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
                      // Agora 切换摄像头
                      debugPrint('Agora: 切换摄像头');
                      ref.read(agoraPreviewProvider.notifier).switchCamera();
                    },
                    label: '翻转',
                  ),
                  SizedBox(width: 15),
                  //美颜
                  _buildActionButton(
                    icon: CupertinoIcons.wand_stars,
                    color: starsState ? Colors.pink : Colors.white, //根据美颜状态改变图标颜色
                    onTap: () {
                      ref.read(stars.notifier).update((state) => !state); //切换美颜状态
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
                    icon: CupertinoIcons.bolt_slash_fill,
                    color: Colors.white,
                    onTap: () {
                      // Agora 切换闪光灯
                      ref.read(agoraPreviewProvider.notifier).toggleFlash();
                      debugPrint('Agora: 切换闪光灯');
                    },
                    label: '闪光灯',
                  ),
                  SizedBox(width: 15),
                  //麦克风
                  _buildActionButton(
                    icon: ref.watch(agoraPreviewProvider).maybeWhen(data: (s) => s.isMicOn ? CupertinoIcons.mic_fill : CupertinoIcons.mic_slash_fill, orElse: () => CupertinoIcons.mic_fill),
                    color: ref.watch(agoraPreviewProvider).maybeWhen(data: (s) => s.isMicOn ? Colors.white : Colors.redAccent, orElse: () => Colors.white),
                    label: '麦克风',
                    onTap: () => ref.read(agoraPreviewProvider.notifier).toggleMicrophone(),
                  ),
                  //画质切换 - 预览页面可选择，默认原画
                  SizedBox(width: 15),
                  _buildActionButton(
                    icon: CupertinoIcons.arrowtriangle_right_square,
                    color: Colors.white,
                    onTap: () => _showQualityPicker(context, ref),
                    label: ref.watch(agoraPreviewProvider).maybeWhen(data: (s) => s.quality.name, orElse: () => '超清'), // 显示当前选择的画质名称
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

  //画质选择弹出面板
  void _showQualityPicker(BuildContext context, WidgetRef ref) {
    final currentQuality = ref.read(currentQualityProvider);

    showModalBottomSheet(
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: ListView(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '选择画质',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              ...LiveQuality.values.map(
                (quality) => ListTile(
                  leading: Icon(quality == currentQuality ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle, color: quality == currentQuality ? Colors.blueAccent : Colors.white70),
                  title: Text(quality.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(_getQualityDescription(quality), style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                  onTap: () {
                    ref.read(currentQualityProvider.notifier).state = quality;
                    debugPrint('选择画质: ${quality.name}');
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _getQualityDescription(LiveQuality quality) {
    return switch (quality) {
      LiveQuality.sd360p => '360P • 流畅省流',
      LiveQuality.sd480p => '480P • 标清',
      LiveQuality.sd720p => '720P • 高清',
      LiveQuality.fhd1080p => '1080P • 超清',
      LiveQuality.original => '使用手机摄像头原画',
    };
  }

  //美颜
  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onTap, String? label}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Icon(icon, color: color, size: 23),
        ),
        Text(label ?? '', style: const TextStyle(color: Color.fromARGB(255, 242, 241, 241), fontSize: 10)),
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
          final me = ref.read(meProvider);
          final liveId = me?.uid ?? '';
          if (liveId.isEmpty) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('直播间ID为空，暂时无法直播')));
            }
            return;
          }
          final title = ref.read(liveTitleProvider(LiveMode.video));
          final region = ref.read(positioningProvider(LiveMode.video));
          final cover = me?.avatar ?? 'assets/image/002.png';
          // 停止 Agora 预览，释放资源
          await ref.read(agoraPreviewProvider.notifier).stopPreview();
          if (!context.mounted) return;
          ref
              .read(liverecommendProvider.notifier)
              .startUpdata(
                liveID: liveId,
                hostname: me?.name ?? '主播',
                title: title.isEmpty ? (me?.name ?? '主播') : title,
                cover: cover,
                region: region,
              );
          if (!context.mounted) return;
          // 跳转到直播间，并标记自动开播
          context.pushNamed('StartVideo', extra: {"id": liveId, 'isHost': true, 'autoStart': true});
        }
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(colors: [Colors.redAccent, Colors.red]),
        ),
        width: width,
        height: 50,
        child: Text('开启视频直播', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
          CupertinoDialogAction(child: const Text('我再想想'), onPressed: () => context.pop(false)),
          CupertinoDialogAction(child: const Text('确认进入'), onPressed: () => context.pop(true)),
        ],
      ),
    );
  }
}
