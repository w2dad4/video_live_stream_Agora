import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/config/login_provider.dart';

class Login extends ConsumerWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听登录状态
    final loginState = ref.watch(loginProvider);
    // 监听登录成功后的跳转逻辑
    ref.listen<AsyncValue<void>>(loginProvider, (previous, next) {
      next.whenOrNull(
        data: (data) => context.pushNamed('Mylivestream'),
        error: (error, stackTrace) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('登陆失败:$error'))),
      );
    });
    return Scaffold(
      appBar: AppBar(title: Text('登陆小猫啵啵'), centerTitle: true),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            const FlutterLogo(size: 100),
            const SizedBox(height: 40),
            TextField(
              decoration: InputDecoration(labelText: '帐号', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(labelText: '密码', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('已阅读并同意', style: TextStyle(fontSize: 12)),
                Text('服务协议', style: TextStyle(color: Colors.blue, fontSize: 12)),
                Text('和', style: TextStyle(fontSize: 12)),
                Text('隐私保护协议', style: TextStyle(color: Colors.blue, fontSize: 12)),
              ],
            ),
            //登陆按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              // 如果正在加载，则禁用按钮
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: loginState.isLoading ? null : () => ref.read(loginProvider.notifier).login('admin', '123456'),
                child: loginState.isLoading ? const CircularProgressIndicator(color: Colors.white) : Text('登陆', style: TextStyle(fontSize: 20, color: Colors.white)),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                TextButton(onPressed: () {}, child: Text('手机号登陆')),
                const SizedBox(width: 20),
                TextButton(onPressed: () {}, child: Text('注册')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
