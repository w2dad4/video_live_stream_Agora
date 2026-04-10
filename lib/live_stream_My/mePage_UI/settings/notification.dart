import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_live_stream/library.dart';

// 通知设置提供者
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((ref) {
  return NotificationSettingsNotifier();
});

//消息通知
class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  //
  NotificationSettingsNotifier() : super(const NotificationSettings(systemNotifications: true, messageSound: true, streamerLiveReminder: true));

  void updateSystemNotifications(bool value) {
    state = state.copyWith(systemNotifications: value);
  }

  void updateMessageSound(bool value) {
    state = state.copyWith(messageSound: value);
  }

  void updateStreamerLiveReminder(bool value) {
    state = state.copyWith(streamerLiveReminder: value);
  }
}

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationSettings = ref.watch(notificationSettingsProvider); //
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('消息通知'),
        centerTitle: true,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
      ),
      body: ListView(
        children: [
          // 系统消息通知组
          _buildNotificationGroup([
            _buildSwitchItem(
              title: '系统消息通知',
              subtitle: '接收系统重要消息和公告',
              value: notificationSettings.systemNotifications, //
              onChanged: (value) => notifier.updateSystemNotifications(value),
            ),
          ]),

          // 消息提示音组
          _buildNotificationGroup([
            _buildSwitchItem(
              title: '消息提示音',
              subtitle: '新消息到达时播放提示音',
              value: notificationSettings.messageSound, //
              onChanged: (value) => notifier.updateMessageSound(value),
            ),
          ]),

          // 关注主播开播提醒组
          _buildNotificationGroup([
            _buildSwitchItem(
              title: '关注主播开播提醒',
              subtitle: '关注的主播开播时推送通知',
              value: notificationSettings.streamerLiveReminder, //
              onChanged: (value) => notifier.updateStreamerLiveReminder(value), //
            ),
          ]),

          // 系统权限设置
          _buildNotificationGroup([
            SettingsUI.item(
              title: '系统消息通知',
              subtitle: '跳转到系统设置开启通知权限，接收消息提醒和主播开播提醒',
              icon: Icons.settings,
              onTap: () => _openSystemNotificationSettings(context),
            ),
          ]),

          // 其他设置
          _buildNotificationGroup([
            SettingsUI.item(
              title: '通知管理',
              icon: Icons.notifications_active,
              onTap: () {
                _showNotificationManagementDialog(context);
              },
            ),
            SettingsUI.divider(),
            SettingsUI.item(
              title: '免打扰设置',
              icon: Icons.do_not_disturb,
              onTap: () {
                _showDoNotDisturbDialog(context);
              },
            ),
          ]),
        ],
      ),
    );
  }

  // 构建通知组容器
  Widget _buildNotificationGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      child: Column(children: children),
    );
  }

  // 构建开关设置项
  Widget _buildSwitchItem({required String title, String? subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), //
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500, //
                  ),
                ),
                if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF999999)))],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.blue,
            activeTrackColor: Colors.blue.withValues(alpha: 0.3), //
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  /// 打开系统通知设置
  void _openSystemNotificationSettings(BuildContext context) async {
    final status = await Permission.notification.status;
    
    if (status.isGranted) {
      // 已开启，显示提示
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('系统通知已开启'),
          content: const Text('您已开启系统消息通知权限，可以正常接收各类消息提醒。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
    } else {
      // 未开启，提示用户跳转系统设置
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('开启系统通知'),
          content: const Text('系统消息通知权限尚未开启，您将收不到消息提醒、主播开播提醒等重要通知。是否前往系统设置开启？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('暂不'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // 打开应用设置页面
                await openAppSettings();
              },
              child: const Text('去开启'),
            ),
          ],
        ),
      );
    }
  }

  // 显示通知管理对话框
  void _showNotificationManagementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('通知管理'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• 在系统设置中管理应用通知权限'),
            SizedBox(height: 8),
            Text('• 可自定义不同类型的通知样式'), //
            SizedBox(height: 8),
            Text('• 支持通知历史记录查看'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('知道了'))],
      ),
    );
  }

  // 显示免打扰设置对话框
  void _showDoNotDisturbDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('免打扰设置'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• 设置免打扰时间段'),
            SizedBox(height: 8),
            Text('• 重要消息仍可接收'), //
            SizedBox(height: 8),
            Text('• 支持自定义免打扰规则'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('知道了')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); //
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }
}
