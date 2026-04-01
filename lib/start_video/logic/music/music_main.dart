import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//音乐
class MusicMain extends ConsumerWidget {
  const MusicMain({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heigbottom = MediaQuery.of(context).size.height * 0.5;
    return Container(
      color: Color(0xff5C8374),
      width: double.infinity,
      height: heigbottom,
      child: Column(
        children: [
          // 1. 顶部美化指示条 (与美颜面板风格统一)
          const SizedBox(height: 10),
          Container(
            width: 100,
            height: 5,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2.5)),
          ),
          // 2. 标题栏
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            alignment: Alignment.center,
            child: const Text(
              '音乐库',
              style: TextStyle(
                color: Colors.white, // 现在背景是深色，白字就可见了
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          // 3. 内容区域
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.music_note_list, color: Colors.white24, size: 48),
                  SizedBox(height: 10),
                  Text('暂无可用音乐', style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
