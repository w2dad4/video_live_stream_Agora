import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_model.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_provider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/group_chat_provider.dart';

class GroupMembersPage extends ConsumerWidget {
  final String groupId;
  const GroupMembersPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupDetailProvider(groupId));
    final me = ref.watch(meProvider);
    final myId = me?.uid?.trim().isNotEmpty == true ? me!.uid!.trim() : 'self';
    final contacts =
        ref.watch(contactListProvider).value ?? const <ContactModel>[];

    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('群成员')),
        body: const Center(child: Text('群信息不存在')),
      );
    }

    final contactMap = {for (final c in contacts) c.id: c};
    final rows = group.memberIds;

    return Scaffold(
      appBar: AppBar(title: Text('群成员(${group.memberCount})')),
      body: ListView.separated(
        itemCount: rows.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final uid = rows[index];
          final contact = contactMap[uid];
          final nickname = group.profileOf(uid).nickname;
          final name = nickname.isNotEmpty
              ? nickname
              : (contact?.title ?? (uid == myId ? (me?.name ?? '我') : '用户$uid'));
          final role = group.isOwner(uid)
              ? '群主'
              : (group.isAdmin(uid) ? '管理员' : '成员');
          final canManage = group.isOwner(myId) && uid != group.ownerId;
          final isAdmin = group.isAdmin(uid);
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: _buildAvatar(contact?.iconUrl ?? ''),
            ),
            title: Text(name),
            subtitle: Text('角色：$role'),
            trailing: canManage
                ? PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value != 'toggle_admin') return;
                      final ok = await ref
                          .read(groupChatListProvider.notifier)
                          .toggleAdmin(groupId, uid);
                      if (!context.mounted) return;
                      if (!ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('管理员最多只能设置 3 个')),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'toggle_admin',
                        child: Text(isAdmin ? '取消管理员' : '设为管理员'),
                      ),
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildAvatar(String url) {
    if (url.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        color: Colors.grey[300],
        child: const Icon(Icons.person, color: Colors.white),
      );
    }
    if (url.startsWith('http')) {
      return Image.network(url, width: 40, height: 40, fit: BoxFit.cover);
    }
    if (url.startsWith('/')) {
      return Image.file(File(url), width: 40, height: 40, fit: BoxFit.cover);
    }
    return Image.asset(url, width: 40, height: 40, fit: BoxFit.cover);
  }
}
