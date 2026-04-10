import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/friend_request_provider.dart';

/// 新的朋友：处理「需对方同意」的好友申请
class NewFriendsPage extends ConsumerWidget {
  const NewFriendsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incoming = ref.watch(incomingFriendRequestsProvider);
    final async = ref.watch(friendRequestListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('新的朋友'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('$e')),
        data: (_) {
          if (incoming.isEmpty) {
            return const Center(
              child: Text('暂无新的好友申请', style: TextStyle(color: Colors.grey)),
            );
          }
          return ListView.separated(
            itemCount: incoming.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = incoming[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: r.fromAvatar.startsWith('assets/')
                      ? AssetImage(r.fromAvatar) as ImageProvider
                      : NetworkImage(r.fromAvatar),
                ),
                title: Text(r.fromName),
                subtitle: Text('猫猫号：${r.fromUserId}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () => ref.read(friendRequestListProvider.notifier).reject(r.id),
                      child: const Text('拒绝'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => ref.read(friendRequestListProvider.notifier).accept(r.id),
                      child: const Text('同意'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
