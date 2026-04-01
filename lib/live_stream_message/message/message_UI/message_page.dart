import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/tool/dataTime.dart';

//UI页面
class MessagePage extends ConsumerWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contens = ref.watch(conversationProvider); // 监听消息会话列表
    return ListView.separated(
      separatorBuilder: (context, index) => const Divider(height: 0.5, indent: 70, color: Color.fromARGB(255, 210, 209, 209)),
      itemCount: contens.length,
      itemBuilder: (context, index) {
        final item = contens[index];
        return _buildMessageTile(item, context);
      },
    );
  }

  Widget _buildMessageTile(ChatConversation item, BuildContext context) {
    return ListTile(
      //图片
      leading: SizedBox(
        width: 50,
        height: 50,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10), //
          child: _buildAvatar(item.avatar),
        ),
      ),

      //标题
      title: Text(item.title, style: const TextStyle(fontSize: 15, color: Colors.black)),
      // 副标题：动态接收的最新消息内容
      subtitle: Text(item.lastMessage, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      //右侧，显示时间
      trailing: Text(item.createdAt.toCanvaerstionTime(), style: const TextStyle(fontSize: 13, color: Colors.grey)),
      //跳转页面
      onTap: () {
        context.pushNamed('chat', pathParameters: {'chatId': item.id.toString()});
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
        errorBuilder: (_, error, stackTrace) => Image.asset('assets/image/002.png', fit: BoxFit.cover),
      );
    }
    if (url.startsWith('/')) {
      return Image.file(
        File(url),
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => Image.asset('assets/image/002.png', fit: BoxFit.cover),
      );
    }
    return Image.asset(
      url.isEmpty ? 'assets/image/002.png' : url,
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      errorBuilder: (_, error, stackTrace) => Image.asset('assets/image/002.png', fit: BoxFit.cover),
    );
  }
}
