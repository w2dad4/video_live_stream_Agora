// Agora 观众拉流组件
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_live_stream/start_video/logic/agora_service.dart';

class AudienceInteractionPanel extends ConsumerWidget {
  final String audienceID;
  const AudienceInteractionPanel({super.key, required this.audienceID});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playState = ref.watch(agoraAudienceServiceProvider(audienceID));
    final notifier = ref.watch(agoraAudienceServiceProvider(audienceID).notifier);

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
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text('等待主播上线...', style: TextStyle(color: Colors.white70)),
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
