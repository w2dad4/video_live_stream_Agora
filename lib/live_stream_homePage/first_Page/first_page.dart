import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/tool/index.dart';

class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => FirstPageState();
}

class FirstPageState extends State<FirstPage> {
  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true, // 确保内容可以顶到最上方
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(padding: const EdgeInsets.fromLTRB(16, 5, 16, 8), child: Text('热门主播')),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(childCount: math.min(VideoIndex.contentsindex.length, 4), (context, index) {
                final item = VideoIndex.contentsindex[index];
                return _buildGrandLiveCard(item);
              }),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.9, crossAxisSpacing: 10, mainAxisSpacing: 10),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(padding: EdgeInsets.fromLTRB(16, 5, 16, 8), child: Text('热门推荐')),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = VideoIndex.contentsindex[index];
                return _buildGrandLiveCard(item);
              }, childCount: VideoIndex.contentsindex.length),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1, crossAxisSpacing: 10, mainAxisSpacing: 10),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  //热门推荐
  Widget _buildGrandLiveCard(Map<String, dynamic> item) {
    final String liveId = item['id']?.toString() ?? "0";
    final String cover = item['icon']?.toString() ?? '';
    final String title = item['title']?.toString() ?? '';
    final String region = item['region']?.toString() ?? '';
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1), //
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            //1,点击进入直播间
            GestureDetector(
              onTap: () {
                debugPrint('点击了图片');
                context.pushNamed('StartVideo', extra: {'id': liveId, 'isHost': false});
              },
              child: _buildCover(cover),
            ),
            //2，名字
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: TextStyle(fontSize: 13), maxLines: 1),
                  const SizedBox(height: 4),
                  //地区
                  Text(region, style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(String cover) {
    if (cover.startsWith('http')) {
      return Image.network(
        cover,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => Image.asset('assets/image/002.png', fit: BoxFit.cover),
      );
    }
    if (cover.startsWith('/')) {
      return Image.file(
        File(cover),
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => Image.asset('assets/image/002.png', fit: BoxFit.cover),
      );
    }
    return Image.asset(
      cover.isEmpty ? 'assets/image/002.png' : cover,
      fit: BoxFit.cover,
      errorBuilder: (_, error, stackTrace) => Image.asset('assets/image/002.png', fit: BoxFit.cover),
    );
  }
}
