import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:video_live_stream/live_stream_discover/live_streaming_starts/logic_layer_data/beauty_provider.dart';
import 'package:video_live_stream/live_stream_discover/live_streaming_starts/logic_layer_data/filter_Group.dart';

// 1. 硬件状态 Providers (全部抽离)

// 摄像头列表
final camersProvider = FutureProvider<List<CameraDescription>>((ref) async {
  return await availableCameras();
});

// 麦克风状态 (独立抽离)
final isMicOpenProvider = StateProvider<bool>((ref) => true);

// 闪光灯状态 (独立抽离)
final isFlashOnProvider = StateProvider<bool>((ref) => false);

// 实时美颜处理后的画面帧
final processedFrameProvider = StateProvider<Uint8List?>((ref) => null);
// 预览页相机会话开关（进入直播间前置为 false，防止后台重开）
final previewCameraActiveProvider = StateProvider<bool>((ref) => true);

// 2. 核心逻辑控制器
class CameraControllerNotifier
    extends StateNotifier<AsyncValue<CameraController>> {
  CameraControllerNotifier(this.ref) : super(const AsyncValue.loading()) {
    ref.listen<BeautySettings>(beautyProvider, (previous, next) {
      final oldEnabled = previous?.isEnable ?? false;
      if (oldEnabled != next.isEnable) {
        _syncBeautyStream(next.isEnable);
      }
    });
  }

  final Ref ref;
  CameraController? _controller;
  int _camIndex = 0;
  bool _isProcessing = false;
  bool _isInitializing = false;

  // 【核心功能】：初始化/重启相机
  Future<void> initCamera(
    CameraDescription camera, {
    bool isSilent = false,
  }) async {
    if (_isInitializing) return;
    _isInitializing = true;

    final oldController = _controller;
    _controller = null;
    _isProcessing = false;
    ref.read(processedFrameProvider.notifier).state = null;
    state = const AsyncValue.loading();

    if (oldController != null) {
      await _disposeController(oldController);
    }

    final bool enableAudio = ref.read(isMicOpenProvider);
    final nextController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.bgra8888,
    );

    try {
      await nextController.initialize();
      // 初始化后，同步闪光灯状态
      if (ref.read(isFlashOnProvider) &&
          camera.lensDirection == CameraLensDirection.back) {
        await nextController.setFlashMode(FlashMode.torch);
      } else {
        ref.read(isFlashOnProvider.notifier).state = false;
      }
      _controller = nextController;
      // 美颜开启时才启动分析流，避免常驻双 Surface
      if (ref.read(beautyProvider).isEnable) {
        _startLiveBeautyStream();
      } else {
        ref.read(processedFrameProvider.notifier).state = null;
      }
      state = AsyncValue.data(nextController);
    } catch (e, stack) {
      await _disposeController(nextController);
      state = AsyncValue.error(e, stack);
    } finally {
      _isInitializing = false;
    }
  }

  // 【修复】：摄像头切换逻辑
  Future<void> switchCamera(List<CameraDescription> cameras) async {
    if (cameras.isEmpty || cameras.length < 2) {
      debugPrint('没有摄像头可以切换');
      return;
    }
    _camIndex = (_camIndex + 1) % cameras.length;
    await initCamera(cameras[_camIndex], isSilent: true);
  }

  // 【抽离逻辑 A】：麦克风控制
  Future<void> toggleMicrophone() async {
    if (_controller == null) return;

    // 1. 更新独立状态
    final currentState = ref.read(isMicOpenProvider);
    ref.read(isMicOpenProvider.notifier).state = !currentState;

    // 2. 硬件层响应：由于原生插件限制，通过 initCamera 重新应用 enableAudio
    await initCamera(_controller!.description, isSilent: true);
  }

  // 【抽离逻辑 B】：闪光灯控制
  Future<void> toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final bool isNowOn = ref.read(isFlashOnProvider);
      final newMode = isNowOn ? FlashMode.off : FlashMode.torch;

      await _controller!.setFlashMode(newMode);
      // 更新独立状态
      ref.read(isFlashOnProvider.notifier).state = !isNowOn;
      // 刷新控制器状态以通知 UI
      state = AsyncValue.data(_controller!);
    } catch (e) {
      debugPrint('闪光灯切换失败: $e');
    }
  }

  // 【核心功能】：OpenCV 美颜流
  void _startLiveBeautyStream() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    controller.startImageStream((CameraImage image) async {
      if (_isProcessing || !ref.read(beautyProvider).isEnable) return;
      _isProcessing = true;

      cv.Mat? rawMat;
      cv.Mat? actualMat;
      cv.Mat? bgrMat;
      cv.Mat? processedMat;

      try {
        final plane = image.planes[0];
        if (image.format.group == ImageFormatGroup.bgra8888) {
          rawMat = cv.Mat.fromList(
            image.height,
            plane.bytesPerRow ~/ 4,
            cv.MatType.CV_8UC4,
            plane.bytes,
          );
          actualMat = rawMat.region(cv.Rect(0, 0, image.width, image.height));
          bgrMat = cv.cvtColor(actualMat, cv.COLOR_BGRA2BGR);

          final isFront =
              controller.description.lensDirection == CameraLensDirection.front;
          processedMat = BeautyProcessor.process(
            bgrMat,
            ref.read(beautyProvider),
            isFrontCamera: isFront,
          );

          final (_, bytes) = cv.imencode(".jpg", processedMat);
          ref.read(processedFrameProvider.notifier).state = bytes;
        }
      } catch (e) {
        debugPrint("美颜流异常: $e");
      } finally {
        rawMat?.dispose();
        actualMat?.dispose();
        bgrMat?.dispose();
        processedMat?.dispose();
        _isProcessing = false;
      }
    });
  }

  Future<void> _syncBeautyStream(bool enable) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (enable) {
      if (!controller.value.isStreamingImages) {
        _startLiveBeautyStream();
      }
      return;
    }

    try {
      _isProcessing = false;
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (e) {
      debugPrint('关闭美颜分析流失败: $e');
    } finally {
      ref.read(processedFrameProvider.notifier).state = null;
    }
  }

  Future<void> _disposeController(CameraController controller) async {
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (e) {
      debugPrint('停止图像流失败: $e');
    }

    try {
      await controller.dispose();
    } catch (e) {
      debugPrint('释放摄像头失败: $e');
    }
  }

  /// 手动释放相机（跳转直播间前调用，避免和 WebRTC 抢占）
  Future<void> releaseCamera() async {
    final oldController = _controller;
    _controller = null;
    _isProcessing = false;
    ref.read(processedFrameProvider.notifier).state = null;
    state = const AsyncValue.loading();

    if (oldController != null) {
      await _disposeController(oldController);
    }
  }

  /// 重新初始化相机（从直播间返回时调用）
  Future<void> reinitializeCamera(List<CameraDescription> cameras) async {
    if (cameras.isNotEmpty) {
      await initCamera(cameras[_camIndex]);
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      _disposeController(controller);
    }
    super.dispose();
  }
}

// 4. 全局 Provider 绑定
final cameraStateProvider =
    StateNotifierProvider<
      CameraControllerNotifier,
      AsyncValue<CameraController>
    >((ref) {
      return CameraControllerNotifier(ref);
    });
