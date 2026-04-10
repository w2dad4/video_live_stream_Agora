// 添加好友：搜索关键词、菜单项、可搜索的猫猫号目录（演示用，可接后端替换）
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// 顶部搜索框绑定
final searchKeywordProvider = StateProvider<String>((ref) => '');

/// 菜单动作（与 [addFriendMenuProvider] 对应）
enum AddFriendMenuAction { scan, newGroup, faceToFace, newFriends }

class AddFriendMenuItem {
  const AddFriendMenuItem({required this.icon, required this.title, required this.action});

  final IconData icon;
  final String title;
  final AddFriendMenuAction action;
}

final addFriendMenuProvider = Provider<List<AddFriendMenuItem>>((ref) {
  return const [
    AddFriendMenuItem(icon: Icons.crop_free, title: '扫一扫', action: AddFriendMenuAction.scan),
    AddFriendMenuItem(icon: Icons.group_add, title: '新建群聊', action: AddFriendMenuAction.newGroup), //
    AddFriendMenuItem(icon: Icons.groups, title: '面对面建群', action: AddFriendMenuAction.faceToFace),
    AddFriendMenuItem(icon: Icons.person_add_alt_1, title: '新的朋友', action: AddFriendMenuAction.newFriends),
  ];
});

/// 兼容旧拼写（若仍有引用可逐步删掉）
final addFriendMenuPrvider = addFriendMenuProvider;

/// 平台内置可搜索的猫猫号（真实环境改为接口查询）
final catAccountDirectoryProvider = Provider<Map<String, ContactModelLite>>((ref) {
  return {
    'cat_tom': const ContactModelLite(id: 'cat_tom', title: '汤姆猫', avatar: 'assets/image/004.jpeg'),
    'cat_jerry': const ContactModelLite(id: 'cat_jerry', title: '杰瑞鼠好友', avatar: 'assets/image/005.jpeg'),
    'cat_888': const ContactModelLite(
      //
      id: 'cat_888',
      title: '测试号888',
      avatar: 'assets/image/006.png',
    ),
  };
});

/// 轻量展示用（避免循环依赖 contact_model）
class ContactModelLite {
  const ContactModelLite({required this.id, required this.title, required this.avatar});

  final String id;
  final String title;
  final String avatar;
}

/// 按输入查找猫猫号：精确 id 或昵称包含
final searchCatAccountProvider = Provider<ContactModelLite?>((ref) {
  final q = ref.watch(searchKeywordProvider).trim();
  if (q.isEmpty) return null;
  final dir = ref.watch(catAccountDirectoryProvider); //
  if (dir.containsKey(q)) return dir[q];
  for (final e in dir.entries) {
    if (e.key.contains(q) || e.value.title.contains(q)) {
      return e.value;
    }
  }
  return null;
});
