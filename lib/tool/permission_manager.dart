//权限管理工具类 - 首页统一请求所有权限
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 权限管理器 - 用于在首页统一请求所有必要权限
class PermissionManager {
  /// 需要请求的所有权限列表
  static final List<Permission> _permissions = [
    Permission.camera,      // 摄像头
    Permission.microphone,  // 麦克风
    Permission.notification,// 通知
    Permission.storage,     // 存储（Android）
    Permission.photos,      // 相册（iOS）
  ];

  /// 检查并请求所有权限，返回权限状态列表
  static Future<List<PermissionStatus>> requestAllPermissions() async {
    List<PermissionStatus> results = [];
    
    for (var permission in _permissions) {
      // 先检查当前状态
      var status = await permission.status;
      
      // 如果是拒绝状态，则请求权限
      if (status.isDenied || status.isRestricted) {
        status = await permission.request();
      }
      
      results.add(status);
    }
    
    return results;
  }

  /// 单独检查位置权限（使用 geolocator）
  static Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  /// 检查特定权限状态
  static Future<PermissionStatus> checkPermission(Permission permission) async {
    return await permission.status;
  }

  /// 打开应用设置页面
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}

/// 权限提示对话框
class PermissionDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;

  const PermissionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('去开启', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('暂不开启', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
            ),
          ],
        ),
      ),
    );
  }
}

/// 首页权限请求弹窗组件
class HomePermissionRequest extends StatefulWidget {
  final Widget child;

  const HomePermissionRequest({super.key, required this.child});

  @override
  State<HomePermissionRequest> createState() => _HomePermissionRequestState();
}

class _HomePermissionRequestState extends State<HomePermissionRequest> {
  bool _hasRequested = false;

  @override
  void initState() {
    super.initState();
    // 延迟请求权限，避免页面加载时立即弹出
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _requestPermissionsSequentially();
      }
    });
  }

  /// 依次请求所有权限，每次显示说明弹窗
  Future<void> _requestPermissionsSequentially() async {
    if (_hasRequested) return;
    _hasRequested = true;

    final permissions = [
      _PermissionItem(
        permission: Permission.camera,
        title: '开启摄像头权限',
        message: '需要摄像头权限才能进行直播和连麦互动',
        icon: Icons.videocam,
        iconColor: Colors.red,
      ),
      _PermissionItem(
        permission: Permission.microphone,
        title: '开启麦克风权限',
        message: '需要麦克风权限才能进行语音直播和聊天',
        icon: Icons.mic,
        iconColor: Colors.blue,
      ),
      // 通知权限特殊处理：根据用户之前的选择决定是否弹出
      // 如果用户之前点击"开启"或"取消"，则不再弹出，可在设置页手动开启
    ];

    for (var item in permissions) {
      // 检查当前权限状态
      var status = await item.permission.status;
      
      // 如果是首次请求（denied），显示说明弹窗
      if (status.isDenied) {
        if (!mounted) return;
        
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => PermissionDialog(
            title: item.title,
            message: item.message,
            icon: item.icon,
            iconColor: item.iconColor,
          ),
        );

        // 用户选择去开启
        if (result == true) {
          status = await item.permission.request();
        }
      }
    }

    // 单独处理通知权限 - 根据用户之前的选择
    await _handleNotificationPermission();

    // 单独请求位置权限
    await PermissionManager.requestLocationPermission();
  }

  /// 处理通知权限 - 根据用户之前的选择决定是否弹出
  Future<void> _handleNotificationPermission() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 检查是否已经做过选择（用户点击过"开启"或"取消"）
    final hasUserChosen = prefs.getBool('notification_permission_chosen') ?? false;
    
    if (hasUserChosen) {
      // 用户已经做过选择，不再弹出提示
      return;
    }

    // 检查通知权限当前状态
    final status = await Permission.notification.status;
    
    // 如果已经授权，直接标记为已选择
    if (status.isGranted) {
      await prefs.setBool('notification_permission_chosen', true);
      return;
    }

    // 首次请求，显示说明弹窗
    if (!mounted) return;
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PermissionDialog(
        title: '开启通知权限',
        message: '开启通知可以及时收到直播间消息和互动提醒，比如消息提醒、主播开播提醒等',
        icon: Icons.notifications,
        iconColor: Colors.orange,
      ),
    );

    // 记录用户已经做过选择（无论点击"开启"还是"取消"）
    await prefs.setBool('notification_permission_chosen', true);

    // 用户选择去开启，请求权限
    if (result == true) {
      await Permission.notification.request();
    }
    // 用户点击取消，暂时不请求，之后可在设置页手动开启
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _PermissionItem {
  final Permission permission;
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;

  _PermissionItem({
    required this.permission,
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
  });
}
