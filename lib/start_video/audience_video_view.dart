// Agora 观众拉流组件
import 'package:flutter/material.dart';
// 👀 使用新的观众服务
import 'package:video_live_stream/features/audience/logic/index.dart';

class AudienceInteractionPanel extends ConsumerWidget {
  final String audienceID;
  const AudienceInteractionPanel({super.key, required this.audienceID});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playState = ref.watch(audienceServiceProvider(audienceID));
    final notifier = ref.watch(audienceServiceProvider(audienceID).notifier);
    // ✅ 监听远端用户UID变化，触发重建
    final remoteUid = ref.watch(audienceRemoteUidProvider);

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 远端画面渲染层
          playState.when(
            data: (_) {
              final remoteView = notifier.getRemoteVideoView();
              if (remoteView != null) {
                return remoteView;
              }
              // 没有视频画面时显示等待状态
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 20),
                    Text(
                      remoteUid != null ? '正在加载画面...' : '等待主播上线...',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (err, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam_off, color: Colors.white, size: 50),
                  const SizedBox(height: 16),
                  const Text('主播暂时离开一下，请稍后哟', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => notifier.retryPlaying(),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                    child: const Text('点击重试'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
