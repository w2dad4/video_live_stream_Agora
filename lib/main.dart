import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:video_live_stream/library.dart';
import 'package:video_live_stream/features/auth/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isLoggedIn = await readIsLoggedIn();
  if (!isLoggedIn) {
    Approute.initialLocation = '/Login';
  } else {
    final userId = await readUserId();
    setInitialUserId(userId);
    final isNewUser = await readIsNewUser(userId: userId);
    final completed = await readProfileCompleted(userId: userId);
    // 新用户或未完善资料的用户进入资料完善页，老用户直接进入首页
    Approute.initialLocation = (isNewUser || !completed) ? '/Onboarding' : '/';
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: Approute.router, // 引用你定义的 GoRouter
      title: '小猫啵啵',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
    );
  }
}

// bottomNavigationBar 底部
class Mylivestream extends StatefulWidget {
  const Mylivestream({super.key});

  @override
  State<Mylivestream> createState() => MyMylivestreamState();
}

class MyMylivestreamState extends State<Mylivestream> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home_outlined, 'active': Icons.home, 'label': '首页', 'page': const MyHomeTab()},
    {'icon': Icons.explore_outlined, 'active': Icons.explore, 'label': '消息', 'page': const VideoMessagePage()},
    {'icon': Icons.center_focus_weak, 'active': Icons.center_focus_strong, 'label': '开播', 'page': const OnairPage()},
    {'icon': Icons.person_outlined, 'active': Icons.person, 'label': '我的', 'page': const MyVideoPage()},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      // 使用 IndexedStack 可以保持页面状态（比如你在首页刷到一半，切到“我的”再回来，进度还在）
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: const [MyHomeTab(), VideoMessagePage(), OnairPage(), MyVideoPage()]),
        ],
      ),
      bottomNavigationBar: Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 0), child: _buildBottomNavigationBar()),
    );
  }

  // bottomNavigationBar 底部的一个毛玻璃胶囊
  Widget _buildBottomNavigationBar() {
    // 白底下调高不透明度，模拟亚克力板
    // 白底下用微弱的黑边勾勒轮廓
    final Color borderColor = Colors.black.withValues(alpha: 0.08);
    // 颜色适配：白底下用黑色系，深色底下用白色系
    const Color activeColor = Colors.blueAccent;
    const Color inactiveColor = Colors.black54;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        // 毛玻璃模糊度
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navItems.asMap().entries.map((entry) {
              final int idx = entry.key;
              final item = entry.value;
              final bool isSelected = _currentIndex == idx;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = idx),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        // 选中时的胶囊底色
                        color: isSelected ? Colors.grey.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 图标
                          Icon(isSelected ? item['active'] as IconData : item['icon'] as IconData, color: isSelected ? activeColor : inactiveColor, size: 24),
                          const SizedBox(height: 2),
                          Text(
                            item['label'] as String,
                            style: TextStyle(fontSize: 10, color: isSelected ? activeColor : inactiveColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
