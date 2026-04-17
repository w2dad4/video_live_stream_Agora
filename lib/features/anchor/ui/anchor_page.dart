import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/index.dart';

// ============================================
// 🎤 主播端页面示例
// 使用完全独立的主播服务
// ============================================

/// 主播直播页面
class AnchorPage extends ConsumerWidget {
  final String roomId;
  const AnchorPage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 主播端专用 Provider
    final anchorAsync = ref.watch(anchorServiceProvider(roomId));
    final isPublishing = ref.watch(anchorPublishingProvider);
    final quality = ref.watch(anchorQualityProvider);
    final micEnabled = ref.watch(anchorMicEnabledProvider);

    return Scaffold(
      body: anchorAsync.when(
        data: (_) => _AnchorContent(
          roomId: roomId,
          isPublishing: isPublishing,
          quality: quality,
          micEnabled: micEnabled,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('初始化失败: $err')),
      ),
    );
  }
}

class _AnchorContent extends ConsumerWidget {
  final String roomId;
  final bool isPublishing;
  final AnchorLiveQuality quality;
  final bool micEnabled;

  const _AnchorContent({
    required this.roomId,
    required this.isPublishing,
    required this.quality,
    required this.micEnabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(anchorServiceProvider(roomId).notifier);

    return Column(
      children: [
        // 本地视频预览/推流画面
        Expanded(
          child: Stack(
            children: [
              // 视频视图
              Positioned.fill(
                child: notifier.getLocalVideoView(),
              ),
              // 状态指示器
              Positioned(
                top: 16,
                left: 16,
                child: _StatusBadge(
                  isPublishing: isPublishing,
                  quality: quality,
                  micEnabled: micEnabled,
                ),
              ),
            ],
          ),
        ),
        // 控制栏
        _AnchorControls(
          isPublishing: isPublishing,
          micEnabled: micEnabled,
          onTogglePublish: () {
            if (isPublishing) {
              notifier.stopPublishing();
            } else {
              notifier.startPublishing();
            }
          },
          onToggleMic: () => notifier.toggleMicrophone(),
        ),
      ],
    );
  }
}

/// 状态指示器
class _StatusBadge extends StatelessWidget {
  final bool isPublishing;
  final AnchorLiveQuality quality;
  final bool micEnabled;

  const _StatusBadge({
    required this.isPublishing,
    required this.quality,
    required this.micEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublishing ? Icons.live_tv : Icons.videocam_off,
            color: isPublishing ? Colors.red : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isPublishing ? '直播中 • ${quality.name}' : '预览中 • ${quality.name}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(width: 6),
          Icon(
            micEnabled ? Icons.mic : Icons.mic_off,
            color: micEnabled ? Colors.green : Colors.red,
            size: 16,
          ),
        ],
      ),
    );
  }
}

/// 控制栏
class _AnchorControls extends StatelessWidget {
  final bool isPublishing;
  final bool micEnabled;
  final VoidCallback onTogglePublish;
  final VoidCallback onToggleMic;

  const _AnchorControls({
    required this.isPublishing,
    required this.micEnabled,
    required this.onTogglePublish,
    required this.onToggleMic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 麦克风控制
            _ControlButton(
              icon: micEnabled ? Icons.mic : Icons.mic_off,
              label: micEnabled ? '麦开' : '麦关',
              color: micEnabled ? Colors.green : Colors.red,
              onTap: onToggleMic,
            ),
            // 推流控制
            _ControlButton(
              icon: isPublishing ? Icons.stop_circle : Icons.play_circle_fill,
              label: isPublishing ? '停止' : '开始直播',
              color: isPublishing ? Colors.red : Colors.green,
              size: 64,
              onTap: onTogglePublish,
            ),
          ],
        ),
      ),
    );
  }
}

/// 控制按钮
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: size),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
