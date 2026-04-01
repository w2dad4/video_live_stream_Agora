//用于主播警言用户等等
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_live_stream/start_video/room_manager_logic.dart';


class ShowMuteManagement extends ConsumerWidget {
  const ShowMuteManagement({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听全局禁言名单
    final mutedUsers = ref.watch(mutedUsersProvider);
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          // 顶部装饰条
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: Colors.white),
            margin: const EdgeInsets.only(bottom: 10),
            width: 40,
            height: 5,
          ),
          const Text('警言名单管理', style: TextStyle(color: Colors.grey)),
          const Divider(),
          if (mutedUsers.isEmpty)
            const Expanded(
              child: Center(
                child: Text('当前没有被禁言的用户', style: TextStyle(color: Colors.redAccent)),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: mutedUsers.length,
                itemBuilder: (context, index) {
                  final uid = mutedUsers.elementAt(index);
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text("用户 ID: $uid"),
                    trailing: ElevatedButton(
                      onPressed: () {
                        ref.read(mutedUsersProvider.notifier).update((state) {
                          return {...state}..remove(uid);
                        });
                      },
                      child: const Text('解除'),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
