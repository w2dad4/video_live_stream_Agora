import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../live_stream_message/contact/contact_UI/constants.dart'; // 导入 LiveConfig 以获取动态 IP

// 持久化常量定义
const String _kUserAccount = 'user_account';
const String _kIsLoggedIn = 'is_logged_in';
const String _kUserToken = 'token';
const String _kUserId = 'user_id';
const String _kPhoneUidMap = 'phone_uid_map';
const String _kUsedUids = 'used_uids';

String _profileCompletedKey(String userId) => 'profile_completed_$userId';
String _isNewUserKey(String userId) => 'is_new_user_$userId';

bool _isValidUid(String uid) => RegExp(r'^\d{7,11}$').hasMatch(uid);

Future<Map<String, String>> _readPhoneUidMap(SharedPreferences prefs) async {
  final raw = prefs.getString(_kPhoneUidMap);
  if (raw == null || raw.isEmpty) return {};
  try {
    final decoded = (jsonDecode(raw) as Map).cast<String, dynamic>();
    return decoded.map((k, v) => MapEntry(k, v.toString()));
  } catch (_) {
    return {};
  }
}

Future<void> _writePhoneUidMap(SharedPreferences prefs, Map<String, String> map) async {
  await prefs.setString(_kPhoneUidMap, jsonEncode(map));
}

Future<Set<String>> _readUsedUidSet(SharedPreferences prefs) async {
  final raw = prefs.getStringList(_kUsedUids);
  if (raw == null) return <String>{};
  return raw.toSet();
}

Future<void> _writeUsedUidSet(SharedPreferences prefs, Set<String> used) async {
  await prefs.setStringList(_kUsedUids, used.toList(growable: false));
}

Future<void> _migrateUidRelatedData(SharedPreferences prefs, {required String oldUid, required String newUid}) async {
  if (oldUid.isEmpty || oldUid == newUid) return;

  final oldProfileKey = 'user_profile_$oldUid';
  final newProfileKey = 'user_profile_$newUid';
  if (prefs.containsKey(oldProfileKey) && !prefs.containsKey(newProfileKey)) {
    final raw = prefs.getString(oldProfileKey);
    if (raw != null && raw.isNotEmpty) {
      await prefs.setString(newProfileKey, raw);
    }
  }

  final oldCompletedKey = _profileCompletedKey(oldUid);
  final newCompletedKey = _profileCompletedKey(newUid);
  if (prefs.containsKey(oldCompletedKey) && !prefs.containsKey(newCompletedKey)) {
    final completed = prefs.getBool(oldCompletedKey);
    if (completed != null) {
      await prefs.setBool(newCompletedKey, completed);
    }
  }

  final oldNewUserKey = _isNewUserKey(oldUid);
  final newNewUserKey = _isNewUserKey(newUid);
  if (prefs.containsKey(oldNewUserKey) && !prefs.containsKey(newNewUserKey)) {
    final isNew = prefs.getBool(oldNewUserKey);
    if (isNew != null) {
      await prefs.setBool(newNewUserKey, isNew);
    }
  }
}

String _generateUid(Set<String> used) {
  final random = math.Random();
  for (int i = 0; i < 5000; i++) {
    final int length = 7 + random.nextInt(5); // 7~11
    final first = 1 + random.nextInt(9); // 首位不为0
    final tail = List.generate(length - 1, (_) => random.nextInt(10).toString()).join();
    final uid = '$first$tail';
    if (!used.contains(uid)) return uid;
  }
  // 极低概率兜底：取毫秒时间后11位，保证是数字
  final fallback = DateTime.now().millisecondsSinceEpoch.toString().substring(2, 13);
  if (!used.contains(fallback)) return fallback;
  return '${1 + random.nextInt(9)}${DateTime.now().microsecondsSinceEpoch.toString().substring(4, 14)}';
}

Future<bool> hasLocalUserByPhone(String phone) async {
  final prefs = await SharedPreferences.getInstance();
  final map = await _readPhoneUidMap(prefs);
  return map.containsKey(phone.trim());
}

Future<String?> readUserIdByPhone(String phone) async {
  final prefs = await SharedPreferences.getInstance();
  final map = await _readPhoneUidMap(prefs);
  final mapped = map[phone.trim()]?.trim() ?? '';
  if (_isValidUid(mapped)) return mapped;
  if (mapped.isEmpty) return null;
  return ensureUserId(phone: phone, preferredId: mapped);
}

Future<String> ensureUserId({String? preferredId, String? phone}) async {
  final prefs = await SharedPreferences.getInstance();
  final normalizedPhone = (phone ?? prefs.getString(_kUserAccount) ?? '').trim();
  final preferred = (preferredId ?? '').trim();
  final used = await _readUsedUidSet(prefs);

  if (normalizedPhone.isNotEmpty) {
    final map = await _readPhoneUidMap(prefs);
    final mapped = map[normalizedPhone]?.trim() ?? '';
    final legacyUid = mapped;
    if (_isValidUid(mapped)) {
      used.add(mapped);
      await _writeUsedUidSet(prefs, used);
      await prefs.setString(_kUserId, mapped);
      return mapped;
    }

    String uid;
    if (_isValidUid(preferred)) {
      final usedBySamePhone = map[normalizedPhone] == preferred;
      final usedByOtherPhone = map.entries.any((e) => e.key != normalizedPhone && e.value == preferred);
      if ((usedBySamePhone || !used.contains(preferred)) && !usedByOtherPhone) {
        uid = preferred;
      } else {
        uid = _generateUid(used);
      }
    } else {
      uid = _generateUid(used);
    }

    map[normalizedPhone] = uid;
    used.add(uid);
    await _writePhoneUidMap(prefs, map);
    await _writeUsedUidSet(prefs, used);
    await prefs.setString(_kUserId, uid);
    await _migrateUidRelatedData(prefs, oldUid: legacyUid, newUid: uid);
    return uid;
  }

  final existing = prefs.getString(_kUserId)?.trim() ?? '';
  if (_isValidUid(existing)) {
    used.add(existing);
    await _writeUsedUidSet(prefs, used);
    return existing;
  }

  final uid = _isValidUid(preferred) && !used.contains(preferred) ? preferred : _generateUid(used);
  used.add(uid);
  await _writeUsedUidSet(prefs, used);
  await prefs.setString(_kUserId, uid);
  await _migrateUidRelatedData(prefs, oldUid: existing, newUid: uid);
  return uid;
}

Future<void> writeProfileCompleted(String userId, bool completed) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_profileCompletedKey(userId), completed);
}

Future<void> writeIsNewUser(String userId, bool isNewUser) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_isNewUserKey(userId), isNewUser);
}

Future<bool> readIsNewUser({String? userId}) async {
  final prefs = await SharedPreferences.getInstance();
  final uid = userId ?? prefs.getString(_kUserId) ?? '';
  if (uid.isEmpty) return false;
  return prefs.getBool(_isNewUserKey(uid)) ?? false;
}

Future<bool> readProfileCompleted({String? userId}) async {
  final prefs = await SharedPreferences.getInstance();
  final uid = userId ?? prefs.getString(_kUserId) ?? '';
  if (uid.isEmpty) return false;
  final key = _profileCompletedKey(uid);
  final stored = prefs.getBool(key);
  if (stored != null) return stored;

  // 兼容老版本：如果本地已有完整资料，则自动视为已完善，避免重复强制引导。
  final profileRaw = prefs.getString('user_profile_$uid');
  if (profileRaw != null && profileRaw.isNotEmpty) {
    try {
      final profile = (jsonDecode(profileRaw) as Map).cast<String, dynamic>();
      final name = (profile['name'] ?? '').toString().trim();
      final avatar = (profile['avatar'] ?? '').toString().trim();
      final inferred = name.isNotEmpty && name != '用户_$uid' && avatar.isNotEmpty;
      await prefs.setBool(key, inferred);
      return inferred;
    } catch (_) {
      return false;
    }
  }
  return false;
}

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

/// 读取保存的用户ID
Future<String?> readUserId() async {
  final prefs = await SharedPreferences.getInstance();
  final existing = prefs.getString(_kUserId)?.trim() ?? '';
  if (_isValidUid(existing)) return existing;

  final phone = prefs.getString(_kUserAccount)?.trim() ?? '';
  if (phone.isNotEmpty) {
    return ensureUserId(phone: phone, preferredId: existing);
  }
  if (existing.isNotEmpty) {
    return ensureUserId(preferredId: existing);
  }
  return null;
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
        final isOldUser = await hasLocalUserByPhone(username);
        final userId = await ensureUserId(phone: username);
        await prefs.setString(_kUserAccount, username);
        await prefs.setBool(_kIsLoggedIn, true);
        await prefs.setString(_kUserToken, 'dev-bypass-token');
        await writeIsNewUser(userId, !isOldUser);
        final completed = await readProfileCompleted(userId: userId);
        await writeProfileCompleted(userId, isOldUser ? completed : false);
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
        final serverUserId = response.data['data']?['userId']?.toString() ?? response.data['userId']?.toString();
        final userId = await ensureUserId(preferredId: serverUserId, phone: username);

        // 核心持久化逻辑
        await prefs.setString(_kUserAccount, username);
        await prefs.setBool(_kIsLoggedIn, true);
        await prefs.setString(_kUserToken, response.data['token'] ?? '');

        // 读取后端返回的新用户标记
        final dynamic isNewUserRaw = response.data['data']?['isNewUser'] ?? response.data['isNewUser'];
        final bool isNewUser = isNewUserRaw is bool ? isNewUserRaw : false;
        await writeIsNewUser(userId, isNewUser);

        // 读取资料完善状态
        final dynamic profileCompletedRaw = response.data['data']?['profileCompleted'] ?? response.data['profileCompleted'];
        if (profileCompletedRaw is bool) {
          await writeProfileCompleted(userId, profileCompletedRaw);
        } else {
          final completed = await readProfileCompleted(userId: userId);
          await writeProfileCompleted(userId, completed);
        }

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
    return SmsCodeState(isSending: isSending ?? this.isSending, canSend: canSend ?? this.canSend, countdown: countdown ?? this.countdown, error: error);
  }
}

/// 验证码发送管理
class SmsCodeNotifier extends StateNotifier<SmsCodeState> {
  SmsCodeNotifier() : super(SmsCodeState());

  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 5), receiveTimeout: const Duration(seconds: 3)));

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

  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 5), receiveTimeout: const Duration(seconds: 3)));

  /// 验证码登录
  Future<void> loginWithSms(String phone, String code) async {
    state = const AsyncValue.loading();

    try {
      if (LiveConfig.bypassLoginApi) {
        // 开发模式：模拟登录成功
        await Future.delayed(const Duration(seconds: 1));
        final prefs = await SharedPreferences.getInstance();
        final isOldUser = await hasLocalUserByPhone(phone);
        final userId = await ensureUserId(phone: phone);
        await prefs.setString(_kUserAccount, phone);
        await prefs.setBool(_kIsLoggedIn, true);
        await prefs.setString(_kUserToken, 'dev-bypass-token-sms');
        await writeIsNewUser(userId, !isOldUser);
        final completed = await readProfileCompleted(userId: userId);
        await writeProfileCompleted(userId, isOldUser ? completed : false);
        state = const AsyncValue.data(null);
        return;
      }

      // 调用后端验证码登录 API
      final String loginUrl = 'http://${LiveConfig.serverIP}:8000/api/v1/loginBySms';
      final response = await _dio.post(loginUrl, data: {'phone': phone, 'code': code});

      if (response.statusCode == 200 && response.data['code'] == 0) {
        final prefs = await SharedPreferences.getInstance();
        final serverUserId = response.data['data']?['userId']?.toString() ?? response.data['userId']?.toString();
        final userId = await ensureUserId(preferredId: serverUserId, phone: phone);
        await prefs.setString(_kUserAccount, phone);
        await prefs.setBool(_kIsLoggedIn, true);
        await prefs.setString(_kUserToken, response.data['token'] ?? '');

        // 读取后端返回的新用户标记
        final dynamic isNewUserRaw = response.data['data']?['isNewUser'] ?? response.data['isNewUser'];
        final bool isNewUser = isNewUserRaw is bool ? isNewUserRaw : false;
        await writeIsNewUser(userId, isNewUser);

        // 读取资料完善状态
        final dynamic profileCompletedRaw = response.data['data']?['profileCompleted'] ?? response.data['profileCompleted'];
        if (profileCompletedRaw is bool) {
          await writeProfileCompleted(userId, profileCompletedRaw);
        } else {
          final completed = await readProfileCompleted(userId: userId);
          await writeProfileCompleted(userId, completed);
        }
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

  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 5), receiveTimeout: const Duration(seconds: 3)));

  /// 手机号验证码注册
  /// 参数：phone - 手机号，code - 验证码，password - 密码
  Future<void> register(String phone, String code, String password) async {
    state = const AsyncValue.loading();

    try {
      if (LiveConfig.bypassLoginApi) {
        // 开发模式：模拟注册成功
        await Future.delayed(const Duration(seconds: 1));
        final prefs = await SharedPreferences.getInstance();
        final userId = await ensureUserId(phone: phone);
        await prefs.setString(_kUserAccount, phone);
        await prefs.setString(_kUserId, userId);
        await prefs.setBool(_kIsLoggedIn, true);
        await prefs.setString(_kUserToken, 'dev-bypass-token-register');
        await writeIsNewUser(userId, true); // 注册时设置为新用户
        await writeProfileCompleted(userId, false);
        state = const AsyncValue.data(null);
        return;
      }

      // 调用后端注册 API：phone + code + password
      final String registerUrl = 'http://${LiveConfig.serverIP}:8000/api/v1/register';
      final response = await _dio.post(registerUrl, data: {'phone': phone, 'code': code, 'password': password});

      if (response.statusCode == 200 && response.data['code'] == 0) {
        final prefs = await SharedPreferences.getInstance();
        // 从后端响应获取用户ID，如果没有则生成一个
        final serverUserId = response.data['data']?['userId']?.toString() ?? response.data['userId']?.toString();
        final userId = await ensureUserId(preferredId: serverUserId, phone: phone);
        await prefs.setString(_kUserAccount, phone);
        await prefs.setString(_kUserId, userId);
        await prefs.setBool(_kIsLoggedIn, true);
        await prefs.setString(_kUserToken, response.data['token'] ?? response.data['data']?['token'] ?? '');
        await writeIsNewUser(userId, true); // 注册时设置为新用户
        await writeProfileCompleted(userId, false);
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
