import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_model.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/group_chat_provider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_provider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/group_read_provider.dart';
import 'package:video_live_stream/live_stream_message/message/message_Data/chat_Model.dart';

class ContactPage extends ConsumerWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用 Riverpod 监听数据，实现响应式 UI
    final contactAsync = ref.watch(contactListProvider);
    final double topPadding = MediaQuery.of(context).padding.top;
    return contactAsync.when(
      data: (contacs) {
        // 统计群聊入口：只计算「我加入的群」
        final me = ref.watch(meProvider);
        final myId = me.uid?.trim().isNotEmpty == true
            ? me.uid!.trim()
            : 'self';
        final groupMetas = ref.watch(groupChatListProvider).value ?? const [];
        final joinedGroupIds = groupMetas
            .where((g) => g.memberIds.contains(myId))
            .map((e) => e.id)
            .toSet();
        final allGroups = contacs.where((c) => c.tag == '群聊').toList();
        final groups = joinedGroupIds.isNotEmpty
            ? allGroups.where((c) => joinedGroupIds.contains(c.id)).toList()
            : allGroups;
        final friends = contacs.where((c) => c.tag != '群聊').toList();
        final groupCount = groups.length;
        final readMap =
            ref.watch(groupReadProvider).value ?? const <String, DateTime>{};
        int totalUnread = 0;
        for (final g in groups) {
          final messages = ref.watch(messageProvider(g.id)).value ?? const [];
          final readAt = readMap[g.id];
          final unread = messages
              .where((m) => !m.isMe)
              .where((m) => readAt == null || m.timestamp.isAfter(readAt))
              .length;
          totalUnread += unread;
        }
        return CustomScrollView(
          slivers: [
            //顶部添加好友的icon
            _buildTopHeader(context, topPadding),
            SliverToBoxAdapter(
              child: ListTile(
                // 点击后进入「我加入的群聊」列表页，再次点击群聊再进聊天页
                onTap: () => context.pushNamed('GroupChatHub'),
                leading: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xffE7F1FF),
                  ),
                  child: const Icon(Icons.groups, color: Color(0xff2B6CB0)),
                ),
                title: const Text('群聊', style: TextStyle(fontSize: 16)),
                subtitle: Text('共 $groupCount 个群聊'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (totalUnread > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$totalUnread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return _ContactTile(item: friends[index]);
              }, childCount: friends.length),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
      error: (err, stack) => const Center(child: Text('数据加载失败')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildTopHeader(BuildContext context, double topPadding) {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        height: topPadding + 30,
        color: Colors.white,
        padding: EdgeInsets.only(top: topPadding, right: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () {
                context.pushNamed('AddFriend');
              },
              child: Icon(Icons.person_add_alt_1, size: 27),
            ),
          ],
        ),
      ),
    );
  }
}

// 联系人行：群聊入口统一在顶部，这里只展示好友（包含自己的账号）
class _ContactTile extends StatelessWidget {
  final ContactModel item;
  const _ContactTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        if (item.id.isEmpty) return;
        context.pushNamed(
          'Details',
          pathParameters: {'detailsId': item.id},
          extra: {
            'title': item.title,
            'avatar': item.iconUrl,
            'bgUrl': item.bgUrl,
          },
        );
      },
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildAvatar(item.iconUrl),
      ),
      title: Text(item.title, style: const TextStyle(fontSize: 16)),
      subtitle: Transform.translate(
        offset: const Offset(0, 10),
        child: const Divider(height: 1, thickness: 0.5),
      ),
    );
  }

  Widget _buildAvatar(String url) {
    if (url.isEmpty) {
      return Container(
        width: 45,
        height: 45,
        color: Colors.grey[200],
        child: const Icon(Icons.person, color: Colors.grey),
      );
    }
    if (url.startsWith('http')) {
      return Image.network(url, width: 45, height: 45, fit: BoxFit.cover);
    }
    if (url.startsWith('assets/')) {
      return Image.asset(url, width: 45, height: 45, fit: BoxFit.cover);
    }
    return Image.file(File(url), width: 45, height: 45, fit: BoxFit.cover);
  }
}
