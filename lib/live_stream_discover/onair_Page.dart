import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_live_stream/live_stream_discover/live_streaming_starts/logic_layer_data/logic_layer.dart';
import 'package:video_live_stream/live_stream_discover/live_streaming_starts/shiping_UI/video_shiping.dart';
import 'package:video_live_stream/live_stream_discover/voice_live_streaming/speech_main.dart';

class OnairPage extends ConsumerStatefulWidget {
  const OnairPage({super.key});

  @override
  ConsumerState<OnairPage> createState() => _OnairPageState();
}

class _OnairPageState extends ConsumerState<OnairPage> {
  @override
  void initState() {
    super.initState();
    // 返回开播页时恢复预览会话开关
    Future.microtask(() {
      ref.read(previewCameraActiveProvider.notifier).state = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> onAirList = [
      {'title': '视频开播', 'page': const VideoShipingPage()},
      {'title': '语音开播', 'page': const SpeechMainTab()},
    ];
    return DefaultTabController(
      length: onAirList.length,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          primary: false,
          toolbarHeight: 0,
          elevation: 0,
          backgroundColor: const Color.fromARGB(255, 233, 231, 231),
          centerTitle: true,
          title: Container(
            height: 45,
            decoration: BoxDecoration(
              color: Colors.grey[100]!.withValues(alpha: 0.3), //
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          bottom: TabBar(
            tabs: onAirList.map((item) => Tab(text: item['title'])).toList(),
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
            indicatorColor: Colors.blueAccent,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            labelColor: Colors.black,
            indicatorSize: TabBarIndicatorSize.tab, //  指示器大小充满整个 Tab 区域
            unselectedLabelColor: Colors.grey[600],
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal), //未选中标签的样式
            overlayColor: WidgetStateProperty.all(Colors.transparent), //点击没有水波纹
            dividerColor: Colors.transparent, // 去除底部底线
          ),
        ),
        body: TabBarView(children: onAirList.map((item) => item['page'] as Widget).toList()),
      ),
    );
  }
}
