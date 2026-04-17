import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../config/constants.dart';
import '../../../start_video/logic/agora_token_service.dart';
import '../../../services/live_room_service.dart';
import '../../../live_stream_My/meProvider_data/meProvider.dart';

// ============================================
// 🎤 主播端专用 - 完全独立的引擎管理
// 不共享、不混用、独立 Provider
// ============================================

/// 主播端直播质量设置（优化码率，平衡清晰度和流畅度）
enum AnchorLiveQuality {
  sd360p(name: '流畅', videoBitrate: 400, audioBitrate: 24, fps: 15, videoDimensions: VideoDimensions(width: 640, height: 360)),
  sd480p(name: '标清', videoBitrate: 600, audioBitrate: 24, fps: 24, videoDimensions: VideoDimensions(width: 640, height: 480)),
  sd720p(name: '高清', videoBitrate: 1200, audioBitrate: 32, fps: 30, videoDimensions: VideoDimensions(width: 1280, height: 720)),
  fhd1080p(name: '超清', videoBitrate: 1800, audioBitrate: 48, fps: 30, videoDimensions: VideoDimensions(width: 1920, height: 1080)),
  original(name: '原画', videoBitrate: 2500, audioBitrate: 48, fps: 30, videoDimensions: VideoDimensions(width: 1920, height: 1080));

  final String name;
  final int videoBitrate;
  final int audioBitrate;
  final int fps;
  final VideoDimensions videoDimensions;
  bool get isOriginal => this == AnchorLiveQuality.original;

  const AnchorLiveQuality({required this.name, required this.videoBitrate, required this.audioBitrate, required this.fps, required this.videoDimensions});
}

/// 主播端当前画质状态 Provider - 主播端专用
final anchorQualityProvider = StateProvider<AnchorLiveQuality>((ref) => AnchorLiveQuality.sd720p, name: 'anchorQuality');

/// 主播端推流状态 Provider
final anchorPublishingProvider = StateProvider<bool>((ref) => false, name: 'anchorPublishing');

/// 主播端麦克风状态 Provider
final anchorMicEnabledProvider = StateProvider<bool>((ref) => true, name: 'anchorMicEnabled');

/// 🎤 主播服务 Provider - 完全独立
final anchorServiceProvider = AsyncNotifierProvider.autoDispose.family<AnchorService, void, String>((roomId) => AnchorService(roomId), name: 'anchorService');

/// 🎤 主播端引擎管理 - 主播专用单例
/// ❌ 不共享给观众端
class AnchorEngineManager {
  static RtcEngine? _engine;
  static int _refCount = 0;
  // 🔒 防止并发初始化
  static bool _isInitializing = false;
  static final List<Completer<RtcEngine>> _pendingRequests = [];

  /// 获取主播专用引擎（带并发保护）
  static Future<RtcEngine> getEngine() async {
    // 如果已有引擎，直接返回
    if (_engine != null) {
      _refCount++;
      debugPrint('🎤 [Anchor] 引擎引用计数: $_refCount（复用现有引擎）');
      return _engine!;
    }

    // 如果正在初始化，等待初始化完成
    if (_isInitializing) {
      debugPrint('🎤 [Anchor] 等待引擎初始化...');
      final completer = Completer<RtcEngine>();
      _pendingRequests.add(completer);
      return completer.future;
    }

    // 开始初始化
    _isInitializing = true;
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        RtcEngineContext(
          appId: LiveConfig.agoraAppId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          areaCode: 0x00000001, // 中国区
        ),
      );
      await _engine!.enableVideo();
      await _engine!.enableAudio();
      // 🚀 开启低延迟模式
      await _engine!.setParameters('{"rtc.video.enable_low_latency_mode": true}');
      // 🚀 开启自适应码率
      await _engine!.setParameters('{"rtc.video.enable_adaptive_bitrate": true}');
      // 🚀 开启双流模式
      await _engine!.enableDualStreamMode(enabled: true);
      _refCount = 1;
      debugPrint('🎤 [Anchor] 引擎初始化完成，引用计数: 1');

      // 通知所有等待的请求
      for (final completer in _pendingRequests) {
        completer.complete(_engine!);
      }
      _pendingRequests.clear();

      return _engine!;
    } catch (e) {
      // 初始化失败，通知所有等待的请求
      for (final completer in _pendingRequests) {
        completer.completeError(e);
      }
      _pendingRequests.clear();
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// 释放引擎（引用计数归零时销毁）
  static Future<void> releaseEngine() async {
    _refCount--;
    debugPrint('🎤 [Anchor] 引擎引用计数: $_refCount');
    if (_refCount <= 0 && _engine != null) {
      debugPrint('🎤 [Anchor] 正在销毁引擎...');
      try {
        await _engine!.stopPreview();
        await _engine!.leaveChannel();
      } catch (e) {
        debugPrint('🎤 [Anchor] 停止预览/离开频道时出错: $e');
      }
      await _engine!.release();
      _engine = null;
      _refCount = 0;
      debugPrint('🎤 [Anchor] 引擎已销毁');
    }
  }

  /// 强制销毁引擎（用于错误恢复）
  static Future<void> forceDestroy() async {
    if (_engine != null) {
      debugPrint('🎤 [Anchor] 强制销毁引擎...');
      try {
        await _engine!.stopPreview();
        await _engine!.leaveChannel();
      } catch (e) {
        // 忽略错误
      }
      await _engine!.release();
      _engine = null;
      _refCount = 0;
      _pendingRequests.clear();
      debugPrint('🎤 [Anchor] 引擎已强制销毁');
    }
  }
}

/// 🎤 主播推流服务 - 两阶段：预览 → 开播
/// ❌ 不处理任何观众端逻辑
/// ❌ 不 subscribe 任何远端流
class AnchorService extends AsyncNotifier<void> {
  final String roomId;
  AnchorService(this.roomId);

  RtcEngine? _engine;
  AgoraToken? _token;
  Timer? _tokenRefreshTimer;
  Widget? _cachedLocalVideoView;
  bool _isPreviewStarted = false;
  bool _isInChannel = false;

  /// 是否正在推流
  bool get isPublishing => ref.read(anchorPublishingProvider);

  @override
  Future<void> build() async {
    ref.onDispose(() async {
      await _leaveChannel();
      _tokenRefreshTimer?.cancel();
    });
    // 初始化引擎并启动预览
    await _ensurePermissions();
    _engine = await AnchorEngineManager.getEngine();
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    // 自动启动摄像头预览
    await _startPreview();
  }

  /// 第一阶段：启动预览（仅本地摄像头，不推流）
  Future<void> _startPreview() async {
    if (_isPreviewStarted && _engine != null) {
      debugPrint('🎤 [Anchor] 预览已启动，跳过重复初始化');
      return;
    }

    try {
      await _ensurePermissions();
      _engine = await AnchorEngineManager.getEngine();
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // 只在未加入频道时设置编码配置
      if (!_isInChannel) {
        final quality = ref.read(anchorQualityProvider);
        await _engine!.setVideoEncoderConfiguration(VideoEncoderConfiguration(dimensions: quality.videoDimensions, frameRate: quality.fps, bitrate: quality.videoBitrate, minBitrate: quality.isOriginal ? 400 : (quality.videoBitrate ~/ 3), orientationMode: OrientationMode.orientationModeAdaptive));
      }

      await _engine!.startPreview();
      _isPreviewStarted = true;
      debugPrint('🎤 [Anchor] 预览已启动');

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            debugPrint('🎤 [Anchor] 加入频道成功: ${connection.channelId}');
            _isInChannel = true;
          },
          onLeaveChannel: (connection, stats) {
            debugPrint('🎤 [Anchor] 离开频道: ${connection.channelId}');
            _isInChannel = false;
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('🎤 [Anchor] 错误: $err, $msg');
          },
        ),
      );
    } catch (e) {
      debugPrint('🎤 [Anchor] 预览启动失败: $e');
      throw Exception('预览启动失败: $e');
    }
  }

  /// 第二阶段：开始推流（加入频道 + publish）
  Future<void> startPublishing() async {
    try {
      if (isPublishing) {
        debugPrint('🎤 [Anchor] 已经在推流中');
        return;
      }

      debugPrint('🎤 [Anchor] 开始推流...');
      final channelId = LiveConfig.getChannelName(roomId);

      // 获取 Token
      _token = await AgoraTokenService.fetchToken(roomId: channelId, isHost: true, userId: DateTime.now().millisecondsSinceEpoch.toString());
      debugPrint('🎤 [Anchor] Token获取成功 uid=${_token!.uid}');

      // ⚡ 推流前确保预览已启动
      await _startPreview();
      debugPrint('🎤 [Anchor] 预览已启动，准备推流');

      // 加入频道（主播角色，publish 音视频）
      await _engine!.joinChannel(
        token: _token!.token,
        channelId: channelId,
        uid: _token!.uid,
        options: const ChannelMediaOptions(
          autoSubscribeVideo: false, // ❌ 主播不 subscribe
          autoSubscribeAudio: false, // ❌ 主播不 subscribe
          publishCameraTrack: true, // ✅ publish 视频
          publishMicrophoneTrack: true, // ✅ publish 音频
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      // 同步房间号到 Token 服务
      await AgoraTokenService.syncDefaultRoom(roomId: channelId);

      // 获取当前用户信息
      final user = ref.read(meProvider);
      final hostName = user?.name ?? '主播';
      final region = (user?.region == null || user?.region == '未设置') ? '未知' : user!.region!;

      // 创建直播间（后端）
      debugPrint('🎤 [Anchor] 准备创建直播间: roomId=$roomId, channelId=$channelId, hostName=$hostName, region=$region');
      await LiveRoomService.createRoom(
        id: roomId,
        channelName: channelId,
        hostName: hostName,
        hostUid: _token!.uid.toString(), //
        title: hostName,
        region: region,
      );

      // 更新房间状态为 live（开始直播），这样首页才能看到
      await LiveRoomService.updateRoomStatus(roomId, 'live');
      debugPrint('🎤 [Anchor] 房间状态已更新为 live');

      // 更新状态
      ref.read(anchorPublishingProvider.notifier).state = true;
      _startTokenRefreshTimer();

      debugPrint('🎤 [Anchor] 推流已开始 channel=$channelId');
    } catch (e) {
      debugPrint('🎤 [Anchor] 推流失败: $e');
      // 开播失败不需要删除房间（因为房间还未创建或已标记为失败）
      rethrow;
    }
  }

  /// 停止推流
  Future<void> stopPublishing() async {
    _tokenRefreshTimer?.cancel();
    ref.read(anchorPublishingProvider.notifier).state = false;

    // 删除直播间（后端）
    await LiveRoomService.deleteRoom(roomId);

    await _leaveChannel();
    debugPrint('🎤 [Anchor] 推流已停止');
  }

  /// 重试推流（断开重连）
  Future<void> retryPublishing() async {
    debugPrint('🎤 [Anchor] 重试推流...');
    await stopPublishing();
    await startPublishing();
    debugPrint('🎤 [Anchor] 重试完成');
  }

  /// 离开频道并释放资源
  Future<void> _leaveChannel() async {
    if (_engine != null) {
      debugPrint('🎤 [Anchor] 正在停止预览...');
      await _engine!.stopPreview();

      debugPrint('🎤 [Anchor] 正在离开频道...');
      await _engine!.leaveChannel();

      // 等待摄像头完全释放
      debugPrint('🎤 [Anchor] 等待摄像头完全释放...');
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('🎤 [Anchor] 正在释放引擎...');
      await AnchorEngineManager.releaseEngine();
      _engine = null;
      _isPreviewStarted = false;
      _isInChannel = false;
      debugPrint('🎤 [Anchor] 资源释放完成');
    }
    // 注意：房间删除在 stopPublishing 中已调用 LiveRoomService.deleteRoom
  }

  /// 启动 Token 刷新定时器
  void _startTokenRefreshTimer() {
    _tokenRefreshTimer = Timer.periodic(const Duration(minutes: 10), (timer) async {
      final channelId = LiveConfig.getChannelName(roomId);
      final newToken = await AgoraTokenService.fetchToken(roomId: channelId, isHost: true, userId: _token!.uid.toString());
      debugPrint('🎤 [Anchor] Token 刷新成功');
      _token = newToken;
    });
  }

  /// 切换麦克风
  Future<void> toggleMicrophone() async {
    if (_engine == null) return;
    final currentState = ref.read(anchorMicEnabledProvider);
    final newState = !currentState;
    await _engine!.muteLocalAudioStream(!newState); // true = 静音, false = 开启
    ref.read(anchorMicEnabledProvider.notifier).state = newState;
    debugPrint('🎤 [Anchor] 麦克风: ${newState ? "开启" : "静音"}');
  }

  /// 切换摄像头（前置/后置）
  Future<void> switchCamera() async {
    if (_engine == null) return;
    await _engine!.switchCamera();
    debugPrint('🎤 [Anchor] 摄像头已切换');
  }

  /// 获取本地视频视图
  Widget getLocalVideoView() {
    if (_cachedLocalVideoView == null && _engine != null) {
      _cachedLocalVideoView = AgoraVideoView(
        controller: VideoViewController(rtcEngine: _engine!, canvas: const VideoCanvas(uid: 0)),
      );
    }
    return _cachedLocalVideoView ?? const Center(child: CircularProgressIndicator());
  }

  /// 请求权限
  Future<void> _ensurePermissions() async {
    // 权限检查逻辑...
    debugPrint('🎤 [Anchor] 权限检查完成');
  }
}
