import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_live_stream/tool/index.dart';
import 'package:video_live_stream/tool/onRefresh.dart';
import 'package:video_live_stream/utility/pullRefreshContainer.dart';

class PkPage extends StatefulWidget {
  const PkPage({super.key});
  @override
  State<PkPage> createState() => PkPageState();
}

class PkPageState extends State<PkPage> {
  Future<void> _loadData() async {
    // 模拟刷新，后续可接入真实数据接口
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PullRefreshContainer(
      onRefresh: _loadData,
      child: Padding(
        padding: EdgeInsets.all(10),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(
            0,
            0,
            0,
            Positions.topPadding(context) + 10,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemCount: VideoIndex.contentsindex.length,
          itemBuilder: (context, index) {
            final item = VideoIndex.contentsindex[index];
            return _buildItem(item);
          },
        ),
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> item) {
    final String icon = item['icon']?.toString() ?? '';
    final String title = item['title']?.toString() ?? '未知标题';
    return Stack(
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _buildCover(icon),
          ),
        ),
        Positioned(
          left: 10,
          bottom: 10,
          right: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCover(String icon) {
    if (icon.startsWith('http')) {
      return Image.network(
        icon,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) =>
            Image.asset('assets/image/002.png', fit: BoxFit.cover),
      );
    }
    if (icon.startsWith('/')) {
      return Image.file(
        File(icon),
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) =>
            Image.asset('assets/image/002.png', fit: BoxFit.cover),
      );
    }
    return Image.asset(
      icon.isEmpty ? 'assets/image/002.png' : icon,
      fit: BoxFit.cover,
      errorBuilder: (_, error, stackTrace) =>
          Image.asset('assets/image/002.png', fit: BoxFit.cover),
    );
  }
}
