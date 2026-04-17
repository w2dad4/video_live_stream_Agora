// ignore_for_file: dead_code

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 直播结束页面 - 显示主播信息和结束状态
class Conclude extends StatelessWidget {
  final String hostName;
  final String? hostAvatar;
  final String roomId;

  const Conclude({super.key, required this.hostName, this.hostAvatar, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部关闭按钮
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),

            // 主要内容区域
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 主播头像
                  _buildAvatar(),
                  const SizedBox(height: 20),

                  // 主播昵称
                  Text(
                    hostName,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // 直播结束标签
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20)),
                    child: const Text('本场直播已结束', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ),
                  const SizedBox(height: 40),

                  // 关注按钮
                  _buildFollowButton(context),
                  const SizedBox(height: 20),

                  // 返回首页按钮
                  TextButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.home, color: Colors.white70),
                    label: const Text('去看看其他直播', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建主播头像
  Widget _buildAvatar() {
    final avatarUrl = hostAvatar;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.pink.withValues(alpha: 0.5), width: 3),
        boxShadow: [BoxShadow(color: Colors.pink.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 2)],
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl.isNotEmpty ? Image.network(avatarUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar()) : _buildDefaultAvatar(),
      ),
    );
  }

  /// 默认头像
  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey.shade700,
      child: const Icon(Icons.person, size: 50, color: Colors.white),
    );
  }

  /// 构建关注按钮（示例UI，可接入真实关注逻辑）
  Widget _buildFollowButton(BuildContext context) {
    final isFollowing = false; // 示例状态

    // 根据关注状态设置UI属性
    final String buttonText = isFollowing ? '已关注' : '关注';
    final IconData buttonIcon = isFollowing ? Icons.check : Icons.add;
    final Color buttonColor = isFollowing ? Colors.grey : Colors.pink;
    final String snackText = isFollowing ? '已取消关注' : '已关注 $hostName';

    return ElevatedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snackText), duration: const Duration(seconds: 2)));
      },
      icon: Icon(buttonIcon, size: 18),
      label: Text(buttonText),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
