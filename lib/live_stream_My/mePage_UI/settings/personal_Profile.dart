//个人资料
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_live_stream/config/toppop-up.dart';
import 'package:video_live_stream/features/auth/auth_provider.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';

class PersonalProfile extends ConsumerWidget {
  const PersonalProfile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('个人资料'), centerTitle: true),
      body: ListView(
        children: [
          //头像
          _buildItem(title: '头像', trailingWidget: _buildAvatar(me?.avatar), onTap: () => _showAvatarSelector(context, ref)),
          const Divider(height: 1, indent: 12, color: Color(0xFFEEEEEE)),
          //标题
          _buildItem(
            title: '标题',
            value: me?.name ?? '未设置',
            onTap: () => _editTextField(
              context,
              title: '修改标题',
              initialValue: me?.name ?? '',
              onConfirm: (value) {
                // 更新当前用户数据
                final currentUserId = ref.read(currentUserIdProvider);
                if (currentUserId != null) {
                  final currentData = ref.read(userDataProvider(currentUserId));
                  if (currentData != null) {
                    ref.read(userDataProvider(currentUserId).notifier).updateUserData(currentData.copyWith(name: value.trim()));
                  }
                }
              },
            ),
          ),
          const Divider(height: 1, indent: 12, color: Color(0xFFEEEEEE)),
          //固定UID，一个帐号仅此一个UID无法修改
          _buildItem(title: 'UID', value: me?.uid ?? 'unknown', enableArrow: false),
          const Divider(height: 1, indent: 12, color: Color(0xFFEEEEEE)),
          //性别
          _buildItem(title: '性别', value: me?.gender ?? '未设置', onTap: () => _showGenderSelector(context, ref)),
          const Divider(height: 1, indent: 12, color: Color(0xFFEEEEEE)),
          //地区
          _buildItem(
            title: '地区',
            value: me?.region ?? '未设置',
            onTap: () => _editTextField(
              context,
              title: '设置地区',
              initialValue: me?.region == '未设置' ? '' : (me?.region ?? ''),
              onConfirm: (value) {
                // 更新当前用户数据
                final currentUserId = ref.read(currentUserIdProvider);
                if (currentUserId != null) {
                  final currentData = ref.read(userDataProvider(currentUserId));
                  if (currentData != null) {
                    ref.read(userDataProvider(currentUserId).notifier).updateUserData(currentData.copyWith(region: value.trim().isEmpty ? '未设置' : value.trim()));
                  }
                }
              },
            ),
          ),
          const Divider(height: 1, indent: 12, color: Color(0xFFEEEEEE)),
          //签名
          _buildItem(
            title: '签名',
            value: me?.signature ?? '这个人很懒，还没有签名',
            onTap: () => _editTextField(
              context,
              title: '设置签名',
              initialValue: me?.signature ?? '',
              maxLines: 3,
              onConfirm: (value) {
                // 更新当前用户数据
                final currentUserId = ref.read(currentUserIdProvider);
                if (currentUserId != null) {
                  final currentData = ref.read(userDataProvider(currentUserId));
                  if (currentData != null) {
                    ref.read(userDataProvider(currentUserId).notifier).updateUserData(currentData.copyWith(signature: value.trim().isEmpty ? '这个人很懒，还没有签名' : value.trim()));
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  //通用列表项
  Widget _buildItem({required String title, String? value, Widget? trailingWidget, bool enableArrow = true, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: Colors.white,
        child: Row(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, color: Color(0xFF333333))),
            const Spacer(),
            if (value != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            if (trailingWidget != null) trailingWidget,
            if (enableArrow) const SizedBox(width: 6),
            if (enableArrow) const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  //头像
  Widget _buildAvatar(String? avatarPath) {
    final path = avatarPath ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: path.isEmpty
          ? Container(
              width: 40,
              height: 40,
              color: Colors.grey[300],
              child: const Icon(CupertinoIcons.person_fill, color: Colors.white),
            )
          : _renderAvatar(path),
    );
  }

  Widget _renderAvatar(String path) {
    if (path.startsWith('http')) {
      return Image.network(path, width: 40, height: 40, fit: BoxFit.cover);
    }
    if (path.startsWith('/')) {
      return Image.file(File(path), width: 40, height: 40, fit: BoxFit.cover);
    }
    return Image.asset(path, width: 40, height: 40, fit: BoxFit.cover);
  }

  //调用相册
  void _showAvatarSelector(BuildContext context, WidgetRef ref) async {
    // 演示版：提供几张预置头像，避免引入额外依赖
    final ImagePicker picker = ImagePicker();
    try {
      // 调用相册选择图片
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxHeight: 512, // 限制宽度
        imageQuality: 80, // 压缩质量
      );
      //如果用户没有选择图片，则直接返回
      if (image == null) return;
      // 3. 成功拿到路径，更新用户数据
      final currentUserId = ref.read(currentUserIdProvider);
      if (currentUserId != null) {
        final currentData = ref.read(userDataProvider(currentUserId));
        if (currentData != null) {
          ref.read(userDataProvider(currentUserId).notifier).updateUserData(currentData.copyWith(avatar: image.path));
        }
      }
      //成功提醒
      if (context.mounted) {
        ToastUtil.showGreenSuccess(context, "成功", "头像已更新");
      }
    } catch (e) {
      if (context.mounted) {
        ToastUtil.showGreenSuccess(context, '头像选择失败', '请稍后');
      }
    }
  }

  //性别选择对话框
  void _showGenderSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Center(child: Text('男')),
              onTap: () {
                _updateGender(ref, '男');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Center(child: Text('女')),
              onTap: () {
                _updateGender(ref, '女');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Center(child: Text('保密')),
              onTap: () {
                _updateGender(ref, '保密');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 更新性别
  void _updateGender(WidgetRef ref, String gender) {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId != null) {
      final currentData = ref.read(userDataProvider(currentUserId));
      if (currentData != null) {
        ref.read(userDataProvider(currentUserId).notifier).updateUserData(currentData.copyWith(gender: gender));
      }
    }
  }

  //弹出一个包含输入框的对话框
  void _editTextField(BuildContext context, {required String title, required String initialValue, int maxLines = 1, required ValueChanged<String> onConfirm}) {
    final controller = TextEditingController(text: initialValue);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            TextButton(
              onPressed: () {
                onConfirm(controller.text);
                Navigator.pop(context);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}
