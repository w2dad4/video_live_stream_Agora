//负责观众内容
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_live_stream/start_video/logic/stream_player_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class AudienceInteractionPanel extends ConsumerWidget {
  final String audienceID;
  const AudienceInteractionPanel({super.key, required this.audienceID});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playState = ref.watch(streamPlayerServiceProvider(audienceID));
    final notifier = ref.watch(streamPlayerServiceProvider(audienceID).notifier);
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 远端画面渲染层
          if (notifier.renderer != null)
            RTCVideoView(
              notifier.renderer!, //
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              mirror: false,
            ),
          // 2. 状态遮罩层
          playState.when(
            data: (_) => const SizedBox.shrink(),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stcak) => Center(
              child: Column(
                children: [
                  const Icon(Icons.videocam_off, color: Colors.white, size: 20),
                  const SizedBox(width: 50),
                  const Text('主播暂时离开一下，请稍后哟', style: TextStyle(color: Colors.white)),
                  TextButton(
                    onPressed: () => notifier.retryPlaying(),
                    child: Text('点击重试', style: TextStyle(color: Colors.pinkAccent)),
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
