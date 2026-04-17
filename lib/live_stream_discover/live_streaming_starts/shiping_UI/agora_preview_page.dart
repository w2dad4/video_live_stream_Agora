// Agora 预览页面 - 仅本地摄像头预览，不推流
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_live_stream/start_video/logic/agora_preview_service.dart';

/// Agora 视频预览页面
/// 
/// 功能：
/// ✅ 摄像头打开
/// ✅ 本地画面显示
/// ❌ 没有推流（仅预览）
class AgoraPreviewPage extends ConsumerStatefulWidget {
  const AgoraPreviewPage({super.key});

  @override
  ConsumerState<AgoraPreviewPage> createState() => _AgoraPreviewPageState();
}

class _AgoraPreviewPageState extends ConsumerState<AgoraPreviewPage> {
  @override
  void initState() {
    super.initState();
    // 页面加载时启动预览
    Future.microtask(() {
      ref.read(agoraPreviewProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    // 页面销毁时停止预览
    ref.read(agoraPreviewProvider.notifier).stopPreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewState = ref.watch(agoraPreviewProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: previewState.when(
        data: (state) {
          if (!state.isInitialized) {
            return const Center(
              child: Text('初始化中...', style: TextStyle(color: Colors.white)),
            );
          }

          // 显示 Agora 本地视频视图
          return ref.read(agoraPreviewProvider.notifier).getLocalVideoView();
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (err, _) => Center(
          child: Text('预览失败: $err', style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
