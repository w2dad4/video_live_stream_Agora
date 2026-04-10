import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/config/app_config.dart';

// --- 1. 定义版本数据模型 ---
class VersionInfo {
  final String version;
  final String content;
  final bool hasUpdate;
  VersionInfo({required this.version, required this.content, required this.hasUpdate});
}

// --- 2. 模拟网络请求的 Provider ---
final versionCheckProvider = FutureProvider<VersionInfo>((ref) async {
  // 模拟网络延迟，实际开发中这里对接你的 SRS 或后台 API
  await Future.delayed(const Duration(seconds: 1));
  return VersionInfo(
    version: '1.2.0',
    content: AppConfig.updateContent,
    hasUpdate: false, // 切换为 true 即可看到“立即更新”状态
  );
});

// --- 3. 界面实现 ---
class VersionUpdatePage extends ConsumerWidget {
  const VersionUpdatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(versionCheckProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('版本更新', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new, size: 20)),
      ),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            const Spacer(flex: 1),
            // APP 图标区域
            _buildAppIcon(),
            const SizedBox(height: 24),
            Text('当前版本 ${AppConfig.currentVersion}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const Spacer(flex: 1),
            // 响应式内容区域
            versionAsync.when(
              data: (info) => _buildUpdateUI(context, ref, info),
              loading: () => const CircularProgressIndicator.adaptive(), //
              error: (err, _) => Text('检查失败: $err'),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildAppIcon() {
    return AppConfig.getGradientLogoContainer(size: 100, borderRadius: 24);
  }

  Widget _buildUpdateUI(BuildContext context, WidgetRef ref, VersionInfo info) {
    if (!info.hasUpdate) {
      return const Text(
        '已是最新版本',
        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Text('发现新版本 ${info.version}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            info.content,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.6),
          ),
          const SizedBox(height: 40),
          // 液态玻璃按钮
          _buildLiquidGlassButton(
            onTap: () => print("开始下载更新..."),
            child: const Text(
              '立即安装更新',
              style: TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidGlassButton({required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              // 这里的颜色的 values 符合 Flutter 3.x 最新语法
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
              gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
