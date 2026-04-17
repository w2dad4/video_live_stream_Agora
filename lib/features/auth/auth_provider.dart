// 用户认证与数据隔离核心
// ❗核心原则：所有数据必须带 userId
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// 当前登录用户ID
/// null = 未登录
final currentUserIdProvider = StateProvider<String?>((ref) => null);

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
    // TODO: 从本地存储或 API 加载用户数据
    // 临时：设置默认数据
    state = UserData(uid: userId, name: '用户_$userId', avatar: 'assets/image/002.png');
  }

  void updateUserData(UserData data) {
    state = data;
    // TODO: 保存到本地存储
  }
}

/// 便捷获取当前登录用户数据
final currentUserDataProvider = Provider<UserData?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(userDataProvider(userId));
});
