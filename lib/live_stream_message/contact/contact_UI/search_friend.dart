import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/friend_request_provider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/search_provider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_UI/qr_flutter.dart';

class AddFriendPage extends ConsumerWidget {
  const AddFriendPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuItems = ref.watch(addFriendMenuProvider);
    final me = ref.watch(meProvider);
    final myCatId = me?.uid?.trim().isNotEmpty == true ? me!.uid!.trim() : 'me';
    final hit = ref.watch(searchCatAccountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('添加朋友'),
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed('VideoMessage');
            }
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _SearchBar(),
            if (hit != null) _SearchHitCard(hit: hit),
            Expanded(
              child: ListView.separated(
                itemCount: menuItems.length,
                separatorBuilder: (context, index) => const Divider(height: 0.5, indent: 60),
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return ListTile(
                    leading: Icon(item.icon, color: Colors.blueAccent),
                    title: Text(item.title),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 15, color: Colors.grey),
                    onTap: () => _onMenuTap(context, item.action),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(
                  children: [
                    Text('我的小猫号：$myCatId', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 10),
                    const QrGeneratorPage(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onMenuTap(BuildContext context, AddFriendMenuAction action) {
    switch (action) {
      case AddFriendMenuAction.scan:
        context.pushNamed('ScanQr');
        break;
      case AddFriendMenuAction.newGroup:
        context.pushNamed('NewGroupChat');
        break;
      case AddFriendMenuAction.faceToFace:
        context.pushNamed('FaceToFaceGroup');
        break;
      case AddFriendMenuAction.newFriends:
        context.pushNamed('NewFriends');
        break;
    }
  }
}

class _SearchBar extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  final TextEditingController _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10, top: 8),
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: const Color.fromARGB(255, 227, 225, 225),
      ),
      child: TextField(
        controller: _c,
        textAlignVertical: TextAlignVertical.center,
        onChanged: (v) => ref.read(searchKeywordProvider.notifier).state = v,
        decoration: const InputDecoration(
          isDense: true,
          hintText: '搜索小猫号 / 昵称',
          prefixIcon: Icon(Icons.search, size: 30),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _SearchHitCard extends ConsumerWidget {
  const _SearchHitCard({required this.hit});

  final ContactModelLite hit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(backgroundImage: AssetImage(hit.avatar)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hit.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('猫猫号：${hit.id}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            FilledButton(
              onPressed: () async {
                final err = await ref.read(friendRequestListProvider.notifier).sendRequestToCatId(
                      targetCatId: hit.id,
                      targetName: hit.title,
                      targetAvatar: hit.avatar,
                    );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err ?? '已发送申请，对方同意后成为好友')),
                );
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }
}
