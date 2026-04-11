// Agora Token 服务 - 从服务端获取临时 Token
// ⚠️ 安全原则：
// 1. App Certificate 只在服务端保存
// 2. Token 每小时刷新一次
// 3. Token 绑定特定频道 + 用户UID + 角色权限
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_live_stream/config/constants.dart';

/// Token 响应模型
class AgoraToken {
  final String token;
  final int uid;
  final int expireTime; // 过期时间戳
  final String channelName;
  final String role; // 'publisher' | 'subscriber'

  const AgoraToken({
    required this.token,
    required this.uid,
    required this.expireTime,
    required this.channelName,
    required this.role,
  });

  /// 是否已过期（提前5分钟认为过期，避免边界问题）
  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000 >= (expireTime - 300);

  factory AgoraToken.fromJson(Map<String, dynamic> json) {
    return AgoraToken(
      token: json['token'] as String,
      uid: json['uid'] as int,
      expireTime: json['expireTime'] as int, //
      channelName: json['channelName'] as String,
      role: json['role'] as String,
    );
  }
}

/// Token 服务端点配置
class TokenServiceConfig {
  /// Token 生成接口。
  /// 实际地址统一从 `LiveConfig` 读取，避免 Flutter 端多处硬编码。
  static String get tokenUrl => LiveConfig.agoraTokenUrl;

  /// 主播默认房间号同步接口。
  /// 浏览器测试页会读取这个接口，从而进入 Flutter 主播正在使用的真实频道。
  static String get defaultRoomUrl => LiveConfig.agoraDefaultRoomUrl;
}

/// Token 服务
class AgoraTokenService {
  /// 获取直播 Token
  ///
  /// [roomId] - 直播间ID (作为频道名)
  /// [isHost] - 是否主播 (决定角色权限)
  /// [userId] - 用户唯一标识
  static Future<AgoraToken> fetchToken({
    required String roomId,
    required bool isHost,
    required String userId,
  }) async {
    try {
      final url = TokenServiceConfig.tokenUrl;
      debugPrint(
        'AgoraTokenService: 请求Token - URL=$url, roomId=$roomId, role=${isHost ? 'publisher' : 'subscriber'}',
      );

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'channelName': roomId, // 频道名
              'uid': userId, // 用户ID
              'role': isHost ? 'publisher' : 'subscriber', // 角色
              'expireMinutes': 60, // 过期时间（分钟）
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint(
        'AgoraTokenService: 响应状态=${response.statusCode}, body=${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 0) {
          return AgoraToken.fromJson(data['data']);
        }
        throw Exception(data['message'] ?? 'Token 请求失败');
      }
      throw Exception(
        'Token 服务错误: ${response.statusCode}, 响应=${response.body}',
      );
    } catch (e) {
      debugPrint('AgoraTokenService: 获取Token失败 - $e');
      rethrow;
    }
  }

  /// 将当前 Flutter 主播正在使用的直播间 ID 同步给本地 Token 服务。
  /// 浏览器测试页会读取这个值，从而自动填入真实房间号。
  static Future<void> syncDefaultRoom({required String roomId}) async {
    try {
      final url = TokenServiceConfig.defaultRoomUrl;
      debugPrint('AgoraTokenService: 同步默认房间号 - URL=$url, roomId=$roomId');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'channelName': roomId}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        debugPrint(
          'AgoraTokenService: 默认房间号同步失败 - status=${response.statusCode}, body=${response.body}',
        );
      }
    } catch (e) {
      // 这里不阻塞开播主流程，只做调试同步
      debugPrint('AgoraTokenService: 默认房间号同步异常 - $e');
    }
  }

  /// 清空默认主播房间号。
  /// 作用：
  /// 当主播停播或推流失败后，浏览器测试页不应该再自动进入一个已经失效的频道。
  static Future<void> clearDefaultRoom() async {
    try {
      final url = '${TokenServiceConfig.defaultRoomUrl}/clear';
      debugPrint('AgoraTokenService: 清空默认房间号 - URL=$url');

      final response = await http
          .post(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        debugPrint(
          'AgoraTokenService: 清空默认房间号失败 - status=${response.statusCode}, body=${response.body}',
        );
      }
    } catch (e) {
      debugPrint('AgoraTokenService: 清空默认房间号异常 - $e');
    }
  }

  /// 刷新 Token（在 Token 即将过期时调用）
  static Future<AgoraToken> refreshToken(AgoraToken oldToken) async {
    return fetchToken(
      roomId: oldToken.channelName,
      isHost: oldToken.role == 'publisher',
      userId: oldToken.uid.toString(),
    );
  }
}

/// Token 管理 Provider - 用于缓存和自动刷新
class TokenManager extends ChangeNotifier {
  AgoraToken? _currentToken;
  Timer? _refreshTimer;

  AgoraToken? get currentToken => _currentToken;

  /// 初始化 Token 并启动自动刷新
  Future<void> initToken(AgoraToken token) async {
    _currentToken = token;
    _scheduleRefresh(token);
    notifyListeners();
  }

  /// 更新 Token
  Future<void> updateToken(AgoraToken token) async {
    _currentToken = token;
    _scheduleRefresh(token);
    notifyListeners();
  }

  void _scheduleRefresh(AgoraToken token) {
    _refreshTimer?.cancel();

    // 计算刷新时间（过期前10分钟刷新）
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final refreshAt = token.expireTime - 600; // 提前10分钟
    final delaySeconds = refreshAt - now;

    if (delaySeconds > 0) {
      _refreshTimer = Timer(Duration(seconds: delaySeconds), () async {
        try {
          final newToken = await AgoraTokenService.refreshToken(token);
          await updateToken(newToken);
          debugPrint('TokenManager: Token 自动刷新成功');
        } catch (e) {
          debugPrint('TokenManager: Token 自动刷新失败 - $e');
        }
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
