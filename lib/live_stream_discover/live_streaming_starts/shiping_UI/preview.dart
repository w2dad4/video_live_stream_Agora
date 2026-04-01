//直播预览
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_live_stream/live_stream_discover/live_streaming_starts/logic_layer_data/logic_layer.dart';

class VideoPreviewPage extends ConsumerWidget {
  const VideoPreviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 获取摄像头列表状态 (FutureProvider)
    final cameraAsync = ref.watch(camersProvider);
    // 2. 获取当前的相机控制器状态 (StateNotifierProvider)
    final cameraState = ref.watch(cameraStateProvider);
    // 3. 监听美颜处理后的字节流
    final processedFrame = ref.watch(processedFrameProvider);
    // 4. 预览页相机会话开关（用于避免后台重启摄像头）
    final previewActive = ref.watch(previewCameraActiveProvider);
    // 自动初始化逻辑：当摄像头列表加载成功且控制器还未初始化时，触发初始化
    cameraAsync.whenData((cameras) {
      if (previewActive && cameras.isNotEmpty && cameraState is AsyncLoading) {
        Future.microtask(() {
          ref.read(cameraStateProvider.notifier).initCamera(cameras.first);
        });
      }
    });
    return Scaffold(
      backgroundColor: Colors.white,
      body: cameraAsync.when(
        data: (cameras) {
          if (!previewActive) {
            return const SizedBox.expand();
          }
          if (cameras.isEmpty) {
            return Center(child: Text('未找到摄像头'));
          }
          return cameraState.when(
            data: (controller) {
              // 如果有处理后的美颜帧，显示处理后的图片，否则显示原生预览
              if (processedFrame != null) {
                return Image.memory(
                  processedFrame,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  gaplessPlayback: true, //关键：防止每一帧切换时的闪烁
                );
              }
              // 2. 如果美颜未开启或没数据，显示原生预览
              final value = controller.value;
              if (!value.isInitialized || value.previewSize == null) {
                return const SizedBox();
              }
              //获取屏幕尺寸
              final size = MediaQuery.of(context).size;
              //计算屏幕宽高比
              var scales = size.aspectRatio * value.aspectRatio;
              //如果缩放比例
              if (scales < 1) scales = 1 / scales;
              return Center(
                child: Transform.scale(
                  scale: scales,
                  child: CameraPreview(controller),
                ),
              );
            },
            error: (err, _) => Center(child: Text("获取摄像头列表失败")),
            loading: () => const Center(child: CircularProgressIndicator()),
          );
        },
        error: (err, _) => Center(child: Text('摄像头出错')),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }
}
