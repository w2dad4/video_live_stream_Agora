//数据层
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final searchProvider = StateProvider<String>((ref) => '');
final addFriendMenuPrvider = Provider<List<Map<String, dynamic>>>((ref) {
  return [
    {'icon': Icons.crop_free, 'title': '扫一扫', 'action': 'scan'},
    {'icon': Icons.group_add, 'title': '新建群聊', 'action': 'group'},
    {'icon': Icons.groups, 'title': '面对面建群', 'action': 'face_to_face'},
  ];
});
