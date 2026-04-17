import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/services/live_room_service.dart';

class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => FirstPageState();
}

class FirstPageState extends State<FirstPage> {
  List<Map<String, dynamic>> _liveRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLiveRooms();
  }

  Future<void> _fetchLiveRooms() async {
    setState(() => _isLoading = true);
    final rooms = await LiveRoomService.getLiveRooms();
    if (!mounted) return;
    setState(() {
      _liveRooms = rooms;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_liveRooms.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchLiveRooms,
        child: ListView(
          children: const [
            SizedBox(height: 200),
            Center(
              child: Text('主播正在准备中', style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
            SizedBox(height: 20),
            Center(
              child: Text('下拉刷新', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchLiveRooms,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true, // 确保内容可以顶到最上方
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // 确保可以下拉刷新
          slivers: [
            SliverToBoxAdapter(
              child: Padding(padding: const EdgeInsets.fromLTRB(16, 5, 16, 8), child: Text('热门主播')),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(childCount: math.min(_liveRooms.length, 4), (context, index) {
                  final item = _liveRooms[index];
                  return _buildGrandLiveCard(item);
                }),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.9, crossAxisSpacing: 10, mainAxisSpacing: 10),
              ),
            ),
            // 只有存在第5个及以后的房间时，才显示"热门推荐"区域
            if (_liveRooms.length > 4) ...[
              SliverToBoxAdapter(
                child: Padding(padding: EdgeInsets.fromLTRB(16, 5, 16, 8), child: Text('热门推荐')),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    // 从第5个房间开始（索引4）
                    final item = _liveRooms[index + 4];
                    return _buildGrandLiveCard(item);
                  }, childCount: _liveRooms.length - 4),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1, crossAxisSpacing: 10, mainAxisSpacing: 10),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
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
