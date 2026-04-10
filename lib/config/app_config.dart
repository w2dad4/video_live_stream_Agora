//应用配置管理类
import 'package:flutter/material.dart';

/// 应用通用配置类
/// 统一管理应用Logo、名称、版本等全局信息
class AppConfig {
  // 私有构造函数，防止实例化
  AppConfig._();

  // ========== 应用基本信息 ==========
  static const String appName = '小猫啵啵';
  static const String appNameEn = 'XiaoMao BoBo';
  static const String currentVersion = '1.0.0';

  // ========== Logo 资源路径 ==========
  static const String logoPath = 'assets/icon/Logo.jpg';

  // ========== 品牌信息 ==========
  static const String brandSlogan = '开启你的直播之旅';
  static const String companyName = '小猫啵啵科技有限公司';

  // ========== 联系方式 ==========
  static const String supportEmail = 'support@xiaomaobobo.com';
  static const String businessEmail = 'business@xiaomaobobo.com';
  static const String techEmail = 'tech@xiaomaobobo.com';
  static const String customerServicePhone = '400-123-4567';

  // ========== 社交媒体 ==========
  static const String weibo = '@小猫啵啵直播';
  static const String wechat = '小猫啵啵';
  static const String douyin = '小猫啵啵官方';

  // ========== 版本更新信息 ==========
  static const String latestVersion = '1.2.0';
  static const String updateContent = '''• 优化直播间高并发加载速度
• 适配硬件解码优化
• 新增小猫啵啵专属互动表情''';

  // ========== 辅助方法 ==========

  /// 获取带Logo的圆形图片Widget
  static Widget getCircleLogo({double size = 80}) {
    return ClipOval(
      child: Image.asset(
        logoPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }

  /// 获取带Logo的圆角图片Widget
  static Widget getRoundedLogo({double size = 80, double borderRadius = 16}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        logoPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }

  /// 获取渐变背景的Logo容器
  static Widget getGradientLogoContainer({
    double size = 100,
    double borderRadius = 24,
    List<Color> gradientColors = const [Color(0xFF64B5F6), Color(0xFF1976D2)],
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          logoPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
