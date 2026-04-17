import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'package:video_live_stream/start_video/audience_video_view.dart';
import 'package:video_live_stream/start_video/chat_view.dart';
import 'package:video_live_stream/start_video/live_video_view.dart';
import 'package:video_live_stream/start_video/room_manager_logic.dart';
import 'package:video_live_stream/features/anchor/logic/index.dart';

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
  final bool autoStart; // 是否自动开播（从预览页进入时为true）

  const StartVideoPage({super.key, required this.liveID, required this.isHost, this.autoStart = false});

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
      final me = ref.read(meProvider);
      if (me == null) return;
      final myUid = me.uid;
      if (myUid != null && next.contains(myUid)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('您已被管理员移出该房间内')));
        if (context.mounted) context.pop(); // GoRouter 路由返回
      }
    });
    // 4. 自动开播逻辑（从预览页进入时）
    useEffect(() {
      if (hostMode && autoStart) {
        // 延迟一点等待引擎初始化完成
        Future.delayed(const Duration(milliseconds: 500), () async {
          final notifier = ref.read(anchorServiceProvider(currentRoomID).notifier);
          await notifier.startPublishing();
        });
      }
      return null;
    }, [autoStart, hostMode, currentRoomID]);

    //5. 计时器逻辑 如果是主播，进入页面即开始计时
    useEffect(() {
      if (!hostMode) return null;
      final timer = Timer.periodic(const Duration(seconds: 1), (t) {
        ref.read(liveSecondsProvider.notifier).update((state) => state + 1);
      });
      return () => timer.cancel(); //退出直播间自动销毁计时器
    }, []);

    // 进入直播间前确保资源就绪
    useEffect(() {
      if (!hostMode) return null;
      var cancelled = false;
      Future<void>(() async {
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
            // 1. 核心渲染层：Agora 预览 (完全独立，不参与 UI 层重绘)
            hostMode ? (hostCameraReady.value ? LiveAgoraPreview(roomID: currentRoomID) : const _PreparingCameraView()) : AudienceInteractionPanel(audienceID: currentRoomID),
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
                      child: LiveRoomComponents(info: liveInfo, isHost: hostMode),
                    ),
                    // 直播状态指示器（主播模式显示）
                    if (hostMode)
                      Positioned(
                        bottom: 120,
                        left: 50,
                        right: 50,
                        child: Consumer(
                          builder: (context, ref, child) {
                            final isPublishing = ref.watch(anchorPublishingProvider);
                            final anchorService = ref.watch(anchorServiceProvider(currentRoomID));
                            return anchorService.when(
                              data: (_) => isPublishing ? const SizedBox.shrink() : const SizedBox.shrink(),
                              loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                              error: (_, _) => ElevatedButton.icon(
                                onPressed: () async {
                                  final notifier = ref.read(anchorServiceProvider(currentRoomID).notifier);
                                  await notifier.retryPublishing();
                                },
                                icon: const Icon(Icons.refresh, color: Colors.white),
                                label: const Text('重新连接', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              ),
                            );
                          },
                        ),
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
                            if (hostMode) {
                              // 🟢 主播：跳转到结束页面
                              final int intsecondsPlayed = ref.read(liveSecondsProvider);
                              final DateTime startMoment = DateTime.now().subtract(Duration(seconds: intsecondsPlayed));
                              ref.read(liverecommendProvider.notifier).stop(currentRoomID);
                              context.pushNamed(
                                'End',
                                extra: {
                                  'id': currentRoomID,
                                  'startTime': startMoment,
                                },
                              );
                            } else {
                              // 👀 观众：直接返回列表页
                              context.pop();
                            }
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
