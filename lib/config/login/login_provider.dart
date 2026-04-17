import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../live_stream_message/contact/contact_UI/constants.dart'; // 导入 LiveConfig 以获取动态 IP

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

/// 验证码登录状态
final smsLoginProvider = StateNotifierProvider<SmsLoginNotifier, AsyncValue<void>>((ref) => SmsLoginNotifier());

/// 验证码注册状态
final smsRegisterProvider = StateNotifierProvider<SmsRegisterNotifier, AsyncValue<void>>((ref) => SmsRegisterNotifier());

/// 验证码发送状态
final smsCodeProvider = StateNotifierProvider<SmsCodeNotifier, SmsCodeState>((ref) => SmsCodeNotifier());

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

// ==================== 验证码登录相关 ====================

/// 验证码发送状态
class SmsCodeState {
  final bool isSending;
  final bool canSend;
  final int countdown;
  final String? error;

  SmsCodeState({this.isSending = false, this.canSend = true, this.countdown = 0, this.error});

  SmsCodeState copyWith({bool? isSending, bool? canSend, int? countdown, String? error}) {
    return SmsCodeState(
      isSending: isSending ?? this.isSending,
      canSend: canSend ?? this.canSend,
      countdown: countdown ?? this.countdown,
      error: error,
    );
  }
}

/// 验证码发送管理
class SmsCodeNotifier extends StateNotifier<SmsCodeState> {
  SmsCodeNotifier() : super(SmsCodeState());

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  /// 发送验证码
  Future<void> sendCode(String phone) async {
    // 验证手机号格式
    final phoneRegex = RegExp(r'^1\d{10}$');
    if (!phoneRegex.hasMatch(phone)) {
      state = state.copyWith(error: '请输入正确的11位手机号');
      return;
    }

    state = state.copyWith(isSending: true, error: null);

    try {
      if (LiveConfig.bypassLoginApi) {
        // 开发模式：模拟发送成功
        await Future.delayed(const Duration(seconds: 1));
        _startCountdown();
        return;
      }

      // 调用后端发送验证码 API
      final String sendCodeUrl = 'http://${LiveConfig.serverIP}:8000/api/v1/sendSmsCode';
      final response = await _dio.post(sendCodeUrl, data: {'phone': phone});

      if (response.statusCode == 200 && response.data['code'] == 0) {
        _startCountdown();
      } else {
        state = state.copyWith(isSending: false, error: response.data['message'] ?? '发送失败');
      }
    } catch (e) {
      String errorMsg = '网络连接失败';
      if (e is DioException) {
        errorMsg = e.response?.data['message'] ?? e.message ?? errorMsg;
      } else {
        errorMsg = e.toString();
      }
      state = state.copyWith(isSending: false, error: errorMsg);
    }
  }

  /// 开始倒计时
  void _startCountdown() {
    state = state.copyWith(isSending: false, canSend: false, countdown: 60);

    // 每秒更新倒计时
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.countdown <= 1) {
        timer.cancel();
        state = state.copyWith(canSend: true, countdown: 0);
      } else {
        state = state.copyWith(countdown: state.countdown - 1);
      }
    });
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// 验证码登录管理
class SmsLoginNotifier extends StateNotifier<AsyncValue<void>> {
  SmsLoginNotifier() : super(const AsyncValue.data(null));

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  /// 验证码登录
  Future<void> loginWithSms(String phone, String code) async {
    state = const AsyncValue.loading();

    try {
      if (LiveConfig.bypassLoginApi) {
        // 开发模式：模拟登录成功
        await Future.delayed(const Duration(seconds: 1));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kUserAccount, phone);
        await prefs.setBool(_kIsLoggedIn, true);
        await prefs.setString(_kUserToken, 'dev-bypass-token-sms');
        state = const AsyncValue.data(null);
        return;
      }

      // 调用后端验证码登录 API
      final String loginUrl = 'http://${LiveConfig.serverIP}:8000/api/v1/loginBySms';
      final response = await _dio.post(loginUrl, data: {'phone': phone, 'code': code});

      if (response.statusCode == 200 && response.data['code'] == 0) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kUserAccount, phone);
        await prefs.setBool(_kIsLoggedIn, true);
        await prefs.setString(_kUserToken, response.data['token'] ?? '');
        state = const AsyncValue.data(null);
      } else {
        throw response.data['message'] ?? '验证码错误或已过期';
      }
    } catch (e, stk) {
      String errorMsg = '网络连接失败';
      if (e is DioException) {
        errorMsg = e.response?.data['message'] ?? e.message ?? errorMsg;
      } else {
        errorMsg = e.toString();
      }
      state = AsyncValue.error(errorMsg, stk);
    }
  }
}

/// 手机号验证码注册管理
class SmsRegisterNotifier extends StateNotifier<AsyncValue<void>> {
  SmsRegisterNotifier() : super(const AsyncValue.data(null));

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  /// 手机号验证码注册
  /// 参数：phone - 手机号，code - 验证码，password - 密码
  Future<void> register(String phone, String code, String password) async {
    state = const AsyncValue.loading();

    try {
      if (LiveConfig.bypassLoginApi) {
        // 开发模式：模拟注册成功
        await Future.delayed(const Duration(seconds: 1));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kUserAccount, phone);
        await prefs.setBool(_kIsLoggedIn, true);
        await prefs.setString(_kUserToken, 'dev-bypass-token-register');
        state = const AsyncValue.data(null);
        return;
      }

      // 调用后端注册 API：phone + code + password
      final String registerUrl = 'http://${LiveConfig.serverIP}:8000/api/v1/register';
      final response = await _dio.post(registerUrl, data: {
        'phone': phone,
        'code': code,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['code'] == 0) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kUserAccount, phone);
        await prefs.setBool(_kIsLoggedIn, true);
        await prefs.setString(_kUserToken, response.data['token'] ?? '');
        state = const AsyncValue.data(null);
      } else {
        throw response.data['message'] ?? '注册失败，请检查验证码或手机号';
      }
    } catch (e, stk) {
      String errorMsg = '网络连接失败';
      if (e is DioException) {
        errorMsg = e.response?.data['message'] ?? e.message ?? errorMsg;
      } else {
        errorMsg = e.toString();
      }
      state = AsyncValue.error(errorMsg, stk);
    }
  }
}
