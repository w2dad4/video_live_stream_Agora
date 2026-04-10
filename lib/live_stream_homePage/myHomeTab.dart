//tab
import 'package:flutter/material.dart';
import 'package:video_live_stream/live_stream_homePage/discover_page/discover_page.dart';
import 'package:video_live_stream/live_stream_homePage/entertainment_page/entertainment.dart';
import 'package:video_live_stream/live_stream_homePage/first_Page/first_page.dart';
import 'package:video_live_stream/live_stream_homePage/pk_page/pk_page.dart';
import 'package:video_live_stream/live_stream_homePage/recommend_page/recommend.dart';
import 'package:video_live_stream/tool/color.dart';
import 'package:video_live_stream/utility/glass.dart';
import 'package:video_live_stream/tool/onRefresh.dart';
import 'package:video_live_stream/tool/permission_manager.dart';

class MyHomeTab extends StatefulWidget {
  const MyHomeTab({super.key});
  @override
  State<MyHomeTab> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomeTab> {
  final List<Map<String, dynamic>> _listTabs = [
    {'title': '推荐', "page": const FirstPage()},
    {'title': '关注', 'page': const RecommendPage()},
    {'title': '附近', 'page': const VideoDiscoverPage()},
    {'title': '娱乐', 'page': const VideoEnterinmentPage()},
    {'title': 'PK', 'page': const PkPage()},
  ];

  @override
  Widget build(BuildContext context) {
    return HomePermissionRequest(
      child: DefaultTabController(
        length: _listTabs.length,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: ColorState.white,

          body: Stack(
            children: [
              TabBarView(
                children: _listTabs.map((item) {
                  return Padding(
                    padding: EdgeInsets.only(top: Positions.topPadding(context) + 60),
                    child: item['page'] as Widget,
                  );
                }).toList(),
              ),
              Positioned(top: Positions.topPadding(context) + 5, left: 0, right: 0, child: _buildGlassTabBar()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTabBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: GlassContainer(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        borderRadius: 30,
        blur: 20, // 增加模糊度更有液态感,
        color: Colors.white.withValues(alpha: 0.4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 0.5),
        child: TabBar(
          isScrollable: true,
          padding: EdgeInsets.zero,
          splashFactory: NoSplash.splashFactory,
          dividerColor: ColorState.transparent,
          tabAlignment: TabAlignment.center,
          // 关键属性 1：将指示器大小设置为 label，配合外部内边距调整
          indicatorSize: TabBarIndicatorSize.tab,
          labelPadding: const EdgeInsets.symmetric(horizontal: 15),
          overlayColor: WidgetStateProperty.all(Colors.transparent), // 5. 彻底取消点击灰色阴影
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(25), //
            color: Colors.black.withValues(alpha: 0.07),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05), width: 0.5),
          ),
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black.withValues(alpha: 0.4),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: _listTabs.map((item) => Tab(height: 43, text: item['title'] as String)).toList(),
        ),
      ),
    );
  }
}
