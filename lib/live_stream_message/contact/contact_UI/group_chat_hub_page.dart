import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_model.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_provider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/group_chat_provider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/group_read_provider.dart';
import 'package:video_live_stream/live_stream_message/message/message_Data/chat_Model.dart';
import 'package:video_live_stream/live_stream_message/message/message_Data/message_Model.dart';

/// 群聊总入口页：支持搜索、未读显示、最近活跃置顶
class GroupChatHubPage extends ConsumerStatefulWidget {
  const GroupChatHubPage({super.key});

  @override
  ConsumerState<GroupChatHubPage> createState() => _GroupChatHubPageState();
}

class _GroupChatHubPageState extends ConsumerState<GroupChatHubPage> {
  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider);
    final myId = me?.uid?.trim().isNotEmpty == true ? me!.uid!.trim() : 'self';
    final contacts =
        ref.watch(contactListProvider).value ?? const <ContactModel>[];
    final groups = ref.watch(groupChatListProvider).value ?? const [];
    final conversations = ref.watch(messageModelProvider);
    final readMap =
        ref.watch(groupReadProvider).value ?? const <String, DateTime>{};

    // 优先用群元数据判断「我加入的群」
    final idsFromMeta = groups
        .where((g) => g.memberIds.contains(myId))
        .map((e) => e.id)
        .toSet();
    final fromMeta = contacts.where((c) => idsFromMeta.contains(c.id)).toList();

    // 兜底：如果本地元数据还未建立，则按联系人中的群聊展示
    final raw = fromMeta.isNotEmpty
        ? fromMeta
        : contacts.where((c) => c.tag == '群聊').toList();

    // 最近活跃置顶：按会话最后活跃时间降序
    final convMap = {for (final conv in conversations) conv.id: conv};
    final sorted = [...raw]
      ..sort((a, b) {
        final aAt =
            convMap[a.id]?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bAt =
            convMap[b.id]?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bAt.compareTo(aAt);
      });

    // 搜索：支持按群名或群号过滤
    final list = _keyword.trim().isEmpty
        ? sorted
        : sorted.where((c) {
            final q = _keyword.trim();
            return c.title.contains(q) || c.id.contains(q);
          }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('我的群聊')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _keyword = value),
              decoration: InputDecoration(
                hintText: '搜索群聊',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _keyword.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _keyword = '');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('没有匹配的群聊'))
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 68),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      final messages =
                          ref.watch(messageProvider(item.id)).value ??
                          const <MessageModel>[];
                      final readAt = readMap[item.id];
                      final unread = messages
                          .where((m) => !m.isMe)
                          .where(
                            (m) =>
                                readAt == null || m.timestamp.isAfter(readAt),
                          )
                          .length;

                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildAvatar(item.iconUrl),
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(item.title)),
                            if (index == 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xffE6F0FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '最近活跃',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xff2B6CB0),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text('群号: ${item.id}'),
                        trailing: unread > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$unread',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : null,
                        onTap: () async {
                          // 进入群聊前先标记已读，保证入口未读计数同步下降
                          await ref
                              .read(groupReadProvider.notifier)
                              .markGroupAsRead(item.id);
                          if (!context.mounted) return;
                          context.pushNamed(
                            'chat',
                            pathParameters: {'chatId': item.id},
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String url) {
    if (url.isEmpty) {
      return Container(
        width: 45,
        height: 45,
        color: Colors.grey[300],
        child: const Icon(Icons.groups, color: Colors.white),
      );
    }
    if (url.startsWith('http')) {
      return Image.network(url, width: 45, height: 45, fit: BoxFit.cover);
    }
    if (url.startsWith('/')) {
      return Image.file(File(url), width: 45, height: 45, fit: BoxFit.cover);
    }
    return Image.asset(url, width: 45, height: 45, fit: BoxFit.cover);
  }
}
