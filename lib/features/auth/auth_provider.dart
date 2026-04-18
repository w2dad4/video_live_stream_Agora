// 用户认证与数据隔离核心
// ❗核心原则：所有数据必须带 userId
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kUserProfilePrefix = 'user_profile_';

String? _initialUserId;

/// 在 App 启动阶段注入已登录用户ID，避免冷启动后 meProvider 为空。
void setInitialUserId(String? userId) {
  final v = userId?.trim() ?? '';
  _initialUserId = v.isEmpty ? null : v;
}

String _profileKey(String userId) => '$_kUserProfilePrefix$userId';

/// 当前登录用户ID
/// null = 未登录
final currentUserIdProvider = StateProvider<String?>((ref) => _initialUserId);

/// 是否已登录
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserIdProvider) != null;
});

/// 用户数据模型
class UserData {
  final String uid;
  final String name;
  final String? avatar;
  final String? email;
  final String? phone;
  final String? gender;
  final String? region;
  final String? signature;

  const UserData({required this.uid, required this.name, this.avatar, this.email, this.phone, this.gender, this.region, this.signature});

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      uid: (json['uid'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      avatar: json['avatar']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      gender: json['gender']?.toString(),
      region: json['region']?.toString(),
      signature: json['signature']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'avatar': avatar,
    'email': email,
    'phone': phone,
    'gender': gender,
    'region': region,
    'signature': signature,
  };

  UserData copyWith({String? name, String? avatar, String? email, String? phone, String? gender, String? region, String? signature}) {
    return UserData(uid: uid, name: name ?? this.name, avatar: avatar ?? this.avatar, email: email ?? this.email, phone: phone ?? this.phone, gender: gender ?? this.gender, region: region ?? this.region, signature: signature ?? this.signature);
  }
}

/// 🔐 按 userId 隔离的用户数据
/// 使用 family 确保每个用户有独立的数据
final userDataProvider = StateNotifierProvider.family<UserDataNotifier, UserData?, String>((ref, userId) => UserDataNotifier(userId));

class UserDataNotifier extends StateNotifier<UserData?> {
  final String userId;

  UserDataNotifier(this.userId) : super(null) {
    // 初始化时从本地存储或服务端加载
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey(userId));

    if (raw != null && raw.isNotEmpty) {
      try {
        final Map<String, dynamic> map = (jsonDecode(raw) as Map).cast<String, dynamic>();
        state = UserData.fromJson(map);
        return;
      } catch (_) {
        // 本地脏数据时回退默认值，避免页面崩溃。
      }
    }

    final defaultData = UserData(
      uid: userId,
      name: '用户_$userId',
      avatar: 'assets/image/002.png',
      gender: '未设置',
      region: '未设置',
      signature: '这个人很懒，还没有签名',
    );
    state = defaultData;
    await _persist(defaultData);
  }

  void updateUserData(UserData data) {
    state = data;
    _persist(data);
  }

  Future<void> _persist(UserData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey(userId), jsonEncode(data.toJson()));
  }
}

/// 便捷获取当前登录用户数据
final currentUserDataProvider = Provider<UserData?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(userDataProvider(userId));
});
