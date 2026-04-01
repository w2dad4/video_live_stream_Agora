import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/start_video/room_manager_logic.dart';

//创建一个功能完备的 BottomSheet，集成禁言、设为房管、踢人三个功能。
void showUserActionMenu(BuildContext context, WidgetRef ref, String targetUid, String userName) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final isAdmin = ref.watch(roomAdminsProvider).contains(targetUid);
          final isMuted = ref.watch(mutedUsersProvider).contains(targetUid);
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text('管理用户:$userName', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                // 1. 禁言开关
                ListTile(
                  leading: Icon(isMuted ? Icons.volume_up : Icons.volume_off, color: Colors.orange),
                  title: Text(isMuted ? '取消警言' : '确定警言'),
                  onTap: () {
                    ref.read(mutedUsersProvider.notifier).update((s) => isMuted ? ({...s}..remove(targetUid)) : ({...s}..add(targetUid)));
                    context.pop();
                  },
                ),
                //房管开门
                ListTile(
                  leading: Icon(isAdmin ? Icons.person_remove : Icons.person_add, color: Colors.blue),
                  title: Text(isAdmin ? '撤销房管' : '设为房管'),
                  onTap: () {
                    ref.read(roomAdminsProvider.notifier).update((s) => isAdmin ? ({...s}..remove(targetUid)) : ({...s}..add(targetUid)));
                    context.pop();
                  },
                ),
                // 3. 踢人 (直接移出房间)
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: Text('踢出房间', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    ref.read(kickedUsersProvider.notifier).update((s) => {...s, targetUid});
                    context.pop();
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
