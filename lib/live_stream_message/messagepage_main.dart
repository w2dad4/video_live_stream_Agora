import 'package:flutter/material.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_UI/contact_page.dart';
import 'package:video_live_stream/live_stream_message/message/message_UI/message_page.dart';

class VideoMessagePage extends StatefulWidget {
  const VideoMessagePage({super.key});
  @override
  State<VideoMessagePage> createState() => VideoMessagePageState();
}

class VideoMessagePageState extends State<VideoMessagePage> {
  final List<Map<String, dynamic>> tabItem = [
    {'title': '消息', 'page': const MessagePage()},
    {'title': '联系人', 'page': const ContactPage()},
  ];
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabItem.length,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.white.withValues(alpha: 0.3),
        appBar: AppBar(
          primary: false,
          elevation: 0,
          toolbarHeight: 0,
          title: Container(
            height: 45,
            decoration: BoxDecoration(
              color: Colors.grey[100]!.withValues(alpha: 0.3), //
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          bottom: TabBar(
            tabs: tabItem.map((item) => Tab(text: item['title'])).toList(),
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1), //
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            indicatorColor: Colors.blueAccent,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey[600],
            indicatorSize: TabBarIndicatorSize.tab, //  指示器大小充满整个 Tab 区域
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
            overlayColor: WidgetStateProperty.all(Colors.transparent), // 去除 TabBar 默认的点击水波纹
            dividerColor: Colors.transparent, // 去除底部底线
          ),
        ),
        body: TabBarView(children: tabItem.map((item) => item['page'] as Widget).toList()),
      ),
    );
  }
}
