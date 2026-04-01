import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

//定义一个枚举 LiveMode 来区分直播类型
enum LiveMode { video, audio }

//family 模式，根据 LiveMode 隔离数据
final liveTitleProvider = StateProvider.family<String, LiveMode>((ref, mode) => '标题');
final positioningProvider = StateProvider.family<String, LiveMode>((ref, mode) => '开启定位');
final visibleProvider = StateProvider.family<String, LiveMode>((ref, mode) => '所有人可见');

class Dialogbox extends ConsumerWidget {
  final LiveMode mode;
  const Dialogbox({super.key, required this.mode});
  // 弹出对话框的静态方法
  static Future<void> show(BuildContext context, LiveMode mode) {
    return showCupertinoDialog(
      context: context,
      builder: (context) => Dialogbox(mode: mode),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTitle = ref.read(liveTitleProvider(mode));
    final controller = TextEditingController(text: currentTitle);
    return CupertinoAlertDialog(
      title: Text('修改直播标题'),
      content: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: CupertinoTextField(
          controller: controller,
          placeholder: '请输入直播标题',
          autocorrect: true,
          style: const TextStyle(color: Colors.black),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            context.pop();
          },
          child: const Text('取消', style: TextStyle(color: Colors.green)),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            ref.read(liveTitleProvider(mode).notifier).state = controller.text;
            context.pop();
          },
          child: const Text('确认', style: TextStyle(color: Colors.green)),
        ),
      ],
    );
  }
}

//开启定位tanch

class SelectionDialogHelper {
  static void showVisibilitySelector(BuildContext context, WidgetRef ref, LiveMode mode) {
    final options = ['开启定位', '关闭定位'];
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text('选择定位开启与否'),
        actions: options.map((option) {
          return CupertinoActionSheetAction(
            onPressed: () {
              ref.read(positioningProvider(mode).notifier).state = option;
              context.pop(context);
            },
            child: Text(option),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(isDestructiveAction: true, onPressed: () => context.pop(), child: const Text('取消')),
      ),
    );
  }
}

//所有人可见

class Visible {
  static void visibleHelper(BuildContext context, WidgetRef ref, LiveMode mode) {
    final options = ['所有人可见', '关注的可见', '私人房间', '不给谁看', '互相关注的人可见'];
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('选择观众是否可见'),
        actions: options.map((options) {
          return CupertinoActionSheetAction(
            onPressed: () {
              ref.read(visibleProvider(mode).notifier).state = options;
              context.pop(context);
            },
            child: Text(options),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(isDestructiveAction: true, onPressed: () => context.pop(), child: Text('取消')),
      ),
    );
  }
}
