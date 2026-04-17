// Agora 主播本地预览组件
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 🎤 使用新的主播服务
import 'package:video_live_stream/features/anchor/logic/index.dart';

class LiveAgoraPreview extends ConsumerWidget {
  final String roomID;
  const LiveAgoraPreview({super.key, required this.roomID});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听推流状态
    final publishState = ref.watch(anchorServiceProvider(roomID));
    // 监听 Notifier
    final notifier = ref.watch(anchorServiceProvider(roomID).notifier);

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Agora 本地视频预览
          publishState.when(
            data: (_) => notifier.getLocalVideoView(),
            loading: () => _buildLoading(),
            error: (err, stack) => _buildErrorOverlay(ref, err),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 20),
          Card(
            color: Colors.black54,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('正在连接声网服务器...', style: TextStyle(color: Colors.white)),
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
        color: Colors.black87,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
            const SizedBox(height: 15),
            Text(
              '推流失败\n$err',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              onPressed: () {
                ref.read(anchorServiceProvider(roomID).notifier).retryPublishing();
              },
              child: const Text('重试连接'),
            ),
          ],
        ),
      ),
    );
  }
}
