import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/friend_request_provider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/friend_social_models.dart';

/// 扫一扫：解析猫猫号二维码并发起好友申请（需对方同意）
class ScanQrPage extends ConsumerStatefulWidget {
  const ScanQrPage({super.key});

  @override
  ConsumerState<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends ConsumerState<ScanQrPage> {
  bool _handled = false;

  void _onDetect(BarcodeCapture cap) {
    if (_handled) return;
    final raw = cap.barcodes.isEmpty ? null : cap.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    final payload = CatQrPayload.parse(raw);
    if (payload == null || payload.catId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('不是有效的小猫好友码')));
      }
      return;
    }
    _handled = true;
    _showAddConfirm(payload);
  }

  Future<void> _showAddConfirm(CatQrPayload payload) async {
    if (!mounted) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加好友'),
        content: Text('猫猫号：${payload.catId}\n昵称：${payload.name ?? "未知"}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('发送申请')),
        ],
      ),
    );
    if (go != true || !mounted) {
      setState(() => _handled = false);
      return;
    }
    final err = await ref.read(friendRequestListProvider.notifier).sendRequestToCatId(
          targetCatId: payload.catId,
          targetName: payload.name ?? payload.catId,
          targetAvatar: 'assets/image/002.png',
        );
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已发送好友申请，等待对方同意')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫一扫'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onDetect,
          ),
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Text(
              '对准好友的「小猫二维码」，识别后将发起添加申请',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), shadows: const [Shadow(blurRadius: 8)]),
            ),
          ),
        ],
      ),
    );
  }
}
