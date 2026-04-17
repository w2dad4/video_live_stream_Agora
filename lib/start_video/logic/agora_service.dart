// Agora 声网 SDK 直播服务 - 推流/拉流统一管理
import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:video_live_stream/config/constants.dart';
import 'package:video_live_stream/start_video/logic/agora_token_service.dart';
import 'package:video_live_stream/services/live_room_service.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';

/// Agora App ID - 从配置中心读取
const String agoraAppId = LiveConfig.agoraAppId;

/// 直播质量设置
enum LiveQuality {
  sd360p(name: '流畅', videoBitrate: 400, audioBitrate: 24, fps: 15, videoDimensions: VideoDimensions(width: 640, height: 360)),
  sd480p(name: '标清', videoBitrate: 800, audioBitrate: 24, fps: 24, videoDimensions: VideoDimensions(width: 640, height: 480)),
  sd720p(name: '高清', videoBitrate: 1500, audioBitrate: 32, fps: 30, videoDimensions: VideoDimensions(width: 1280, height: 720)),
  fhd1080p(name: '超清', videoBitrate: 2500, audioBitrate: 48, fps: 30, videoDimensions: VideoDimensions(width: 1920, height: 1080)),
  original(name: '原画', videoBitrate: 0, audioBitrate: 48, fps: 30, videoDimensions: VideoDimensions(width: 0, height: 0)); // 原画使用设备摄像头默认分辨率

  final String name;
  final int videoBitrate;
  final int audioBitrate;
  final int fps;
  final VideoDimensions videoDimensions;
  bool get isOriginal => this == LiveQuality.original;

  const LiveQuality({required this.name, required this.videoBitrate, required this.audioBitrate, required this.fps, required this.videoDimensions});
}

/// 当前清晰度状态 - 默认 1080p
final currentQualityProvider = StateProvider<LiveQuality>((ref) => LiveQuality.fhd1080p, name: 'liveQuality');

/// 推流状态（是否正在直播中）
final isPublishingProvider = StateProvider<bool>((ref) => false, name: 'isPublishing');

/// 麦克风静音状态
final microphoneMutedProvider = StateProvider<bool>((ref) => false, name: 'microphoneMuted');

/// 主播推流服务 Provider
final agoraHostServiceProvider = AsyncNotifierProvider.autoDispose.family<AgoraHostService, void, String>((roomId) => AgoraHostService(roomId));

/// 观众拉流服务 Provider
final agoraAudienceServiceProvider = AsyncNotifierProvider.autoDispose.family<AgoraAudienceService, void, String>((roomId) => AgoraAudienceService(roomId));

/// 声网引擎管理 - 确保全局单例，避免内存泄漏
class AgoraEngineManager {
  static RtcEngine? _engine;
  static int _refCount = 0;

  /// 获取或创建引擎（配置低延迟 + 中国区优化）
  static Future<RtcEngine> getEngine() async {
    if (_engine == null) {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        RtcEngineContext(
          appId: agoraAppId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          // ⚡ 关键：指定中国区，减少路由延迟 (areaCode 是 int 类型位掩码)
          areaCode: 0x00000001, // AreaCode.areaCodeCn
        ),
      );
      // 启用视频模块
      await _engine!.enableVideo();
      await _engine!.enableAudio();
      // ⚡ 配置低延迟直播参数
      await _engine!.setParameters('{"rtc.log_level": 2}');
      await _engine!.setParameters('{"rtc.enable_audio_bwe": true}');
      // 🚀 开启低延迟模式（延迟从2-3秒降至0.5-1秒）
      await _engine!.setParameters('{"rtc.video.enable_low_latency_mode": true}');
      // 🚀 开启自适应码率（网络差时自动降码率防卡顿）
      await _engine!.setParameters('{"rtc.video.enable_adaptive_bitrate": true}');
      // 🚀 开启双流模式（观众可自动切换高低画质）
      await _engine!.enableDualStreamMode(enabled: true);
    }
    _refCount++;
    return _engine!;
  }

  /// 释放引擎引用
  static Future<void> releaseEngine() async {
    _refCount--;
    if (_refCount <= 0 && _engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
      _engine = null;
      _refCount = 0;
    }
  }

  /// 强制释放（用于应用退出等场景）
  static Future<void> forceRelease() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
      _engine = null;
      _refCount = 0;
    }
  }
}

/// 主播服务 - 两阶段：预览 → 开播
class AgoraHostService extends AsyncNotifier<void> {
  final String roomId;
  AgoraHostService(this.roomId);

  RtcEngine? _engine;
  AgoraToken? _token;
  Timer? _tokenRefreshTimer;
  Widget? _cachedLocalVideoView; // 缓存本地视频视图

  /// 是否正在推流
  bool get isPublishing => ref.read(isPublishingProvider);

  @override
  Future<void> build() async {
    // 确保离开时释放资源
    ref.onDispose(() async {
      await _leaveChannel();
      _tokenRefreshTimer?.cancel();
    });

    // 第一阶段：只初始化引擎和开启本地预览（不加入频道）
    return _startPreview();
  }

  /// 第一阶段：启动预览（仅本地摄像头，不推流）
  Future<void> _startPreview() async {
    try {
      // 1. 请求权限
      await _ensurePermissions();

      // 2. 初始化引擎
      _engine = await AgoraEngineManager.getEngine();

      // 3. 配置主播角色（但先不加入频道）
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // 4. 配置视频编码
      final quality = ref.read(currentQualityProvider);
      await _engine!.setVideoEncoderConfiguration(
        VideoEncoderConfiguration(
          dimensions: quality.videoDimensions,
          frameRate: quality.fps,
          bitrate: quality.videoBitrate, //
          orientationMode: OrientationMode.orientationModeAdaptive,
        ),
      );

      // 5. 开启本地预览（仅本地显示，不推流）
      await _engine!.startPreview();

      // 6. 注册事件监听（用于调试和状态监控）
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            debugPrint('✅ 加入频道成功: ${connection.channelId}');
          },
          onLeaveChannel: (connection, stats) {
            debugPrint('👋 离开频道: ${connection.channelId}');
          },
          onConnectionStateChanged: (conn, state, reason) {
            debugPrint('📡 连接状态: $state, 原因: $reason');
          },
        ),
      );

      debugPrint('Agora: 预览已启动（仅本地摄像头，未推流）');
    } catch (e) {
      debugPrint('Agora 预览启动失败: $e');
      rethrow;
    }
  }

  /// 第二阶段：开始推流（点击开播按钮后调用）
  Future<void> startPublishing() async {
    if (isPublishing) {
      debugPrint('已经在推流中，忽略重复调用');
      return;
    }

    try {
      // 更新状态：正在开播中
      ref.read(isPublishingProvider.notifier).state = true;
      final channelId = LiveConfig.getChannelName(roomId);

      // 1. 从服务端获取 Token（关键：确保安全，AppCert 不在客户端）
      final user = ref.read(meProvider);
      final userId = (user?.uid?.isEmpty ?? true) ? 'host_${DateTime.now().millisecondsSinceEpoch}' : user!.uid!;
      _token = await AgoraTokenService.fetchToken(roomId: channelId, isHost: true, userId: userId);
      debugPrint('✅ Token 获取成功 uid=${_token!.uid}, 过期时间=${DateTime.fromMillisecondsSinceEpoch(_token!.expireTime * 1000)}');

      // 2. 加入频道并自动发布音视频（引擎已在预览阶段初始化好）
      // 注意：
      // 这里不直接使用业务层 `roomId`，而是统一映射成 `live_主播UID`。
      // 这样才能保证“一个主播 = 一个独立频道”，避免多个主播误进同一 Agora 频道。
      // ⚡ 关键：先启动预览，确保摄像头已采集数据，再推流
      await _engine!.startPreview();
      debugPrint('▶️ 摄像头预览已启动');

      // ⚡ 配置视频编码参数 - 高清流畅：720p@30fps
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 720, height: 1280), // 720p 高清
          frameRate: 60, // 30fps 流畅
          bitrate: 2500, // 1500kbps 保证画质
          minBitrate: 600,
          orientationMode: OrientationMode.orientationModeAdaptive,
        ),
      );
      debugPrint('⚡ 视频编码配置完成（高清流畅 720p@30fps, 1500kbps）');

      // 引擎已在预览阶段初始化好，直接加入频道
      await _engine!.joinChannel(
        token: _token!.token,
        channelId: channelId,
        uid: _token!.uid,
        options: const ChannelMediaOptions(
          autoSubscribeVideo: false,
          autoSubscribeAudio: false,
          publishCameraTrack: true, //
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      // 只有在主播真正加入 Agora 频道成功后，才把当前频道同步给浏览器测试页。
      // 这样可以避免“浏览器拿到了房间号，但主播实际上还没推流”的误导情况。
      await AgoraTokenService.syncDefaultRoom(roomId: channelId);
      debugPrint('✅ 开始推流: businessRoomId=$roomId, channel=$channelId, uid=${_token!.uid}');

      // 3. 启动 Token 刷新定时器（提前10分钟刷新）
      _startTokenRefreshTimer();
    } catch (e) {
      // 开播失败，重置状态
      ref.read(isPublishingProvider.notifier).state = false;
      debugPrint('❌ 推流启动失败: $e');
      rethrow;
    }
  }

  /// 获取本地视频视图（缓存机制，避免重复创建）
  Widget getLocalVideoView() {
    // 如果视图已缓存，直接返回
    if (_cachedLocalVideoView != null) return _cachedLocalVideoView!;

    // 首次创建并缓存
    _cachedLocalVideoView = AgoraVideoView(
      controller: VideoViewController(rtcEngine: _engine!, canvas: const VideoCanvas(uid: 0)),
    );
    return _cachedLocalVideoView!;
  }

  /// 切换摄像头（前置/后置）
  Future<void> switchCamera() async {
    if (_engine == null) return;
    await _engine!.switchCamera();
    debugPrint('📷 摄像头已切换');
  }

  /// 切换麦克风静音状态
  Future<void> toggleMicrophone() async {
    if (_engine == null) return;
    final isMuted = ref.read(microphoneMutedProvider);
    await _engine!.muteLocalAudioStream(!isMuted);
    ref.read(microphoneMutedProvider.notifier).state = !isMuted;
    debugPrint(isMuted ? '🎤 麦克风已开启' : '🎤 麦克风已静音');
  }

  /// 检查麦克风是否静音
  bool get isMicrophoneMuted => ref.read(microphoneMutedProvider);

  /// 修改直播清晰度 - 仅在预览阶段允许修改
  Future<void> changeQuality(LiveQuality quality) async {
    // ⚠️ 推流过程中禁止切换画质，避免编码重置导致卡顿
    if (isPublishing) {
      debugPrint('❌ 推流中禁止切换画质，请先停止直播');
      throw Exception('直播进行中无法切换画质');
    }
    if (_engine == null) return;
    await _engine!.setVideoEncoderConfiguration(
      VideoEncoderConfiguration(
        dimensions: quality.videoDimensions,
        frameRate: quality.fps,
        bitrate: quality.videoBitrate, //
        orientationMode: OrientationMode.orientationModeAdaptive,
      ),
    );
    ref.read(currentQualityProvider.notifier).state = quality;
    debugPrint('📊 画质已切换: ${quality.name}');
  }

  /// 重新尝试推流（失败后重试）
  Future<void> retryPublishing() async {
    debugPrint('🔄 重新尝试推流...');
    await stopPublishing();
    await startPublishing();
  }

  Future<void> _ensurePermissions() async {
    final statuses = await [Permission.camera, Permission.microphone].request();
    if (statuses[Permission.camera] != PermissionStatus.granted) {
      throw Exception('需要摄像头权限才能直播');
    }
    if (statuses[Permission.microphone] != PermissionStatus.granted) {
      throw Exception('需要麦克风权限才能直播');
    }
  }

  /// 停止推流
  Future<void> stopPublishing() async {
    _tokenRefreshTimer?.cancel();
    ref.read(isPublishingProvider.notifier).state = false;
    await _leaveChannel();
  }

  /// 离开频道并释放资源
  Future<void> _leaveChannel() async {
    if (_engine != null) {
      await _engine!.stopPreview();
      await _engine!.leaveChannel();
      await AgoraEngineManager.releaseEngine();
      _engine = null;
    }
    // 删除直播间（从服务端移除）
    await LiveRoomService.deleteRoom(roomId);
  }

  /// 启动 Token 刷新定时器
  void _startTokenRefreshTimer() {
    _tokenRefreshTimer = Timer.periodic(const Duration(minutes: 10), (timer) async {
      final channelId = LiveConfig.getChannelName(roomId);
      final newToken = await AgoraTokenService.fetchToken(roomId: channelId, isHost: true, userId: _token!.uid.toString());
      debugPrint('✅ Token 刷新成功 uid=${newToken.uid}, 过期时间=${DateTime.fromMillisecondsSinceEpoch(newToken.expireTime * 1000)}');
      _token = newToken;
    });
  }
}

/// 观众拉流服务
class AgoraAudienceService extends AsyncNotifier<void> {
  final String roomId;
  AgoraAudienceService(this.roomId);

  RtcEngine? _engine;
  int? _remoteUid;
  AgoraToken? _token;
  final _remoteUidController = StreamController<int?>.broadcast();

  Stream<int?> get onRemoteUidChanged => _remoteUidController.stream;

  @override
  Future<void> build() async {
    // 确保离开时释放资源
    ref.onDispose(() async {
      await _leaveChannel();
      _remoteUidController.close();
    });

    return _startPlaying();
  }

  /// 开始拉流
  Future<void> _startPlaying() async {
    try {
      final channelId = LiveConfig.getChannelName(roomId);

      // 1. 从服务端获取 Token
      final user = ref.read(meProvider);
      final userId = (user?.uid?.isEmpty ?? true) ? 'audience_${DateTime.now().millisecondsSinceEpoch}' : user!.uid!;
      _token = await AgoraTokenService.fetchToken(roomId: channelId, isHost: false, userId: userId);
      debugPrint('AgoraToken: 观众获取成功 uid=${_token!.uid}, 过期时间=${DateTime.fromMillisecondsSinceEpoch(_token!.expireTime * 1000)}');

      // 2. 获取引擎
      _engine = await AgoraEngineManager.getEngine();

      // 3. 配置观众角色
      await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);

      // 4. 监听远端用户加入
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onUserJoined: (connection, remoteUid, elapsed) {
            debugPrint('Agora: 远端用户加入 uid=$remoteUid');
            _remoteUid = remoteUid;
            _remoteUidController.add(remoteUid);
          },
          onUserOffline: (connection, remoteUid, reason) {
            debugPrint('Agora: 远端用户离开 uid=$remoteUid');
            if (_remoteUid == remoteUid) {
              _remoteUid = null;
              _remoteUidController.add(null);
            }
          },
          onConnectionLost: (connection) {
            debugPrint('Agora: 连接丢失');
            state = AsyncError(Exception('连接丢失，请检查网络'), StackTrace.current);
          },
        ),
      );

      // 5. 加入频道（使用服务端返回的 Token 和 UID）
      await _engine!.joinChannel(
        token: _token!.token,
        channelId: channelId,
        uid: _token!.uid,
        options: const ChannelMediaOptions(
          autoSubscribeVideo: true,
          autoSubscribeAudio: true,
          publishCameraTrack: false, //
          publishMicrophoneTrack: false,
          clientRoleType: ClientRoleType.clientRoleAudience,
        ),
      );

      debugPrint('Agora: 观众开始拉流 businessRoomId=$roomId, channel=$channelId');
    } catch (e) {
      debugPrint('Agora: 拉流失败 - $e');
      rethrow;
    }
  }

  /// 获取远端视频视图
  Widget? getRemoteVideoView() {
    if (_engine == null || _remoteUid == null) return null;
    final channelId = LiveConfig.getChannelName(roomId);
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine!,
        canvas: VideoCanvas(uid: _remoteUid),
        connection: RtcConnection(channelId: channelId),
      ),
    );
  }

  /// 离开频道并释放
  Future<void> _leaveChannel() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      await AgoraEngineManager.releaseEngine();
      _engine = null;
    }
    _remoteUid = null;
  }

  /// 重试拉流
  Future<void> retryPlaying() {
    ref.invalidateSelf();
    return Future.value();
  }
}
