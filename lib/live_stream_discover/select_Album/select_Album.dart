import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_live_stream/features/auth/auth_provider.dart';
import 'package:video_live_stream/library.dart';

class SelectAlbum extends ConsumerWidget {
  final LiveMode mode;
  const SelectAlbum({super.key, required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    final orientation = ref.watch(positioningProvider(mode)); //定位
    final evident = ref.watch(visibleProvider(mode)); //可见
    return Positioned(
      top: 100,
      left: 20,
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              _buildImage(context, ref),
              Text('修改封面', style: TextStyle(fontSize: 12, color: Colors.white)),
            ],
          ),
          SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Dialogbox.show(context, mode),
                child: Row(
                  children: [
                    Text("${me?.name ?? '主播'}正在直播", style: TextStyle(fontSize: 18, color: Colors.white)), //
                    SizedBox(width: 3),
                    Icon(CupertinoIcons.paperplane, size: 20),
                  ],
                ),
              ),
              Container(margin: EdgeInsets.symmetric(vertical: 5), width: 200, height: 1, color: Colors.white),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      print('点击了开启定位');
                      SelectionDialogHelper.showVisibilitySelector(context, ref, mode);
                    },
                    child: Row(
                      children: [
                        Text(orientation, style: TextStyle(fontSize: 15, color: Colors.white)),
                        Icon(CupertinoIcons.chevron_right, size: 18, color: Colors.white),
                      ],
                    ),
                  ),
                  Container(margin: EdgeInsets.symmetric(horizontal: 10), width: 1, height: 20, color: Colors.white),
                  GestureDetector(
                    onTap: () {
                      print('点击了所有人可见');
                      Visible.visibleHelper(context, ref, mode);
                    },
                    child: Row(
                      children: [
                        Text(evident, style: TextStyle(fontSize: 15, color: Colors.white)),
                        Icon(CupertinoIcons.chevron_right, size: 18, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  //封面
  Widget _buildImage(BuildContext context, WidgetRef ref) {
    //监听meProvider里的信息
    final my = ref.watch(meProvider);
    final avatarPath = my?.avatar;
    // 插入直播（封面图等）
    return GestureDetector(
      onTap: () async => await _pickImageFromGallery(context, ref),

      child: Container(
        width: 60,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(10), child: _randerCover(avatarPath)),
      ),
    );
  }

  // 此方法现在是异步的，因为它调用相册
  Future<void> _pickImageFromGallery(BuildContext context, WidgetRef ref) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 80);
      if (image != null) {
        print('用户选择了:${image.path}');
        // 更新当前用户的头像
        final currentUserId = ref.read(currentUserIdProvider);
        if (currentUserId != null) {
          final currentData = ref.read(userDataProvider(currentUserId));
          if (currentData != null) {
            ref.read(userDataProvider(currentUserId).notifier).updateUserData(
              currentData.copyWith(avatar: image.path),
            );
          }
        }
      }
    } catch (e) {
      print('选择图片时发生的错误');
    }
  }

  // 抽取渲染逻辑：区分本地文件和资源文件
  Widget _randerCover(String? path) {
    if (path == null || path.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 20),
          Text('添加封面', style: TextStyle(fontSize: 13, color: Colors.white)),
        ],
      );
    }
    if (path.startsWith('/') || path.contains('cache')) {
      return Image.file(File(path), fit: BoxFit.cover);
    }
    return Image.asset(path, fit: BoxFit.cover);
  }
}
