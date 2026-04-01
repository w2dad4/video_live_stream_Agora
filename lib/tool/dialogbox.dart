import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

//通用二次对话框
class AppDialogs {
  static Future<void> showconfirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = '确定',
    String cancelText = '取消',
    bool isDestructive = false,
    required VoidCallback onConfirm, //
  }) async {
    return showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(padding: EdgeInsets.only(top: 8), child: Text(content)),
        actions: [
          CupertinoDialogAction(
            child: Text(cancelText, style: const TextStyle(color: Colors.blue)),
            onPressed: () => context.pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: isDestructive,
            child: Text(confirmText),
            onPressed: () {
              context.pop();
              onConfirm();
            },
          ),
        ],
      ),
    );
  }
}

//通用从底部弹出选择框
class AppDialogstate {
  static void showSelectionSheet<T>({
    required BuildContext context,
    required String title,
    String? message,
    required List<T> options,
    required String Function(T) getlabel, //
    required void Function(T) onSelected,
  }) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(title, style: TextStyle(fontSize: 16)),
        message: message != null ? Text(message) : null,
        actions: options.map((T item) {
          return CupertinoActionSheetAction(
            onPressed: () {
              context.pop();
              onSelected(item);
            },
            child: Text(getlabel(item), style: const TextStyle(color: Colors.blueAccent)),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => context.pop(),
          child: const Text('取消', style: TextStyle(color: Colors.redAccent)),
        ),
      ),
    );
  }
}
