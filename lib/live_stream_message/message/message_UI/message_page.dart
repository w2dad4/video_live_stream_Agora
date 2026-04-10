import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/live_stream_message/message/message_Data/chat_Model.dart';
import 'package:video_live_stream/live_stream_message/message/message_Data/delete_message.dart';
import 'package:video_live_stream/live_stream_message/message/message_Data/message_Model.dart';

//UI页面
class MessagePage extends ConsumerWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contens = ref.watch(messageModelProvider); // 监听消息会话列表
    return ListView.separated(
      separatorBuilder: (context, index) => const Divider(
        height: 0.5,
        indent: 70,
        color: Color.fromARGB(255, 210, 209, 209),
      ),
      itemCount: contens.length,
      itemBuilder: (context, index) {
        final item = contens[index];
        return SlidableTile(
          item: item,
          onDelete: () => ref
              .read(messageModelProvider.notifier)
              .deleteConversation(item.id), //
          child: _buildMessageTile(item, context, ref),
        );
      },
    );
  }

  Widget _buildMessageTile(
    ChatConversation item,
    BuildContext context,
    WidgetRef ref,
  ) {
    final detail = ref.watch(chatDetailProvider(item.id));
    final isGroup = detail?.tag == '群聊' || item.id.startsWith('group_');
    return ListTile(
      //图片
      leading: SizedBox(
        width: 50,
        height: 50,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10), //
          child: GestureDetector(
            onDoubleTap: () {},
            onTap: () {
              if (isGroup) {
                context.pushNamed(
                  'GroupInfo',
                  pathParameters: {'groupId': item.id},
                );
              } else {
                context.pushNamed(
                  'Details',
                  pathParameters: {'detailsId': item.id},
                  extra: {
                    'title': item.title,
                    'avatar': item.avatar,
                    'bgUrl': item.bgUrl,
                  },
                );
              }
            },
            child: _buildAvatar(item.avatar),
          ),
        ),
      ),

      //标题
      title: Text(
        item.title,
        style: const TextStyle(fontSize: 15, color: Colors.black),
      ),
      // 副标题：动态接收的最新消息内容
      subtitle: Text(
        item.lastMessage,
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      ),
      //右侧，显示时间
      trailing: Text(
        _formatConversationTime(item.createdAt),
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      ),
      //跳转页面
      onLongPress: () {
        if (isGroup) {
          context.pushNamed('GroupInfo', pathParameters: {'groupId': item.id});
        } else {
          context.pushNamed(
            'Details',
            pathParameters: {'detailsId': item.id},
            extra: {
              'title': item.title,
              'avatar': item.avatar,
              'bgUrl': item.bgUrl,
            },
          );
        }
      },
      onTap: () {
        context.pushNamed('chat', pathParameters: {'chatId': item.id});
      },
    );
  }

  Widget _buildAvatar(String url) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) =>
            Image.asset('assets/image/002.png', fit: BoxFit.cover),
      );
    }
    if (url.startsWith('/')) {
      return Image.file(
        File(url),
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) =>
            Image.asset('assets/image/002.png', fit: BoxFit.cover),
      );
    }
    return Image.asset(
      url.isEmpty ? 'assets/image/002.png' : url,
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      errorBuilder: (_, error, stackTrace) =>
          Image.asset('assets/image/002.png', fit: BoxFit.cover),
    );
  }

  String _formatConversationTime(DateTime value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final current = DateTime(value.year, value.month, value.day);

    String hhmm(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    if (current == today) return hhmm(value);
    if (current == yesterday) return '昨天${hhmm(value)}';
    if (value.year == now.year) return '${value.month}月${value.day}日';
    return '${value.year}年${value.month}月${value.day}日';
  }
}
