import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

String _formatDateTime(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return "$hour.$minute"; 
}

//直播结束后的页面
class EndPage extends ConsumerWidget {
  final String audioID;
  final DateTime startTime;
  const EndPage({super.key, required this.audioID, required this.startTime});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 获取进入页面的当前时间作为结束时间
    final endTime = DateTime.now();
    //系统手势滑动跳转到直播预览页面
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.goNamed('Mylivestream');
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 1, 13, 42),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 1, 13, 42),
          leading: IconButton(
            onPressed: () => context.goNamed('Mylivestream'),
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
        ),
        body: Column(
          children: [
            Text(
              '直播已结束',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text('${_formatDateTime(startTime)}---${_formatDateTime(endTime)}', style: TextStyle(fontSize: 12, color: Colors.white)),
            const SizedBox(height: 25),
            Container(
              margin: const EdgeInsets.only(left: 10, right: 10),
              width: double.infinity,
              height: 150,
              color: const Color.fromARGB(255, 26, 38, 56).withValues(alpha: 0.5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('你的粉丝都在支持你，加油哦~', style: TextStyle(color: Colors.white)), //
                      GestureDetector(
                        onTap: () {
                          print('点击了:更多');
                        },
                        child: Icon(Icons.arrow_forward_ios, size: 20, color: Colors.white),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  const Divider(height: 0.2, color: Colors.white70),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('0', style: TextStyle(color: Colors.white)),
                      Text('0', style: TextStyle(color: Colors.white)),
                      Text('0', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('收获钻石', style: TextStyle(color: Colors.white)),
                      Text('新增粉丝', style: TextStyle(color: Colors.white)),
                      Text('观众人数', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('0', style: TextStyle(color: Colors.white)),
                      Text('0', style: TextStyle(color: Colors.white)),
                      Text('0', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('观看粉丝', style: TextStyle(color: Colors.white)),
                      Text('送礼人数', style: TextStyle(color: Colors.white)),
                      Text('直播时长', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
