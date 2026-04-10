// 通知设置状态模型
class NotificationSettings {
  final bool systemNotifications;
  final bool messageSound;
  final bool streamerLiveReminder;

  const NotificationSettings({required this.systemNotifications, required this.messageSound, required this.streamerLiveReminder});

  NotificationSettings copyWith({bool? systemNotifications, bool? messageSound, bool? streamerLiveReminder}) {
    return NotificationSettings(
      systemNotifications: systemNotifications ?? this.systemNotifications, //
      messageSound: messageSound ?? this.messageSound,
      streamerLiveReminder: streamerLiveReminder ?? this.streamerLiveReminder,
    );
  }
}
