import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// 1. 硬件状态 Providers - 仅保留核心物理状态
final camersProvider = FutureProvider<List<CameraDescription>>((ref) async {
  return await availableCameras();
});

final isMicOpenProvider = StateProvider<bool>((ref) => true);
final isFlashOnProvider = StateProvider<bool>((ref) => false);

final previewCameraActiveProvider = StateProvider<bool>((ref) => true);

// 2. 核心逻辑控制器
class CameraControllerNotifier extends StateNotifier<AsyncValue<CameraController>> {
  CameraControllerNotifier(this.ref) : super(const AsyncValue.loading());

  final Ref ref;
  CameraController? _controller;
  int _camIndex = 0;
  bool _isInitializing = false;

  Future<void> initCamera(CameraDescription camera, {bool isSilent = false}) async {
    if (_isInitializing) return;
    _isInitializing = true;

    final oldController = _controller;
    _controller = null;
    state = const AsyncValue.loading();

    if (oldController != null) {
      await _disposeController(oldController);
    }

    final bool enableAudio = ref.read(isMicOpenProvider);
    // 【性能优化】：将分辨率调整为 medium 以适配移动端预览性能，减少内存占用
    final nextController = CameraController(camera, ResolutionPreset.medium, enableAudio: enableAudio, imageFormatGroup: ImageFormatGroup.bgra8888);

    try {
      await nextController.initialize();
      if (ref.read(isFlashOnProvider) && camera.lensDirection == CameraLensDirection.back) {
        await nextController.setFlashMode(FlashMode.torch);
      } else {
        ref.read(isFlashOnProvider.notifier).state = false;
      }
      _controller = nextController;


      state = AsyncValue.data(nextController);
    } catch (e, stack) {
      await _disposeController(nextController);
      state = AsyncValue.error(e, stack);
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> switchCamera(List<CameraDescription> cameras) async {
    if (cameras.isEmpty || cameras.length < 2) return;
    _camIndex = (_camIndex + 1) % cameras.length;
    await initCamera(cameras[_camIndex], isSilent: true);
  }

  Future<void> toggleMicrophone() async {
    if (_controller == null) return;
    final currentState = ref.read(isMicOpenProvider);
    ref.read(isMicOpenProvider.notifier).state = !currentState;
    await initCamera(_controller!.description, isSilent: true);
  }

  Future<void> toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final bool isNowOn = ref.read(isFlashOnProvider);
      final newMode = isNowOn ? FlashMode.off : FlashMode.torch;
      await _controller!.setFlashMode(newMode);
      ref.read(isFlashOnProvider.notifier).state = !isNowOn;
      state = AsyncValue.data(_controller!);
    } catch (e) {
      debugPrint('闪光灯切换失败: $e');
    }
  }

  Future<void> _disposeController(CameraController controller) async {
    // 停止图像流和释放资源逻辑保持不变
    if (controller.value.isStreamingImages) {
      await controller.stopImageStream().catchError((_) {});
    }
    await controller.dispose().catchError((_) {});
  }

  Future<void> releaseCamera() async {
    final oldController = _controller;
    _controller = null;
    state = const AsyncValue.loading();
    if (oldController != null) {
      await _disposeController(oldController);
    }
  }

  Future<void> reinitializeCamera(List<CameraDescription> cameras) async {
    if (cameras.isNotEmpty) {
      await initCamera(cameras[_camIndex]);
    }
  }

  @override
  void dispose() {
    if (_controller != null) {
      _disposeController(_controller!);
    }
    super.dispose();
  }
}

final cameraStateProvider = StateNotifierProvider<CameraControllerNotifier, AsyncValue<CameraController>>((ref) {
  return CameraControllerNotifier(ref);
});
