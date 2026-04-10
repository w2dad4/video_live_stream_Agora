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

//通用底部弹窗
class BottomSheetUilt {
  BottomSheetUilt._();
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double? height,
    bool isScrollControlled = true, //
    bool isDismissble = true,
    bool enableDlg = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissble,
      enableDrag: enableDlg,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _buildContainer(context, child, height);
      },
    );
  }

  //这是宽高
  static Widget _buildContainer(BuildContext context, Widget child, double? height) {
    return Container(
      width: double.infinity,
      height: height ?? MediaQuery.of(context).size.height * 0.5,
      color: Colors.white,
      decoration: const BoxDecoration(borderRadius: BorderRadius.vertical(top: Radius.circular(10))),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            //拖拽小横跳
            const SizedBox(height: 5),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

//封装成Settings UI工程类
class SettingsItem {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback onTap;
  final String? trailing;

  SettingsItem({required this.title, required this.onTap, this.subtitle, this.icon, this.trailing});
}

class SettingsUI {
  SettingsUI._();

  /// 🔹 分组容器（灰色块）
  static Widget group(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
        ),
      ),
      child: Column(children: children),
    );
  }

  /// 🔹 单个设置项
  static Widget item({required String title, String? subtitle, IconData? icon, String? trailing, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: subtitle != null ? 64 : 50,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: subtitle != null ? 8 : 0),
        color: Colors.white,
        child: Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 20, color: Colors.grey), const SizedBox(width: 10)],

            /// 标题和副标题
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, color: Color(0xFF333333))),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),

            /// 右侧文字
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(trailing, style: const TextStyle(color: Colors.grey)),
              ),

            /// 箭头
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  /// 🔹 分割线
  static Widget divider({double left = 12}) {
    return Container(
      margin: EdgeInsets.only(left: left),
      height: 0.5,
      color: const Color(0xFFEEEEEE),
    );
  }

  /// 🔹 快速生成一组（推荐用这个）
  static Widget groupByItems(List<SettingsItem> items) {
    List<Widget> children = [];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];

      children.add(SettingsUI.item(title: item.title, subtitle: item.subtitle, icon: item.icon, trailing: item.trailing, onTap: item.onTap));

      if (i != items.length - 1) {
        children.add(SettingsUI.divider());
      }
    }

    return SettingsUI.group(children);
  }
}
