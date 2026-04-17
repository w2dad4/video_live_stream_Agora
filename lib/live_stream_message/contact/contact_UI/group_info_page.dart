import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/group_chat_provider.dart';
import 'package:video_live_stream/live_stream_message/message/message_Data/chat_Model.dart';

class GroupInfoPage extends ConsumerStatefulWidget {
  final String groupId;
  const GroupInfoPage({super.key, required this.groupId});

  @override
  ConsumerState<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends ConsumerState<GroupInfoPage> {
  bool _ensuredOnce = false;

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(groupDetailProvider(widget.groupId));
    final contact = ref.watch(chatDetailProvider(widget.groupId));
    final me = ref.watch(meProvider);
    final myId = me?.uid?.trim().isNotEmpty == true ? me!.uid!.trim() : 'self';

    if (group == null) {
      if (!_ensuredOnce && contact != null && contact.tag == '群聊') {
        _ensuredOnce = true;
        Future.microtask(() async {
          await ref.read(groupChatListProvider.notifier).ensureGroupForContact(contact, ownerId: myId, memberIds: [myId]);
        });
      }
      return Scaffold(
        appBar: AppBar(title: const Text('群聊信息')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final profile = group.profileOf(myId);
    final canEditName = group.canEditName(myId);
    final canEditNotice = group.canEditAnnouncement(myId);

    return Scaffold(
      appBar: AppBar(title: const Text('群聊信息')),
      body: ListView(
        children: [
          _tile(
            title: '群成员(${group.memberCount})',
            value: '查看全部成员',
            onTap: () {
              context.pushNamed('GroupMembers', pathParameters: {'groupId': widget.groupId});
            },
          ),
          const Divider(height: 1),
          _tile(
            title: '群名称',
            value: group.groupName,
            onTap: canEditName
                ? () => _editText(
                    context,
                    title: '修改群名称',
                    initial: group.groupName,
                    onConfirm: (value) async {
                      final ok = await ref.read(groupChatListProvider.notifier).renameGroup(widget.groupId, value);
                      if (!context.mounted) return;
                      if (!ok) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('仅群主和管理员可修改群名称')));
                      }
                    },
                  )
                : null,
          ),
          const Divider(height: 1),
          _tile(
            title: '群备注（仅自己可见）',
            value: profile.remark.isEmpty ? '未设置' : profile.remark,
            onTap: () => _editText(
              context,
              title: '设置群备注',
              initial: profile.remark,
              onConfirm: (value) async {
                await ref.read(groupChatListProvider.notifier).updateMyRemark(widget.groupId, value);
              },
            ),
          ),
          const Divider(height: 1),
          _tile(
            title: '群公告',
            value: group.announcement.isEmpty ? '暂无公告' : group.announcement,
            onTap: canEditNotice
                ? () => _editText(
                    context,
                    title: '修改群公告',
                    initial: group.announcement,
                    onConfirm: (value) async {
                      await ref.read(groupChatListProvider.notifier).updateAnnouncement(widget.groupId, value);
                    },
                  )
                : null,
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('消息免打扰'),
            value: profile.mute,
            onChanged: (value) async {
              await ref.read(groupChatListProvider.notifier).updateMyMute(widget.groupId, value);
            },
          ),
          const Divider(height: 1),
          _tile(
            title: '我在本群的昵称',
            value: profile.nickname.isEmpty ? '未设置' : profile.nickname,
            onTap: () => _editText(
              context,
              title: '设置本群昵称',
              initial: profile.nickname,
              onConfirm: (value) async {
                await ref.read(groupChatListProvider.notifier).updateMyNickname(widget.groupId, value);
              },
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            title: const Center(
              child: Text('删除聊天记录', style: TextStyle(color: Colors.blue, fontSize: 16)),
            ),
            onTap: () => _confirmDeleteLocalMessages(context),
          ),
          Container(
            child: ListTile(
              title: const Center(
                child: Text('退出群聊', style: TextStyle(color: Colors.red, fontSize: 16)),
              ),
              onTap: () => _showExitBottomSheet(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile({required String title, required String value, VoidCallback? onTap}) {
    return ListTile(
      title: Text(title),
      subtitle: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Future<void> _editText(BuildContext context, {required String title, required String initial, required Future<void> Function(String value) onConfirm}) async {
    final controller = TextEditingController(text: initial);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              await onConfirm(controller.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteLocalMessages(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除聊天记录'),
        content: const Text('确定删除本地聊天记录'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              await ref.read(groupChatListProvider.notifier).clearLocalChatRecords(widget.groupId);
              await ref.read(messageProvider(widget.groupId).notifier).clearLocalMessages();
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('本地聊天记录已删除')));
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _showExitBottomSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('您将要退出群聊，退出群聊只有群管理员与群主可见。', style: TextStyle(fontSize: 15)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(onPressed: () => Navigator.pop(sheetContext), child: const Text('取消')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        await ref.read(groupChatListProvider.notifier).exitAndReleaseGroup(widget.groupId);
                        if (!sheetContext.mounted) return;
                        Navigator.pop(sheetContext);
                        if (context.mounted) {
                          context.goNamed('VideoMessage');
                        }
                      },
                      child: const Text('退出'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
