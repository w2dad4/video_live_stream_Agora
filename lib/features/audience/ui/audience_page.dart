import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../logic/index.dart';

// ============================================
// 👀 观众端页面示例
// 使用完全独立的观众服务
// ============================================

/// 观众观看页面
class AudiencePage extends ConsumerWidget {
  final String roomId;
  const AudiencePage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 观众端专用 Provider
    final audienceAsync = ref.watch(audienceServiceProvider(roomId));
    final isPlaying = ref.watch(audiencePlayingProvider);
    final remoteUid = ref.watch(audienceRemoteUidProvider);

    return Scaffold(
      body: audienceAsync.when(
        data: (_) => _AudienceContent(roomId: roomId, isPlaying: isPlaying, remoteUid: remoteUid),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _OfflineView(error: err.toString()),
      ),
    );
  }
}

class _AudienceContent extends ConsumerWidget {
  final String roomId;
  final bool isPlaying;
  final int? remoteUid;

  const _AudienceContent({required this.roomId, required this.isPlaying, required this.remoteUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(audienceServiceProvider(roomId).notifier);
    final videoView = notifier.getRemoteVideoView();
    final hostInfo = ref.watch(hostInfoProvider);

    // ✅ 监听主播离开状态，自动跳转到结束页面
    ref.listen(hostLeftProvider, (previous, current) {
      if (current == true && context.mounted) {
        context.push(
          '/Conclude',
          extra: {
            'hostName': hostInfo?['hostName'] ?? '主播',
            'hostAvatar': hostInfo?['hostAvatar'],
            'roomId': roomId,
          },
        );
      }
    });

    return Column(
      children: [
        // 远端视频画面
        Expanded(
          child: Stack(
            children: [
              // 视频视图
              Positioned.fill(
                child:
                    videoView ??
                    const Center(
                      child: Text('等待主播推流...', style: TextStyle(color: Colors.white)),
                    ),
              ),
              // 状态指示器
              Positioned(
                top: 16,
                left: 16,
                child: _StatusBadge(isPlaying: isPlaying, remoteUid: remoteUid),
              ),
            ],
          ),
        ),
        // 控制栏
        _AudienceControls(isPlaying: isPlaying, onStop: () => notifier.stopPlaying()),
      ],
    );
  }
}

/// 状态指示器
class _StatusBadge extends StatelessWidget {
  final bool isPlaying;
  final int? remoteUid;

  const _StatusBadge({required this.isPlaying, required this.remoteUid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPlaying ? Icons.play_circle_fill : Icons.pause_circle_filled, color: isPlaying ? Colors.green : Colors.grey, size: 16),
          const SizedBox(width: 6),
          Text(isPlaying && remoteUid != null ? '观看中 • UID: $remoteUid' : '连接中...', style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

/// 控制栏
class _AudienceControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onStop;

  const _AudienceControls({required this.isPlaying, required this.onStop});

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
            // 退出观看
            _ControlButton(icon: Icons.exit_to_app, label: '退出', color: Colors.red, onTap: onStop),
            // 当前状态
            _ControlButton(
              icon: isPlaying ? Icons.visibility : Icons.visibility_off,
              label: isPlaying ? '观看中' : '已断开', //
              color: isPlaying ? Colors.green : Colors.grey,
              onTap: () {},
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

  // ignore: unused_element_parameter
  const _ControlButton({required this.icon, required this.label, required this.color, this.size = 48, required this.onTap});

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

/// 主播已下线提示视图
class _OfflineView extends StatelessWidget {
  final String error;

  const _OfflineView({required this.error});

  @override
  Widget build(BuildContext context) {
    final isOffline = error.contains('主播已下线');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isOffline ? Icons.videocam_off : Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            isOffline ? '主播已下线' : '连接失败',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(isOffline ? '请观看其他主播' : error, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('返回首页'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          ),
        ],
      ),
    );
  }
}
