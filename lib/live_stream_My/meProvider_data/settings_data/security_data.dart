// ==================== 数据层：帐号安全本地状态 ====================
import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';

final securityProvider = StateNotifierProvider<SecurityNotifier, SecurityState>((ref) => SecurityNotifier());

class SecurityState {
  final String phone;
  final String email;
  final String password;
  final List<String> passwordHistory; // 历史密码
  final List<DeviceSession> devices; // 设备会话
  final bool loginProtect; //
  final bool payProtect;
  final bool deviceLoaded; // 当前设备是否已识别
  final bool deviceLoading; // 当前设备是否识别中
  final String deviceError; // 当前设备识别错误文案

  const SecurityState({
    required this.phone,
    required this.email,
    required this.password,
    required this.passwordHistory,
    required this.devices, //
    this.loginProtect = true,
    this.payProtect = true,
    this.deviceLoaded = false,
    this.deviceLoading = false,
    this.deviceError = '',
  });

  SecurityState copyWith({
    String? phone,
    String? email,
    String? password,
    List<String>? passwordHistory,
    List<DeviceSession>? devices, //
    bool? loginProtect,
    bool? payProtect,
    bool? deviceLoaded,
    bool? deviceLoading,
    String? deviceError,
  }) {
    return SecurityState(
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      passwordHistory: passwordHistory ?? this.passwordHistory, //
      devices: devices ?? this.devices,
      loginProtect: loginProtect ?? this.loginProtect,
      payProtect: payProtect ?? this.payProtect,
      deviceLoaded: deviceLoaded ?? this.deviceLoaded,
      deviceLoading: deviceLoading ?? this.deviceLoading,
      deviceError: deviceError ?? this.deviceError,
    );
  }
}

class DeviceSession {
  final String id;
  final String deviceName;
  final String location; //
  final String loginTime;
  final bool isCurrent;
  final bool trusted;

  const DeviceSession({
    required this.id,
    required this.deviceName,
    required this.location,
    required this.loginTime, //
    this.isCurrent = false,
    this.trusted = true,
  });

  DeviceSession copyWith({bool? trusted}) {
    return DeviceSession(
      id: id,
      deviceName: deviceName,
      location: location,
      loginTime: loginTime,
      isCurrent: isCurrent,
      trusted: trusted ?? this.trusted, //
    );
  }
}

class SecurityNotifier extends StateNotifier<SecurityState> {
  SecurityNotifier()
    : super(
        const SecurityState(
          phone: '138****8899',
          email: 'cat@example.com',
          password: 'Cat123456',
          passwordHistory: ['Cat123123', 'Cat123456'], //
          devices: [],
        ),
      );

  bool _loadingDevice = false;

  // 对外暴露：在 UI 进入设备页后触发，避免插件注册时机问题
  Future<void> ensureCurrentDeviceLoaded({bool force = false}) async {
    if (_loadingDevice) return;
    if (!force && state.deviceLoaded) return;
    await _initDeviceInfo();
  }

  // 对外暴露：手动重试识别当前设备
  Future<void> reloadCurrentDevice() async {
    await ensureCurrentDeviceLoaded(force: true);
  }

  // 获取真实设备信息的异步方法
  Future<void> _initDeviceInfo() async {
    _loadingDevice = true;
    state = state.copyWith(deviceLoading: true, deviceError: '');
    final deviceInfoPlugin = DeviceInfoPlugin();
    String deviceName = "未知设备";
    String deviceId = "unknown_id";
    String location = '本地网络';
    String errorText = '';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        // 安卓设备：品牌 + 机型，设备号优先使用 id，兜底 fingerprint
        deviceName = "${androidInfo.brand} ${androidInfo.model}";
        final androidId = androidInfo.id.trim();
        final fallbackId = androidInfo.fingerprint.trim();
        deviceId = androidId.isNotEmpty ? androidId : (fallbackId.isNotEmpty ? fallbackId : 'android_unknown_id');
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        // iOS 设备：名称 + vendor id
        deviceName = iosInfo.name;
        deviceId = iosInfo.identifierForVendor ?? "ios_id";
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfoPlugin.macOsInfo;
        // macOS 设备：型号 + systemGUID
        deviceName = macInfo.model;
        deviceId = macInfo.systemGUID ?? "mac_id";
      } else {
        deviceName = Platform.operatingSystem;
        deviceId = "unsupported_${Platform.operatingSystem}";
        location = '当前平台暂不支持自动识别';
      }
    } on MissingPluginException catch (e) {
      debugPrint("===== 获取设备信息失败 =====");
      debugPrint("错误原因: $e");
      deviceName = "识别失败";
      deviceId = "missing_plugin_${DateTime.now().millisecondsSinceEpoch}";
      location = '插件未注册，可重试';
      errorText = '插件未注册，请热重启或重装应用后重试';
    } catch (e) {
      debugPrint("===== 获取设备信息失败 =====");
      debugPrint("错误原因: $e");
      deviceName = "识别失败";
      deviceId = "load_failed_${DateTime.now().millisecondsSinceEpoch}";
      location = '设备识别异常，可重试';
      errorText = '设备信息识别失败：$e';
    }

    // 保留非当前设备列表，避免每次重试覆盖管理结果
    final others = state.devices.where((e) => !e.isCurrent).toList();
    if (others.isEmpty) {
      others.add(const DeviceSession(id: 'mock_2', deviceName: 'iPad Pro', location: '中国·上海', loginTime: '2026-04-07 18:20'));
    }

    // 组装最终状态
    state = state.copyWith(
      devices: [
        // 1. 真实的当前设备
        DeviceSession(
          id: deviceId,
          deviceName: deviceName,
          location: location, // 真实定位通常由后端根据IP解析
          loginTime: _formatNow(),
          isCurrent: true,
        ),
        // 2. 其他设备（演示数据或历史保留）
        ...others,
      ],
      deviceLoaded: true,
      deviceLoading: false,
      deviceError: errorText,
    );
    _loadingDevice = false;
  }

  String _formatNow() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  void updatePhone(String phone) {
    state = state.copyWith(phone: phone);
  }

  bool updatePassword({required String oldPwd, required String newPwd}) {
    if (oldPwd != state.password) return false;
    final nextHistory = [state.password, ...state.passwordHistory]; //
    state = state.copyWith(password: newPwd, passwordHistory: nextHistory.take(5).toList());
    return true;
  }

  void resetPassword(String newPwd) {
    final nextHistory = [state.password, ...state.passwordHistory]; //
    state = state.copyWith(password: newPwd, passwordHistory: nextHistory.take(5).toList());
  }

  // 业务方法：强制下线
  void forceOffline(String deviceId) {
    state = state.copyWith(
      devices: state.devices.where((e) => e.id != deviceId).toList(), //
    );
  }

  void removeUnknownDevices() {
    state = state.copyWith(devices: state.devices.where((e) => e.trusted).toList());
  }

  void toggleLoginProtect(bool v) {
    state = state.copyWith(loginProtect: v);
  }

  void togglePayProtect(bool v) {
    state = state.copyWith(payProtect: v);
  }
}

// ==================== 验证码发送状态 ====================
class VerifyCodeState {
  final bool canSend; // 是否可以发送
  final bool sending; // 是否正在请求发送
  final int seconds; // 倒计时秒数

  const VerifyCodeState({this.canSend = true, this.sending = false, this.seconds = 0});

  VerifyCodeState copyWith({bool? canSend, bool? sending, int? seconds}) {
    return VerifyCodeState(canSend: canSend ?? this.canSend, sending: sending ?? this.sending, seconds: seconds ?? this.seconds);
  }
}

final verifyCodeProvider = StateNotifierProvider<VerifyCodeNotifier, VerifyCodeState>((ref) => VerifyCodeNotifier());

class VerifyCodeNotifier extends StateNotifier<VerifyCodeState> {
  VerifyCodeNotifier() : super(const VerifyCodeState());
  Timer? _timer;

  // 发送验证码并启动倒计时
  Future<bool> sendCode({required String account}) async {
    if (!state.canSend || state.sending) return false;
    state = state.copyWith(sending: true);

    final ok = await _mockSendCode(account);
    if (!ok) {
      state = state.copyWith(sending: false);
      return false;
    }

    // 发送成功：进入 60 秒倒计时
    const total = 60;
    state = state.copyWith(sending: false, canSend: false, seconds: total);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = state.seconds - 1;
      if (left <= 0) {
        timer.cancel();
        state = state.copyWith(canSend: true, seconds: 0);
      } else {
        state = state.copyWith(seconds: left);
      }
    });
    return true;
  }

  Future<bool> _mockSendCode(String account) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return account.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
