import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_model.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/group_chat_provider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_provider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_repository.dart';

/// 新建群聊：多选联系人后写入本地联系人（群会话）
class NewGroupChatPage extends ConsumerStatefulWidget {
  const NewGroupChatPage({super.key});

  @override
  ConsumerState<NewGroupChatPage> createState() => _NewGroupChatPageState();
}

class _NewGroupChatPageState extends ConsumerState<NewGroupChatPage> {
  final Set<String> _selected = {};
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final async = ref.read(contactListProvider);
    final list = async.value;
    if (list == null || _selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择至少一位成员')));
      return;
    }
    final name = _nameController.text.trim().isEmpty
        ? '群聊(${_selected.length + 1})'
        : _nameController.text.trim();
    final groupId = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final group = ContactModel(
      id: groupId,
      title: name,
      iconUrl: 'assets/image/007.jpeg',
      bgUrl: 'assets/image/006.png',
      tag: '群聊',
    );
    final me = ref.read(meProvider);
    final ownerId = me.uid?.trim().isNotEmpty == true ? me.uid!.trim() : 'self';
    final memberIds = <String>{ownerId, ..._selected}.toList();
    await ref.read(contactModelProvider).addContact(group);
    await ref
        .read(groupChatListProvider.notifier)
        .ensureGroupForContact(group, ownerId: ownerId, memberIds: memberIds);
    ref.invalidate(contactListProvider);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已创建：$name')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider);
    final myId = me.uid?.trim() ?? 'self';
    final async = ref.watch(contactListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('新建群聊'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        actions: [TextButton(onPressed: _create, child: const Text('完成'))],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('$e')),
        data: (contacts) {
          final pickable = contacts
              .where((c) => c.id != myId && c.tag != '群聊')
              .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '群名称（可选）',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '选择成员',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: pickable.length,
                  itemBuilder: (context, i) {
                    final c = pickable[i];
                    final checked = _selected.contains(c.id);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selected.add(c.id);
                          } else {
                            _selected.remove(c.id);
                          }
                        });
                      },
                      title: Text(c.title),
                      secondary: CircleAvatar(
                        backgroundImage: AssetImage(c.iconUrl),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
