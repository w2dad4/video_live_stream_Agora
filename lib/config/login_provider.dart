//模拟登陆逻辑
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

//1. 定义登录状态 Provider
final loginProvider = StateNotifierProvider<LoginNotifier, AsyncValue<void>>((ref) => LoginNotifier());

class LoginNotifier extends StateNotifier<AsyncValue<void>> {
  LoginNotifier() : super(const AsyncValue.data(null));
  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      //模拟网络请求
      await Future.delayed(const Duration(seconds: 2));
      //假设登陆成功了
      state = const AsyncValue.data(null);
    } catch (e, stk) {
      state = AsyncValue.error(e, stk);
    }
  }
}
