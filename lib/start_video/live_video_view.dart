import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_live_stream/start_video/logic/stream_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class LiveWebRTCPreview extends ConsumerWidget {
  final String roomID;
  const LiveWebRTCPreview({super.key, required this.roomID});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听推流状态
    final publishState = ref.watch(livePublisherProvider(roomID));
    // 监听 Notifier
    final notifier = ref.watch(livePublisherProvider(roomID).notifier);

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 绝对底层：无论推流是否成功，只要本地拿到画面就立刻显示！
          if (notifier.renderer != null) RTCVideoView(notifier.renderer!, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover, mirror: notifier.isFrontCamera),
          // 2. 状态遮罩层
          publishState.when(data: (_) => const SizedBox.shrink(), loading: () => _buildLoading(), error: (err, stack) => _buildErrorOverlay(ref, err)),
        ],
      ),
    );
  }

  // 🟢 核心修正：去除黑底，改为透明，不要挡住底层出来的摄像头画面
  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 20),
          // 使用半透明 Card 保证文字可读性，同时不挡全屏
          Card(
            color: Colors.black54,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('正在连接推流服务器...', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorOverlay(WidgetRef ref, Object err) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.black87, // 错误时才用黑底遮挡
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
            const SizedBox(height: 15),
            Text(
              '推流失败，但本地画面应可见\n$err',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              onPressed: () {
                ref.read(livePublisherProvider(roomID).notifier).retryPublishing();
              },
              child: const Text('重试连接服务器'),
            ),
          ],
        ),
      ),
    );
  }
}
