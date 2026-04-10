import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_model.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/group_chat_provider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_provider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_repository.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/social_local_storage.dart';

/// 面对面建群：输入相同 6 位数字进入同一群（本地演示）
class FaceToFaceGroupPage extends ConsumerStatefulWidget {
  const FaceToFaceGroupPage({super.key});

  @override
  ConsumerState<FaceToFaceGroupPage> createState() =>
      _FaceToFaceGroupPageState();
}

class _FaceToFaceGroupPageState extends ConsumerState<FaceToFaceGroupPage> {
  final TextEditingController _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _joinOrCreate() async {
    final digits = _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(digits)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入 6 位数字')));
      return;
    }
    final me = ref.read(meProvider);
    final myId = me.uid?.trim().isNotEmpty == true ? me.uid!.trim() : 'self';
    var groupId = await SocialLocalStorage.getFaceToFaceGroupId(digits);
    if (groupId == null || groupId.isEmpty) {
      groupId = 'group_f2f_$digits';
      await SocialLocalStorage.setFaceToFaceRoom(digits, groupId);
      final group = ContactModel(
        id: groupId,
        title: '面对面群 $digits',
        iconUrl: 'assets/image/007.jpeg',
        bgUrl: 'assets/image/006.png',
        tag: '群聊',
      );
      await ref.read(contactModelProvider).addContact(group);
      await ref
          .read(groupChatListProvider.notifier)
          .ensureGroupForContact(group, ownerId: myId, memberIds: [myId]);
    } else {
      final contacts = await ref.read(contactModelProvider).getContact();
      late final ContactModel targetGroup;
      if (!contacts.any((c) => c.id == groupId)) {
        final group = ContactModel(
          id: groupId,
          title: '面对面群 $digits',
          iconUrl: 'assets/image/007.jpeg',
          bgUrl: 'assets/image/006.png',
          tag: '群聊',
        );
        await ref.read(contactModelProvider).addContact(group);
        targetGroup = group;
      } else {
        targetGroup = contacts.firstWhere((c) => c.id == groupId);
      }
      await ref
          .read(groupChatListProvider.notifier)
          .ensureGroupForContact(targetGroup, ownerId: myId, memberIds: [myId]);
    }
    ref.invalidate(contactListProvider);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已进入面对面群 $digits')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('面对面建群'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '与身边朋友输入相同的 6 位数字，即可进入同一个群（本地演示，无服务端校验）。',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, letterSpacing: 8),
              decoration: const InputDecoration(
                hintText: '000000',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _joinOrCreate, child: const Text('进入群聊')),
          ],
        ),
      ),
    );
  }
}
