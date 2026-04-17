import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'audio_models.dart';

/// 服务器配置（内联定义，避免依赖问题）
class _ChatConfig {
  static const String _serverFromDefine = String.fromEnvironment('LIVE_SERVER_IP', defaultValue: '');
  static const int unifiedPort = 8080;

  static String get serverIP {
    if (_serverFromDefine.isNotEmpty) return _serverFromDefine;
    if (Platform.isAndroid || Platform.isIOS) return '192.168.1.18';
    return 'localhost';
  }
}

/// WebSocket 连接状态
enum ChatSocketStatus { disconnected, connecting, connected, error }

/// WebSocket 消息模型
class ChatSocketMessage {
  final String type; // 'chat', 'system', 'join', 'leave', 'onlineCount'
  final String uid;
  final String userName;
  final String content;
  final int timestamp;
  final Map<String, dynamic>? data; // 额外数据，如 onlineCount 的 count

  const ChatSocketMessage({required this.type, required this.uid, required this.userName, required this.content, required this.timestamp, this.data});

  factory ChatSocketMessage.fromJson(Map<String, dynamic> json) {
    return ChatSocketMessage(
      type: json['type'] ?? 'chat',
      uid: json['uid'] ?? '',
      userName: json['userName'] ?? '匿名',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'uid': uid, 'userName': userName, 'content': content, 'timestamp': timestamp, 'data': data};
  }

  /// 转换为 VoiceChatMessage（用于兼容现有 UI）
  VoiceChatMessage toVoiceChatMessage() {
    return VoiceChatMessage(uid: uid, userName: userName, content: content);
  }

  /// 获取在线人数（仅 type 为 onlineCount 时有效）
  int? get onlineCount {
    if (type == 'onlineCount') {
      return data?['count'] as int? ?? int.tryParse(content);
    }
    return null;
  }
}

/// WebSocket 连接管理 - 使用 StateNotifier 新版 API
class ChatSocketNotifier extends StateNotifier<ChatSocketStatus> {
  ChatSocketNotifier(this.ref, this.roomId, {this.role = 'viewer'}) : super(ChatSocketStatus.disconnected) {
    _init();
  }

  final Ref ref;
  final String roomId;
  final String role; // 'host' | 'viewer'
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  /// 消息流控制器
  final _messageController = StreamController<ChatSocketMessage>.broadcast();
  Stream<ChatSocketMessage> get messageStream => _messageController.stream;

  /// 在线人数流控制器
  final _onlineCountController = StreamController<int>.broadcast();
  Stream<int> get onlineCountStream => _onlineCountController.stream;

  void _init() {
    connect();
  }

  /// 建立 WebSocket 连接
  void connect() {
    if (state == ChatSocketStatus.connecting || state == ChatSocketStatus.connected) {
      return;
    }

    state = ChatSocketStatus.connecting;

    try {
      final me = ref.read(meProvider);
      if (me == null) {
        state = ChatSocketStatus.error;
        debugPrint('❌ [ChatSocket] 用户未登录');
        return;
      }
      final userId = me.uid ?? 'anonymous';
      final userName = me.name ?? '匿名用户';

      // 构建 WebSocket URL（带上角色信息）
      final wsUrl = Uri.parse(
        'ws://${_ChatConfig.serverIP}:${_ChatConfig.unifiedPort}/ws/chat'
        '?roomId=$roomId&userId=$userId&userName=${Uri.encodeComponent(userName)}&role=$role',
      );

      debugPrint('💬 [ChatSocket] 连接中: $wsUrl');

      _channel = WebSocketChannel.connect(wsUrl);

      _subscription = _channel!.stream.listen(_onMessage, onError: _onError, onDone: _onClose);

      // 等待连接成功
      _channel!.ready.then((_) {
        debugPrint('💬 [ChatSocket] 连接成功');
        state = ChatSocketStatus.connected;
      });
    } catch (e) {
      debugPrint('💬 [ChatSocket] 连接失败: $e');
      state = ChatSocketStatus.error;
      _reconnect();
    }
  }

  /// 接收消息
  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String);
      final message = ChatSocketMessage.fromJson(json);

      // 处理在线人数更新
      if (message.type == 'onlineCount') {
        final count = message.onlineCount ?? 0;
        debugPrint('💬 [ChatSocket] 在线人数更新: $count');
        _onlineCountController.add(count);
      } else {
        debugPrint('💬 [ChatSocket] 收到消息: ${message.userName}: ${message.content}');
      }

      _messageController.add(message);
    } catch (e) {
      debugPrint('💬 [ChatSocket] 消息解析失败: $e');
    }
  }

  /// 错误处理
  void _onError(Object error) {
    debugPrint('💬 [ChatSocket] 连接错误: $error');
    state = ChatSocketStatus.error;
    _reconnect();
  }

  /// 连接关闭
  void _onClose() {
    debugPrint('💬 [ChatSocket] 连接关闭');
    state = ChatSocketStatus.disconnected;
    _reconnect();
  }

  /// 断线重连
  Timer? _reconnectTimer;
  void _reconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (state != ChatSocketStatus.connected) {
        debugPrint('💬 [ChatSocket] 尝试重连...');
        connect();
      }
    });
  }

  /// 发送消息
  void sendMessage(String content) {
    if (_channel == null || state != ChatSocketStatus.connected) {
      debugPrint('💬 [ChatSocket] 未连接，无法发送消息');
      return;
    }

    final message = {'type': 'chat', 'content': content};
    _channel!.sink.add(jsonEncode(message));
    debugPrint('💬 [ChatSocket] 发送消息: $content');
  }

  /// 发送心跳
  void sendPing() {
    if (_channel == null || state != ChatSocketStatus.connected) return;
    _channel!.sink.add(jsonEncode({'type': 'ping'}));
  }

  /// 断开连接
  void disconnect() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    state = ChatSocketStatus.disconnected;
    debugPrint('💬 [ChatSocket] 已断开连接');
  }

  @override
  void dispose() {
    disconnect();
    _messageController.close();
    _onlineCountController.close();
    super.dispose();
  }
}

/// WebSocket 状态 Provider（房间维度，默认观众角色）
final chatSocketProvider = StateNotifierProvider.family<ChatSocketNotifier, ChatSocketStatus, String>((ref, roomId) => ChatSocketNotifier(ref, roomId, role: 'viewer'));

/// WebSocket 状态 Provider（带角色参数）
final chatSocketWithRoleProvider = StateNotifierProvider.family<ChatSocketNotifier, ChatSocketStatus, ({String roomId, String role})>(
  (ref, params) => ChatSocketNotifier(ref, params.roomId, role: params.role),
);

/// WebSocket 消息流 Provider（房间维度）
final chatSocketMessageProvider = StreamProvider.family<ChatSocketMessage, String>((ref, roomId) {
  final notifier = ref.watch(chatSocketProvider(roomId).notifier);
  return notifier.messageStream;
});

/// WebSocket 在线人数流 Provider（房间维度）
final chatOnlineCountProvider = StreamProvider.family<int, String>((ref, roomId) {
  final notifier = ref.watch(chatSocketProvider(roomId).notifier);
  return notifier.onlineCountStream;
});

/// WebSocket 在线人数流 Provider（带角色）
final chatOnlineCountWithRoleProvider = StreamProvider.family<int, ({String roomId, String role})>((ref, params) {
  final notifier = ref.watch(chatSocketWithRoleProvider(params).notifier);
  return notifier.onlineCountStream;
});
