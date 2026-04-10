import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_live_stream/library.dart';

class VideoPreviewPage extends ConsumerWidget {
  const VideoPreviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraAsync = ref.watch(camersProvider);
    final cameraState = ref.watch(cameraStateProvider);
    final previewActive = ref.watch(previewCameraActiveProvider);

    // 【删除】：不再监听 processedFrameProvider

    cameraAsync.whenData((cameras) {
      if (previewActive && cameras.isNotEmpty && cameraState is AsyncLoading) {
        Future.microtask(() {
          ref.read(cameraStateProvider.notifier).initCamera(cameras.first);
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.black, // 建议预览背景设为黑色
      body: cameraAsync.when(
        data: (cameras) {
          if (!previewActive || cameras.isEmpty) return const SizedBox.expand();

          return cameraState.when(
            data: (controller) {
              // 【核心修复】：直接删除对 processedFrame 的渲染分支
              // 仅保留原生高性能的 CameraPreview
              final value = controller.value;
              if (!value.isInitialized) return const SizedBox();

              final size = MediaQuery.of(context).size;
              var scales = size.aspectRatio * value.aspectRatio;
              if (scales < 1) scales = 1 / scales;

              return Center(
                child: Transform.scale(scale: scales, child: CameraPreview(controller)),
              );
            },
            error: (err, _) => const Center(
              child: Text("摄像头列表失败", style: TextStyle(color: Colors.white)),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
          );
        },
        error: (err, _) => const Center(child: Text('摄像头出错')),
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }
}
