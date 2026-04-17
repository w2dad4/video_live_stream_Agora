import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../config/constants.dart';
import '../../../live_stream_discover/voice_live_streaming/voicelive_Data/chat_socket_provider.dart';
import '../../../start_video/logic/agora_token_service.dart';
import '../../../services/live_room_service.dart';

// Re-export for external use
export 'package:flutter_riverpod/flutter_riverpod.dart';

// 👀 观众端专用 - 完全独立的引擎管理
/// 👀 观众服务 Provider - 完全独立
/// ✅ 使用 autoDispose 确保退出页面时自动释放资源
final audienceServiceProvider = AsyncNotifierProvider.family.autoDispose<AudienceService, void, String>((roomId) => AudienceService(roomId), name: 'audienceService');

/// 👀 观众端正在观看的主播 UID（用于渲染视频）
final audienceRemoteUidProvider = StateProvider<int?>((ref) => null, name: 'audienceRemoteUid');

/// 👀 观众端拉流状态
final audiencePlayingProvider = StateProvider<bool>((ref) => false, name: 'audiencePlaying');

/// 👀 主播信息（用于直播结束页面显示）
final hostInfoProvider = StateProvider<Map<String, dynamic>?>((ref) => null, name: 'hostInfo');

/// 👀 主播是否已离开（触发跳转到结束页面）
final hostLeftProvider = StateProvider<bool>((ref) => false, name: 'hostLeft');

/// 👀 观众端引擎管理 - 观众专用单例
class AudienceEngineManager {
  static RtcEngine? _engine;
  static int _refCount = 0;
  static String? _currentChannelId; // 当前加入的频道ID
  // 🔒 防止并发初始化
  static bool _isInitializing = false;
  static final List<Completer<RtcEngine>> _pendingRequests = [];

  /// 获取当前频道ID
  static String? get currentChannelId => _currentChannelId;

  /// 获取观众专用引擎（每次都新建，避免状态混乱）
  static Future<RtcEngine> getEngine({String? targetChannelId}) async {
    // ✅ 坑1修复：如果已有引擎，先强制销毁（避免复用已废弃的引擎）
    if (_engine != null) {
      debugPrint('👀 [Audience] 发现已有引擎，强制销毁后重建');
      await forceDestroy();
    }

    // 如果正在初始化，等待初始化完成
    if (_isInitializing) {
      debugPrint('👀 [Audience] 等待引擎初始化...');
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
      // ✅ 观众端需要启用视频以接收远端视频流
      await _engine!.enableVideo();
      await _engine!.enableAudio();
      // 🚀 开启低延迟模式（观众端延迟更低）
      await _engine!.setParameters('{"rtc.video.enable_low_latency_mode": true}');
      // 🚀 开启双流接收（网络差时自动切换低清流）
      await _engine!.enableDualStreamMode(enabled: true);
      _refCount = 1;
      debugPrint('👀 [Audience] 引擎初始化完成（音视频），引用计数: 1');

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
    debugPrint('👀 [Audience] 引擎引用计数: $_refCount');
    if (_refCount <= 0 && _engine != null) {
      debugPrint('👀 [Audience] 正在销毁引擎...');
      try {
        await _engine!.leaveChannel();
      } catch (e) {
        debugPrint('👀 [Audience] 离开频道时出错: $e');
      }
      await _engine!.release();
      _engine = null;
      _refCount = 0;
      _currentChannelId = null; // 清除当前频道
      debugPrint('👀 [Audience] 引擎已销毁');
    }
  }

  /// 离开当前频道但不销毁引擎（用于切换频道）
  static Future<void> leaveCurrentChannel() async {
    if (_engine != null && _currentChannelId != null) {
      debugPrint('👀 [Audience] 离开当前频道: $_currentChannelId');
      try {
        await _engine!.leaveChannel();
      } catch (e) {
        debugPrint('👀 [Audience] 离开频道出错: $e');
      }
      _currentChannelId = null;
    }
  }

  /// 强制销毁引擎（用于错误恢复）
  static Future<void> forceDestroy() async {
    if (_engine != null) {
      debugPrint('👀 [Audience] 强制销毁引擎...');
      try {
        await _engine!.leaveChannel();
      } catch (e) {
        // 忽略错误
      }
      await _engine!.release();
      _engine = null;
      _refCount = 0;
      _currentChannelId = null;
      _pendingRequests.clear();
      debugPrint('👀 [Audience] 引擎已强制销毁');
    }
  }
}

/// 👀 观众拉流服务 - 仅 subscribe 远端流
class AudienceService extends AsyncNotifier<void> {
  final String roomId;
  AudienceService(this.roomId);

  RtcEngine? _engine;
  AgoraToken? _token;
  int? _remoteUid;
  StreamController<int?>? _remoteUidController;

  @override
  Future<void> build() async {
    // ✅ 每次进入都创建全新的状态
    _remoteUidController = StreamController<int?>.broadcast();
    _remoteUid = null;
    _engine = null;
    _token = null;

    // ✅ 提前缓存 notifier，避免在 dispose 中使用 ref.read()
    final remoteUidNotifier = ref.read(audienceRemoteUidProvider.notifier);
    final hostInfoNotifier = ref.read(hostInfoProvider.notifier);
    final hostLeftNotifier = ref.read(hostLeftProvider.notifier);

    // ✅ 确保全局状态也被清空（防止上次异常退出留下的脏数据）
    remoteUidNotifier.state = null;
    hostLeftNotifier.state = false;

    ref.onDispose(() async {
      debugPrint('👀 [Audience] Provider disposed，清理资源...');
      await _leaveChannel(remoteUidNotifier);
      await _remoteUidController?.close();
    });

    // ✅ 检查房间是否存在且正在直播
    final room = await LiveRoomService.getRoom(roomId);
    if (room == null) {
      throw '主播已下线，请观看其他主播';
    }
    if (room['status'] != 'live') {
      throw '主播已下线，请观看其他主播';
    }

    // ✅ 存储主播信息（用于直播结束页面显示）
    hostInfoNotifier.state = {
      'hostName': room['hostName'] ?? '主播',
      'hostAvatar': room['cover'],
      'roomId': roomId,
    };

    return _startPlaying();
  }

  /// 开始拉流（加入频道 + subscribe）
  Future<void> _startPlaying() async {
    try {
      debugPrint('👀 [Audience] 开始拉流...');
      final channelId = LiveConfig.getChannelName(roomId);

      // 获取观众 Token
      _token = await AgoraTokenService.fetchToken(roomId: channelId, isHost: false, userId: DateTime.now().millisecondsSinceEpoch.toString());
      debugPrint('👀 [Audience] Token获取成功 uid=${_token!.uid}');

      // 延迟更新状态为正在观看，避免在 provider 初始化期间修改其他 provider
      Future.microtask(() {
        ref.read(audiencePlayingProvider.notifier).state = true;
      });

      // 初始化观众专用引擎（传递目标频道ID以便自动切换）
      _engine = await AudienceEngineManager.getEngine(targetChannelId: channelId);

      // 配置观众角色
      await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);

      // 监听远端用户加入
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            debugPrint('👀 [Audience] 加入频道成功: ${connection.channelId}');
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            debugPrint('👀 [Audience] 远端用户加入: $remoteUid');
            _remoteUid = remoteUid;
            ref.read(audienceRemoteUidProvider.notifier).state = remoteUid;
            _remoteUidController?.add(remoteUid);
          },
          onUserOffline: (connection, remoteUid, reason) {
            debugPrint('👀 [Audience] 远端用户离开: $remoteUid');
            if (_remoteUid == remoteUid) {
              _remoteUid = null;
              ref.read(audienceRemoteUidProvider.notifier).state = null;
              _remoteUidController?.add(null);
              // ⚠️ 延迟设置 hostLeft，避免在 Provider 构建阶段修改状态
              Future.microtask(() {
                ref.read(hostLeftProvider.notifier).state = true;
              });
            }
          },
          onConnectionLost: (connection) {
            debugPrint('👀 [Audience] 连接丢失');
          },
        ),
      );

      // 加入频道（观众角色，仅 subscribe）
      await _engine!.joinChannel(
        token: _token!.token,
        channelId: channelId,
        uid: _token!.uid,
        options: const ChannelMediaOptions(
          autoSubscribeVideo: true, // ✅ subscribe 视频
          autoSubscribeAudio: true, // ✅ subscribe 音频
          publishCameraTrack: false, // ❌ 不 publish
          publishMicrophoneTrack: false, // ❌ 不 publish
          clientRoleType: ClientRoleType.clientRoleAudience,
        ),
      );

      // 更新当前频道ID
      AudienceEngineManager._currentChannelId = channelId;
      debugPrint('👀 [Audience] 已加入频道并记录: $channelId');

      ref.read(audiencePlayingProvider.notifier).state = true;
      debugPrint('👀 [Audience] 拉流已开始 channel=$channelId');
    } catch (e) {
      debugPrint('👀 [Audience] 拉流失败: $e');
      rethrow;
    }
  }

  /// 停止拉流
  Future<void> stopPlaying() async {
    // ✅ 先清理 provider 状态（在 _leaveChannel 外部，可以使用 ref）
    if (_remoteUid != null) {
      ref.read(audienceRemoteUidProvider.notifier).state = null;
    }
    await _leaveChannel();
    ref.read(audiencePlayingProvider.notifier).state = false;

    // ✅ 断开 WebSocket 连接，通知服务端观众离开
    try {
      ref.read(chatSocketProvider(roomId).notifier).disconnect();
      debugPrint('👀 [Audience] WebSocket 已断开');
    } catch (e) {
      debugPrint('👀 [Audience] 断开 WebSocket 失败: $e');
    }

    debugPrint('👀 [Audience] 拉流已停止');
  }

  /// 重试拉流（断开重连）
  Future<void> retryPlaying() async {
    debugPrint('👀 [Audience] 重试拉流...');
    await stopPlaying();
    await _startPlaying();
    debugPrint('👀 [Audience] 重试完成');
  }

  /// 离开频道并释放资源
  Future<void> _leaveChannel([StateController<int?>? remoteUidNotifier]) async {
    // 清除远端UID状态（必须在引擎释放前）
    if (_remoteUid != null) {
      debugPrint('👀 [Audience] 清除远端UID: $_remoteUid');
      _remoteUid = null;
      _remoteUidController?.add(null);
      // ✅ 坑2修复：清空全局状态（使用传入的 notifier 或 ref）
      if (remoteUidNotifier != null) {
        remoteUidNotifier.state = null;
      }
    }

    if (_engine != null) {
      debugPrint('👀 [Audience] 离开频道...');
      try {
        await _engine!.leaveChannel();
      } catch (e) {
        debugPrint('👀 [Audience] 离开频道出错: $e');
      }
      AudienceEngineManager._currentChannelId = null; // 清除当前频道记录
      await AudienceEngineManager.releaseEngine();
      _engine = null;
      debugPrint('👀 [Audience] 引擎已释放，引用计数归零');
    }
  }

  /// 获取远端视频视图
  Widget? getRemoteVideoView() {
    if (_engine == null || _remoteUid == null) return null;
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine!,
        canvas: VideoCanvas(uid: _remoteUid),
        connection: RtcConnection(channelId: LiveConfig.getChannelName(roomId)),
      ),
    );
  }

  /// 远端 UID 流
  Stream<int?>? get remoteUidStream => _remoteUidController?.stream;
}
