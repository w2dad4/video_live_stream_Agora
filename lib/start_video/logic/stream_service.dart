import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_whip/flutter_whip.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_live_stream/config/constants.dart';
import 'package:video_live_stream/live_stream_discover/live_streaming_starts/logic_layer_data/logic_layer.dart';

//推流专用
final livePublisherProvider = AsyncNotifierProvider.autoDispose.family<LivePublisherNotifier, void, String>((roomID) => LivePublisherNotifier(roomID));
//调整清晰度逻辑
final currentQualityProvider = StateProvider<LiveQuality>((ref) => LiveQuality.sd720p);

enum LiveQuality {
  sd720p(name: '720P', width: 1280, height: 720, bitrate: 2500000),
  fhd1080p(name: '1080P', width: 1920, height: 1080, bitrate: 5000000),
  bluRay(name: '蓝光', width: 1920, height: 1080, bitrate: 8000000);

  final String name;
  final int width;
  final int height;
  final int bitrate;
  const LiveQuality({required this.name, required this.width, required this.height, required this.bitrate});
}

class LivePublisherNotifier extends AsyncNotifier<void> {
  final String roomID;
  LivePublisherNotifier(this.roomID);

  Future<void> changeQuality(LiveQuality newQuality) async {
    //进入加载状态，让 UI 停止引用旧的渲染器
    state = const AsyncLoading();
    // 1. 立即更新状态 Provider，这将触发 UI 文字刷新
    ref.read(currentQualityProvider.notifier).state = newQuality;

    // 2. 重新执行推流初始化流程
    try {
      await _stopInternal();
      //重新初始化加载
      _localRenderer = RTCVideoRenderer();
      await _localRenderer!.initialize();
      // 重新开始推流
      await startPublishing();
      //恢复状态
      state = const AsyncData(null);
      debugPrint('清晰度已成功切换至: ${newQuality.name}');
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  RTCVideoRenderer? _localRenderer;
  WHIP? _whip;
  MediaStream? _localStream;
  bool _isFrontCamera = true;
  bool _isSwitchingCamera = false;
  bool _isStarting = false;

  RTCVideoRenderer? get renderer => _localRenderer;
  bool get isFrontCamera => _isFrontCamera;

  @override
  Future<void> build() async {
    // 1. 初始化渲染器 (这一步极快)
    _localRenderer = RTCVideoRenderer();
    await _localRenderer!.initialize();
    // 2. 注册销毁逻辑
    ref.onDispose(() async {
      await _stopInternal();
    });
    return startPublishing();
  }

  Future<void> startPublishing() async {
    if (_isStarting) return;
    _isStarting = true;
    if (roomID.trim().isEmpty) {
      _isStarting = false;
      throw Exception('直播间ID为空，无法开始推流');
    }

    try {
      final quality = ref.read(currentQualityProvider);
      // 清理旧资源，防止相机重复打开
      await _releaseStream();
      await _ensurePermissions();

      _localStream = await _getStableMediaStream(quality);
      _localRenderer?.srcObject = _localStream;

      // 4. 开始连接推流服务器 WHIP 连接（加超时，避免卡住）
      final String url = LiveConfig.whipUri(roomID).toString();
      debugPrint('开始推流 roomID=$roomID, whip=$url');
      _whip = WHIP(url: url);
      await _whip!.initlize(mode: WhipMode.kSend, stream: _localStream).timeout(const Duration(seconds: 8), onTimeout: () => throw Exception('推流初始化超时'));
      await _whip!.connect().timeout(const Duration(seconds: 8), onTimeout: () => throw Exception('推流连接超时'));
    } catch (e) {
      debugPrint('推流初始化失败: $e');
      rethrow;
    } finally {
      _isStarting = false;
    }
  }

  Future<void> _ensurePermissions() async {
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;
    if (cameraStatus.isGranted && micStatus.isGranted) return;

    final result = await [Permission.camera, Permission.microphone].request();
    if (result[Permission.camera] != PermissionStatus.granted) {
      throw Exception('需要摄像头权限才能直播');
    }
    if (result[Permission.microphone] != PermissionStatus.granted) {
      throw Exception('需要麦克风权限才能直播');
    }
  }

  Map<String, dynamic> _buildVideoConstraints({required int width, required int height, required int maxFrameRate}) {
    return {
      'audio': true,
      'video': {
        'facingMode': _isFrontCamera ? 'user' : 'environment',
        'width': {'ideal': width, 'max': width},
        'height': {'ideal': height, 'max': height},
        'frameRate': {'ideal': maxFrameRate, 'max': maxFrameRate},
      },
    };
  }

  Future<MediaStream> _getStableMediaStream(LiveQuality quality) async {
    final candidates = <Map<String, dynamic>>[
      _buildVideoConstraints(width: quality.width, height: quality.height, maxFrameRate: 30),
      _buildVideoConstraints(width: 1280, height: 720, maxFrameRate: 24),
      {
        'audio': true,
        'video': {'facingMode': _isFrontCamera ? 'user' : 'environment'},
      },
    ];

    Object? lastError;
    for (final constraints in candidates) {
      try {
        return await navigator.mediaDevices.getUserMedia(constraints).timeout(const Duration(seconds: 6), onTimeout: () => throw Exception('摄像头启动超时'));
      } catch (e) {
        lastError = e;
        debugPrint('getUserMedia 降级重试: $e');
      }
    }
    throw Exception('摄像头启动失败: $lastError');
  }

  /// UI 手动重试按钮专用
  Future<void> retryPublishing() async {
    state = const AsyncLoading();
    try {
      await startPublishing();
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  /// 麦克风静音/取消静音
  void toggleMic() {
    // 1. 获取当前状态
    final currentState = ref.read(isMicOpenProvider);
    final newState = !currentState;

    // 2. 更新状态 Provider (驱动 UI 变化的关键)
    ref.read(isMicOpenProvider.notifier).state = newState;

    // 3. 执行硬件层逻辑 (操作 WebRTC 轨道)
    // _localStream?.getAudioTracks().forEach((track) => track.enabled = newState);
    final audioTracks = _localStream?.getAudioTracks();
    if (audioTracks != null && audioTracks.isNotEmpty) {
      final track = audioTracks.first;
      track.enabled = !track.enabled;
    }
  }

  bool get isMicEnabled {
    final audioTracks = _localStream?.getAudioTracks();
    if (audioTracks != null && audioTracks.isNotEmpty) {
      return audioTracks.first.enabled;
    }
    return false;
  }

  /// 切换前后摄像头
  Future<void> switchCamera() async {
    if (_isSwitchingCamera) return;
    if (_isStarting) return;
    _isSwitchingCamera = true;
    try {
      // 1) 优先走原生轨道切换，避免 WHIP 重连黑屏
      final tracks = _localStream?.getVideoTracks();
      if (tracks != null && tracks.isNotEmpty) {
        await Helper.switchCamera(tracks.first).timeout(const Duration(seconds: 2), onTimeout: () => throw Exception('switchCamera timeout'));
        _isFrontCamera = !_isFrontCamera;
        state = const AsyncData(null);
        return;
      }

      // 2) 无视频轨道时走重建兜底
      throw Exception('当前没有可切换的视频轨道');
    } catch (nativeError) {
      debugPrint('原生切镜头失败，改走重建推流: $nativeError');
      final previousCamera = _isFrontCamera;
      _isFrontCamera = !_isFrontCamera;
      state = const AsyncLoading();
      try {
        await startPublishing();
        state = const AsyncData(null);
      } catch (e, stack) {
        debugPrint('重建推流切换摄像头失败，尝试回退: $e');
        _isFrontCamera = previousCamera;
        try {
          await startPublishing();
        } catch (rollbackError) {
          debugPrint('摄像头回退失败: $rollbackError');
        }
        state = AsyncError(Exception('切换摄像头失败: $e'), stack);
      }
    } finally {
      _isSwitchingCamera = false;
    }
  }

  /// 释放流和 WHIP（不释放 renderer）
  Future<void> _releaseStream() async {
    final whip = _whip;
    final stream = _localStream;
    _whip = null;
    _localStream = null;

    // 先解绑渲染目标，再停止轨道，避免 Surface/BufferQueue 冲突
    _localRenderer?.srcObject = null;
    await Future<void>.delayed(const Duration(milliseconds: 120));

    if (stream != null) {
      for (final track in stream.getTracks()) {
        try {
          track.enabled = false;
          track.stop();
        } catch (e) {
          debugPrint('停止轨道失败: $e');
        }
      }
      try {
        await stream.dispose();
      } catch (e) {
        debugPrint('释放媒体流失败: $e');
      }
    }

    try {
      whip?.close();
    } catch (e) {
      debugPrint('关闭 WHIP 失败: $e');
    }
    // 给 Camera HAL 一点收尾时间，降低切镜头时资源抢占
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  /// 完全释放所有资源
  Future<void> _stopInternal() async {
    await _releaseStream();
    _localRenderer?.srcObject = null;
    await _localRenderer?.dispose();
    _localRenderer = null;
  }
}
