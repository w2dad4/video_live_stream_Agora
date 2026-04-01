import 'package:flutter/material.dart';
import 'package:video_live_stream/tool/color.dart';
import 'package:video_player/video_player.dart';

class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key});

  @override
  State<RecommendPage> createState() => RecommendPageState();
}

class RecommendPageState extends State<RecommendPage> {
  int _focusedIndex = 0;
  final PageController _pageController = PageController();
  //刷新逻辑
  Future<void> _onRefresh() async {
    await Future.delayed(Duration(seconds: 2));
    setState(() {});
  }

  final List<String> videocontext = [
    'assets/video/video_demo.mp4',
    'assets/video/video_demo1.mp4', //
    'assets/video/video_demo2.mp4',
    'assets/video/video_demo3.mp4',
    'assets/video/video_demo4.mp4',
    'assets/video/video_demo5.mp4', //
    'assets/video/video_demo6.mp4',
    'assets/video/video_demo7.mp4',
    'assets/video/video_demo8.mp4',
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorState.color1,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical, //垂直滚动
          itemCount: videocontext.length,
          onPageChanged: (index) => setState(() {
            _focusedIndex = index;
          }),
          itemBuilder: (context, index) {
            return VideoCard(
              index: index,
              isFloyn: _focusedIndex == index, //
              videoPath: videocontext[index],
            );
          },
        ),
      ),
    );
  }
}

class VideoCard extends StatefulWidget {
  final int index;
  final bool isFloyn;
  final String videoPath;
  const VideoCard({super.key, required this.index, required this.isFloyn, required this.videoPath});

  @override
  State<VideoCard> createState() => VideoCardState();
}

class VideoCardState extends State<VideoCard> {
  VideoPlayerController? _controller;
  bool _isInitial = false;

  @override
  void initState() {
    super.initState();
    if (widget.isFloyn) {
      _initLive();
    }
  }

  @override
  void didUpdateWidget(VideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // // 滑入页面 -> 初始化并播放
    if (widget.isFloyn && !oldWidget.isFloyn) {
      _initLive();
      // 场景 B：滑出页面 -> 仅停止并释放，同时重置 UI 状态
    } else if (!widget.isFloyn && oldWidget.isFloyn) {
      _disposeLive();
      if (mounted) setState(() => _isInitial = false);
    }
  }

  // 纯粹的资源初始化
  void _initLive() async {
    _controller = VideoPlayerController.asset(widget.videoPath);
    try {
      await _controller?.initialize();
      if (mounted && widget.isFloyn) {
        setState(() => _isInitial = true);
        await _controller?.setLooping(true);
        _controller?.play();
      }
    } catch (e) {
    }
  }

  // 纯粹的资源清理逻辑（不含任何 setState）
  void _disposeLive() {
    final oldContrall = _controller;
    _controller = null;
    oldContrall?.dispose();
  }

  @override
  void dispose() {
    _disposeLive();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        //1,播放画面的直播
        _isInitial && _controller != null
            ? SizedBox.expand(
                child: ClipRect(
                  child: FittedBox(
                    fit: BoxFit.cover, //全屏沉浸铺满
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: _controller!.value.size.width, //
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                ),
              )
            : Container(
                color: Colors.black,
                child: Center(child: CircularProgressIndicator()),
              ),
        //2，顶层互动ui界面
        _buildtext(),
      ],
    );
  }

  Widget _buildtext() {
    return Positioned.fill(
      child: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 20,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: Colors.purple),
                  child: Center(
                    child: Text('直播中', style: TextStyle(fontSize: 12, color: ColorState.white)),
                  ),
                ),
                SizedBox(width: 5),
                Container(
                  width: 65,
                  height: 20,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: Colors.white),
                  child: Center(
                    child: Text('你的关注', style: TextStyle(fontSize: 12, color: ColorState.color1)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 5),
            Text(
              '@标题',
              style: TextStyle(fontSize: 18, color: ColorState.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
