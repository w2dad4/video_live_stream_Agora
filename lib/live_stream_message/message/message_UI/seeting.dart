import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

//逻辑层
class BlacklistNotifier extends StateNotifier<bool> {
  BlacklistNotifier() : super(false);
  //切换状态方法
  void toggle() => state = !state;
  //也可以根据业务逻辑强制设置状态
  void setBlacklist(bool value) => state = value;
}

//全局声明一个 Provider 来管理黑名单状态
final isBlacklistedProvider = StateNotifierProvider<BlacklistNotifier, bool>((ref) => BlacklistNotifier());

//设置UI页面
class SettingPage extends ConsumerWidget {
  const SettingPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isBlacklisted = ref.watch(isBlacklistedProvider);
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 242, 242),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 242, 242, 242),
        title: Text('设置'),
        leading: GestureDetector(
          child: Icon(Icons.arrow_back_ios),
          onTap: () {
            context.pop();
          },
        ),
      ),
      body: ListView(
        children: [
          SettingTile(title: '编辑备注', onTap: () {}),
          const SizedBox(height: 10),

          SettingTile(title: '分享', onTap: () {}),
          const SizedBox(height: 10),

          SettingTile(
            title: '加入黑名单',
            //           icon: isBlacklisted ? MyIcons.gift : MyIcons.close,
            // iconColor: isBlacklisted ? Colors.green : Colors.grey,
            trailing: Switch(
              value: isBlacklisted,
              onChanged: (value) {
                ref.read(isBlacklistedProvider.notifier).toggle(); // 切换黑名单状态
              },
            ),
            onTap: () {
              ref.read(isBlacklistedProvider.notifier).toggle(); // 切换黑名单状态
            },
          ),
          const SizedBox(height: 10),

          // 删除按钮
          SettingTile(
            title: '删除联系人',
            iconColor: Colors.red,
            trailing: const SizedBox.shrink(), // 不显示箭头
            onTap: () => _buildDeleteButton(context),
          ),
        ],
      ),
    );
  }
}

void _buildDeleteButton(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('删除联系人'),
      content: Text('确定要删除该联系人吗？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // 取消
          child: Text('取消'),
        ),
        TextButton(
          onPressed: () {
            // 执行删除操作
            Navigator.pop(context); // 关闭对话框
          },
          child: Text('删除', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

class SettingTile extends StatelessWidget {
  final String? title; // 标题文本
  final IconData? icon; // 标题图标
  final Color? iconColor; // 标题颜色
  final VoidCallback? onTap; // 点击事件回调
  final Widget? trailing; // 支持自定义右侧内容（如 Switch 或箭头）
  const SettingTile({
    super.key,
    this.title,
    this.icon, //
    this.iconColor,
    this.onTap,
    this.trailing,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 54,
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              //图标显示
              if (icon != null) ...[Icon(icon, color: iconColor ?? Colors.black87, size: 22)],
              Expanded(
                child: Text(title!, style: TextStyle(fontSize: 18, color: Colors.black)),
              ),
              //右侧显示icon
              trailing ?? Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
