import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_live_stream/live_stream_discover/voice_live_streaming/voicelive_Data/chat_socket_provider.dart';

/// 🎯 通用直播间在线人数显示组件
///
/// 功能特性：
/// ✅ 默认显示 0
/// ✅ 自动建立 WebSocket 连接，实时更新人数
/// ✅ 主播角色不计入人数（host 角色）
/// ✅ 支持自定义样式
/// ✅ 可复用于任何页面
///
/// 使用示例：
/// ```dart
/// // 观众端（默认 viewer 角色）
/// LiveOnlineCountWidget(roomId: 'room_123')
///
/// // 主播端（host 角色，主播不计入人数）
/// LiveOnlineCountWidget(roomId: 'room_123', isHost: true)
///
/// // 自定义样式
/// LiveOnlineCountWidget(
///   roomId: 'room_123',
///   textStyle: TextStyle(fontSize: 14, color: Colors.white),
///   iconSize: 20,
///   iconColor: Colors.yellow,
/// )
/// ```
class LiveOnlineCountWidget extends ConsumerWidget {
  final String roomId;
  final bool isHost;
  final TextStyle? textStyle;
  final double iconSize;
  final Color? iconColor;

  const LiveOnlineCountWidget({super.key, required this.roomId, this.isHost = false, //
  this.textStyle, this.iconSize = 18, this.iconColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🎯 关键：建立 WebSocket 连接（自动通知服务端 "我进来了"）
    // 主播使用 'host' 角色，不计入观众人数；观众使用默认 'viewer' 角色
    if (isHost) {
      ref.watch(chatSocketWithRoleProvider((roomId: roomId, role: 'host')));
    } else {
      ref.watch(chatSocketProvider(roomId));
    }

    // 监听 WebSocket 推送的实时人数
    final onlineCountAsync = isHost
        ? ref.watch(
            chatOnlineCountWithRoleProvider((
              roomId: roomId, //
              role: 'host',
            )),
          )
        : ref.watch(chatOnlineCountProvider(roomId));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          CupertinoIcons.person_2_fill,
          size: iconSize,
          color: iconColor ?? Colors.white, //
        ),
        const SizedBox(width: 4),
        onlineCountAsync.when(
          data: (count) => Text(
            "$count",
            style: textStyle ?? const TextStyle(fontSize: 13, color: Colors.white), //
          ),
          loading: () => SizedBox(
            width: iconSize * 0.6,
            height: iconSize * 0.6,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: (iconColor ?? Colors.white).withValues(alpha: 0.3), //
            ),
          ),
          error: (_, __) => Text("0", style: textStyle ?? const TextStyle(fontSize: 13, color: Colors.white)),
        ),
      ],
    );
  }
}
