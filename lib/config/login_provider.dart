import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../live_stream_message/contact/contact_UI/constants.dart'; // 导入 LiveConfig 以获取动态 IP

// 持久化常量定义
const String _kUserAccount = 'user_account';
const String _kIsLoggedIn = 'is_logged_in';
const String _kUserToken = 'token';

/// 读取上次登录成功并持久化的手机号（不读密码，密码不落盘）。
Future<String?> readSavedUserAccount() async {
  final prefs = await SharedPreferences.getInstance();
  final v = prefs.getString(_kUserAccount);
  if (v == null || v.isEmpty) return null;
  return v;
}

/// 是否仍处于已登录状态（与 [LoginNotifier.login] 写入的标记一致）。
Future<bool> readIsLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kIsLoggedIn) ?? false;
}

final loginProvider = StateNotifierProvider<LoginNotifier, AsyncValue<void>>((ref) => LoginNotifier());

class LoginNotifier extends StateNotifier<AsyncValue<void>> {
  LoginNotifier() : super(const AsyncValue.data(null));

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5), // 设置 5 秒超时，提升 M1 运行效率
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  /// 活的登录验证：请求后端 API（或由 [LiveConfig.bypassLoginApi] 跳过）
  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      if (LiveConfig.bypassLoginApi) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kUserAccount, username);
        await prefs.setBool(_kIsLoggedIn, true);
        await prefs.setString(_kUserToken, 'dev-bypass-token');
        state = const AsyncValue.data(null);
        return;
      }

      // 1. 动态构造 URL：使用 LiveConfig.serverIP 替代死地址
      final String loginUrl = 'http://${LiveConfig.serverIP}:8000/api/v1/login';

      // 2. 发送 POST 请求
      final response = await _dio.post(loginUrl, data: {'username': username, 'password': password});

      // 3. 根据后端返回码处理（假设 0 为成功）
      if (response.statusCode == 200 && response.data['code'] == 0) {
        final prefs = await SharedPreferences.getInstance();

        // 核心持久化逻辑
        await prefs.setString(_kUserAccount, username);
        await prefs.setBool(_kIsLoggedIn, true);
        await prefs.setString(_kUserToken, response.data['token'] ?? '');

        state = const AsyncValue.data(null);
      } else {
        // 后端逻辑错误（如密码不对）
        throw response.data['message'] ?? '登录验证未通过';
      }
    } catch (e, stk) {
      // 网络错误或抛出的异常
      String errorMsg = '网络连接失败，请检查后端服务';
      if (e is DioException) {
        errorMsg = e.response?.data['message'] ?? e.message ?? errorMsg;
      } else {
        errorMsg = e.toString();
      }
      state = AsyncValue.error(errorMsg, stk);
    }
  }

  /// 退出登录：一键清除所有标记
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = const AsyncValue.data(null);
  }
}
