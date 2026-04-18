import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/config/login/login_provider.dart';
import 'package:video_live_stream/features/auth/auth_provider.dart';
import 'package:video_live_stream/live_stream_My/mePage_UI/apply_Page.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'package:video_live_stream/tool/region.dart';

class MyVideoPage extends ConsumerStatefulWidget {
  const MyVideoPage({super.key});

  @override
  ConsumerState<MyVideoPage> createState() => _MyVideoPageState();
}

class _MyVideoPageState extends ConsumerState<MyVideoPage> {
  String _localUid = '';

  @override
  void initState() {
    super.initState();
    // 延迟初始化，避免阻塞主线程
    Future.delayed(const Duration(milliseconds: 100), _ensureProfileReady);
  }

  Future<void> _ensureProfileReady() async {
    final uid = await ensureUserId();
    if (!mounted) return;

    ref.read(currentUserIdProvider.notifier).state = uid;
    await ref.read(userDataProvider(uid).notifier).loadUserData();

    if (!mounted) return;
    setState(() {
      _localUid = uid;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 使用 watch 监听用户信息
    final me = ref.watch(meProvider);
    final locationAsync = ref.watch(userLocationProvider);
    final displayUid = me?.uid?.trim().isNotEmpty == true ? me!.uid!.trim() : _localUid;
    final displayName = me?.name?.trim().isNotEmpty == true ? me!.name!.trim() : '未设置';

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
                    Text("昵称: $displayName", style: const TextStyle(fontSize: 15)), //昵称
                    Text("UID: ${displayUid.isEmpty ? 'unknown' : displayUid}", style: const TextStyle(fontSize: 15)), //UID
                    locationAsync.when(
                      data: (area) => Text('IP:$area', style: const TextStyle(fontSize: 15)), //ip地址
                      loading: () => const Text('正在获取位置...', style: TextStyle(fontSize: 15)),
                      error: (Object error, StackTrace stackTrace) => const Text('获取位置失败', style: TextStyle(fontSize: 15)),
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
      return Image.file(
        File(path),
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(height: 80, width: 80, color: Colors.grey[300], child: const Icon(Icons.person)),
      );
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
