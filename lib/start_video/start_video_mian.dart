import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'package:video_live_stream/live_stream_discover/live_streaming_starts/logic_layer_data/logic_layer.dart';
import 'package:video_live_stream/start_video/audience_video_view.dart';
import 'package:video_live_stream/start_video/chat_view.dart';
import 'package:video_live_stream/start_video/live_video_view.dart';
import 'package:video_live_stream/start_video/room_manager_logic.dart';

//定义消息模型
class ChatsMessage {
  final String uid;
  final String userName; //发消息的名字
  final String content; //发消息的内容
  ChatsMessage({required this.uid, required this.userName, required this.content});
}

// 🟢 抛弃 StatefulWidget，使用最轻量的 ConsumerWidget
class StartVideoPage extends HookConsumerWidget {
  final String isHost; // 通过 GoRouter 路由参数判断：是主播开播还是观众进入
  final String liveID;

  const StartVideoPage({super.key, required this.liveID, required this.isHost});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 获取清屏状态和角色身份
    final isCleanMode = ref.watch(isCleanModeProvider);
    final bool hostMode = isHost == 'true';
    final hostCameraReady = useState<bool>(!hostMode);

    // 2. 🟢 通过 liveID 动态获取当前房间数据，替代原来错误的构造函数传参
    final liveInfo = ref.watch(liveDataProvider(liveID));
    final String currentRoomID = liveInfo.liveID;

    // 3. 监听踢出名单：如果当前用户 UID 在踢出名单中，GoRouter 强制弹回上一页
    ref.listen(kickedUsersProvider, (previous, next) {
      final myUid = ref.read(meProvider).uid;
      if (next.contains(myUid)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('您已被管理员移出该房间内')));
        if (context.mounted) context.pop(); // GoRouter 路由返回
      }
    });
    //4. 计时器逻辑 如果是主播，进入页面即开始计时
    useEffect(() {
      if (!hostMode) return null;
      final timer = Timer.periodic(const Duration(seconds: 1), (t) {
        ref.read(liveSecondsProvider.notifier).update((state) => state + 1);
      });
      return () => timer.cancel(); //退出直播间自动销毁计时器
    }, []);

    // 进入直播间前先确保 camera 插件完全释放，避免和 WebRTC 抢占相机
    useEffect(() {
      if (!hostMode) return null;
      var cancelled = false;
      Future<void>(() async {
        ref.read(previewCameraActiveProvider.notifier).state = false;
        await ref.read(cameraStateProvider.notifier).releaseCamera();
        await Future<void>.delayed(const Duration(milliseconds: 200));
        if (!cancelled) {
          hostCameraReady.value = true;
        }
      });
      return () {
        cancelled = true;
      };
    }, [hostMode]);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (hostMode) {
          return;
        }
        final shouldPop = await _showExitConfirmDialog(context);
        if (shouldPop == true && context.mounted) {
          context.pop();
        }
      },

      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. 核心渲染层：WebRTC 预览 (完全独立，不参与 UI 层重绘)
            hostMode ? (hostCameraReady.value ? LiveWebRTCPreview(roomID: currentRoomID) : const _PreparingCameraView()) : AudienceInteractionPanel(audienceID: currentRoomID),
            // 2. 交互层UI：添加平滑的透明度动画
            AnimatedOpacity(
              opacity: isCleanMode ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: isCleanMode,
                child: Stack(
                  children: [
                    // 顶部主播信息
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 20,
                      child: LiveRoomComponents(info: liveInfo),
                    ),
                    // 聊天区域
                    Positioned(
                      bottom: 0,
                      left: 10,
                      right: 10,
                      child: LiveChatOverlay(isHost: hostMode, roomID: currentRoomID),
                    ),
                    //右上的一个关闭直播按钮
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () async {
                          // 点击按钮时弹出对话框
                          final bool? shouldExit = await _showExitConfirmDialog(context);
                          if (shouldExit == true && context.mounted) {
                            // 🟢 核心逻辑：当前时间 减去 已经直播的秒数 = 开播时刻
                            final int intsecondsPlayed = ref.read(liveSecondsProvider);
                            final DateTime startMoment = DateTime.now().subtract(Duration(seconds: intsecondsPlayed));
                            if (hostMode) {
                              ref.read(liverecommendProvider.notifier).stop(currentRoomID);
                            }
                            // 只有点击“确认退出”，才执行真正的路由跳转
                            context.pushNamed(
                              'End',
                              extra: {
                                'id': currentRoomID,
                                //把计算好的当前时间传递给子页面
                                'startTime': startMoment,
                              },
                            );
                          }
                        },
                        child: Icon(Icons.adjust, color: const Color.fromARGB(255, 170, 37, 37)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 返回弹出窗
  Future<bool?> _showExitConfirmDialog(BuildContext context) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('退出直播'),
        content: const Text('确定要结束当前的直播吗？'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消退出', style: TextStyle(color: Colors.blue)),
            onPressed: () => context.pop(false), // GoRouter 关闭弹窗
          ),
          CupertinoDialogAction(isDestructiveAction: true, child: const Text('确认退出'), onPressed: () => context.pop(true)),
        ],
      ),
    );
  }
}

class _PreparingCameraView extends StatelessWidget {
  const _PreparingCameraView();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
