import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/live_stream_My/mePage_UI/apply_Page.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'package:video_live_stream/tool/region.dart';

class MyVideoPage extends ConsumerWidget {
  const MyVideoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用 watch 监听用户信息
    final me = ref.watch(meProvider);
    final locationAsync = ref.watch(userLocationProvider);
    return Scaffold(
      // backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        leading: const Icon(CupertinoIcons.camera_viewfinder), //
        actions: [
          GestureDetector(onTap: () => context.pushNamed('Settings'), child: Icon(CupertinoIcons.square_grid_2x2_fill)),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(me?.avatar), //将头像地址传入
              Padding(
                padding: EdgeInsets.only(left: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("昵称: ${me?.name ?? '未设置'}", style: TextStyle(fontSize: 15)), //昵称
                    Text("UID: ${me?.uid ?? 'unknown'}", style: TextStyle(fontSize: 15)), //UID
                    locationAsync.when(
                      data: (area) => Text('IP:$area', style: TextStyle(fontSize: 15)), //ip地址
                      loading: () => Text('正在获取位置...', style: TextStyle(fontSize: 15)),
                      error: (Object error, StackTrace stackTrace) => Text('获取位置失败', style: TextStyle(fontSize: 15)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 30),
          ApplyPage(),
        ],
      ),
    );
  }

  //头像
  Widget _buildImage(String? avatarPath) {
    return Padding(
      padding: EdgeInsets.only(left: 10),
      child: ClipRRect(borderRadius: BorderRadius.circular(15), child: _renderUniversalAvatar(avatarPath)),
    );
  }

  // 3. 项目资源图片
  Widget _renderUniversalAvatar(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        height: 80,
        width: 80,
        color: Colors.grey[300],
        child: const Icon(CupertinoIcons.person_fill, size: 40, color: Colors.white),
      );
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(height: 80, width: 80, color: Colors.grey[300], child: const Icon(Icons.person)),
      );
    }
    if (path.startsWith('/')) {
      return Image.file(File(path), width: 80, height: 80, fit: BoxFit.cover);
    }
    return Image.asset(
      path,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(height: 80, width: 80, color: Colors.grey[300], child: const Icon(Icons.person)),
    );
  }
}
