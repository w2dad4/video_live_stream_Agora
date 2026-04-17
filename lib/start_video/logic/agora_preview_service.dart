// Agora 纯预览服务 - 仅本地摄像头预览，不推流
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'agora_service.dart';

/// Agora 预览服务 Provider
/// 仅用于直播前的摄像头预览，不加入频道、不推流
final agoraPreviewProvider = StateNotifierProvider<AgoraPreviewService, AsyncValue<AgoraPreviewState>>((ref) {
  return AgoraPreviewService(ref);
});

/// 预览状态
class AgoraPreviewState {
  final bool isInitialized;
  final bool isPreviewing;
  final bool isCameraOn;
  final bool isMicOn;
  final LiveQuality quality;

  const AgoraPreviewState({
    this.isInitialized = false,
    this.isPreviewing = false,
    this.isCameraOn = true,
    this.isMicOn = true,
    this.quality = LiveQuality.fhd1080p,
  });

  AgoraPreviewState copyWith({
    bool? isInitialized,
    bool? isPreviewing,
    bool? isCameraOn,
    bool? isMicOn,
    LiveQuality? quality,
  }) {
    return AgoraPreviewState(
      isInitialized: isInitialized ?? this.isInitialized,
      isPreviewing: isPreviewing ?? this.isPreviewing,
      isCameraOn: isCameraOn ?? this.isCameraOn,
      isMicOn: isMicOn ?? this.isMicOn,
      quality: quality ?? this.quality,
    );
  }
}

/// Agora 预览服务 - 仅预览，不推流
class AgoraPreviewService extends StateNotifier<AsyncValue<AgoraPreviewState>> {
  final Ref ref;
  RtcEngine? _engine;
  int _cameraId = 0; // 0=后置, 1=前置

  AgoraPreviewService(this.ref) : super(const AsyncValue.loading());

  /// 初始化并启动预览
  Future<void> initialize() async {
    try {
      // 1. 请求权限
      await [Permission.camera, Permission.microphone].request();

      // 2. 获取引擎（使用 AgoraEngineManager 单例）
      _engine = await AgoraEngineManager.getEngine();

      // 3. 配置视频编码（使用当前选择的画质）
      final quality = ref.read(currentQualityProvider);
      await _updateVideoConfig(quality);

      // 4. 配置角色为 broadcaster（但先不加入频道）
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // 5. 开启本地预览
      await _engine!.startPreview();

      state = AsyncValue.data(AgoraPreviewState(
        isInitialized: true,
        isPreviewing: true,
        quality: quality,
      ));

      debugPrint('✅ [AgoraPreview] 预览已启动');
    } catch (e, stack) {
      debugPrint('❌ [AgoraPreview] 启动失败: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  /// 更新视频配置
  Future<void> _updateVideoConfig(LiveQuality quality) async {
    if (_engine == null) return;

    await _engine!.setVideoEncoderConfiguration(
      VideoEncoderConfiguration(
        dimensions: quality.videoDimensions,
        frameRate: quality.fps,
        bitrate: quality.videoBitrate,
        orientationMode: OrientationMode.orientationModeAdaptive,
      ),
    );
  }

  /// 切换摄像头
  Future<void> switchCamera() async {
    if (_engine == null) return;

    await _engine!.switchCamera();
    _cameraId = _cameraId == 0 ? 1 : 0;
    debugPrint('🎥 [AgoraPreview] 切换摄像头: $_cameraId');
  }

  /// 切换麦克风
  Future<void> toggleMicrophone() async {
    if (_engine == null) return;

    final current = state.value?.isMicOn ?? true;
    await _engine!.muteLocalAudioStream(!current);
    state = AsyncValue.data(state.value?.copyWith(isMicOn: !current) ?? const AgoraPreviewState());
  }

  /// 切换闪光灯（仅后置摄像头）
  Future<void> toggleFlash() async {
    if (_engine == null) return;

    await _engine!.setCameraTorchOn(_cameraId == 0); // 仅后置可用
  }

  /// 更新画质
  Future<void> updateQuality(LiveQuality quality) async {
    await _updateVideoConfig(quality);
    state = AsyncValue.data(state.value?.copyWith(quality: quality) ?? AgoraPreviewState(quality: quality));
  }

  /// 停止预览并释放资源
  Future<void> stopPreview() async {
    try {
      if (_engine != null) {
        await _engine!.stopPreview();
      }
      await AgoraEngineManager.releaseEngine();
      state = const AsyncValue.data(AgoraPreviewState(isInitialized: false, isPreviewing: false));
      debugPrint('👋 [AgoraPreview] 预览已停止');
    } catch (e) {
      debugPrint('❌ [AgoraPreview] 停止失败: $e');
    }
  }

  /// 获取本地视频视图
  Widget getLocalVideoView() {
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine!,
        canvas: const VideoCanvas(uid: 0), // uid=0 表示本地视频
      ),
    );
  }

  @override
  void dispose() {
    stopPreview();
    super.dispose();
  }
}
