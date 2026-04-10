//功能介绍
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/config/app_config.dart';

class FeatureIntroduction extends ConsumerWidget {
  const FeatureIntroduction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('功能介绍', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new, size: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Logo 和标语
          Center(
            child: Column(
              children: [
                AppConfig.getGradientLogoContainer(size: 80, borderRadius: 20),
                const SizedBox(height: 16),
                Text(
                  AppConfig.appName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                ),
                const SizedBox(height: 8),
                Text(AppConfig.brandSlogan, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // 核心功能
          _buildSectionTitle('核心功能'),
          const SizedBox(height: 16),
          _buildFeatureCard(icon: Icons.live_tv, iconColor: Colors.red, title: '高清直播', description: '支持720P/1080P高清画质，流畅不卡顿，让精彩时刻清晰呈现'),
          _buildFeatureCard(icon: Icons.chat_bubble, iconColor: Colors.blue, title: '实时互动', description: '弹幕聊天、礼物打赏、连麦PK，多种互动方式让直播更有趣'),
          _buildFeatureCard(icon: Icons.people, iconColor: Colors.green, title: '多人连麦', description: '支持多人在线连麦，语音视频畅聊，打破距离限制'),
          _buildFeatureCard(icon: Icons.videocam, iconColor: Colors.purple, title: '美颜滤镜', description: '智能美颜、趣味滤镜、动态贴纸，让你随时随地美美出镜'),
          const SizedBox(height: 24),
          // 特色服务
          _buildSectionTitle('特色服务'),
          const SizedBox(height: 16),
          _buildFeatureCard(icon: Icons.security, iconColor: Colors.orange, title: '安全直播', description: '实名认证、内容审核、隐私保护，打造绿色健康的直播环境'),
          _buildFeatureCard(icon: Icons.monetization_on, iconColor: Colors.amber, title: '收益管理', description: '礼物收益、打赏分成、提现便捷，让直播创造价值'),
          _buildFeatureCard(icon: Icons.analytics, iconColor: Colors.teal, title: '数据分析', description: '直播数据、粉丝画像、收益报表，助力主播精细化运营'),
          const SizedBox(height: 32),
          // 底部提示
          Center(
            child: Text('更多功能，敬请期待', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(color: const Color(0xFF1976D2), borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({required IconData icon, required Color iconColor, required String title, required String description}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                ),
                const SizedBox(height: 6),
                Text(description, style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
