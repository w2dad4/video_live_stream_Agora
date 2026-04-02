import 'package:flutter/material.dart';
import 'package:video_live_stream/live_stream_message/message/message_Data/message_Model.dart'; 

class SlidableTile extends StatefulWidget {
  final ChatConversation item;
  final VoidCallback onDelete;
  final Widget child;
  const SlidableTile({super.key, required this.item, required this.onDelete, required this.child});

  @override
  State<SlidableTile> createState() => SlidableTileState();
}

class SlidableTileState extends State<SlidableTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0;
  final double _actionWidth = 80; // 删除按钮的宽度
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      //当用户开始滑动时
      onHorizontalDragUpdate: (details) {
        setState(() {
          //只允许向左滑动
          _dragExtent += details.primaryDelta!;
          // 1. 不允许向右滑 ( _dragExtent > 0 )
          if (_dragExtent > 0) _dragExtent = 0;
          // 2. 向左滑最大不超过按钮宽度 ( -80 )
          if (_dragExtent <- _actionWidth) _dragExtent = -_actionWidth;
        });
      },
      //当用户滑到结尾时
      onHorizontalDragEnd: (details) {
        //如果超过了，就自动吸附到80
        if (_dragExtent < -_actionWidth / 2) {
          _controller.animateTo(1.0);
          setState(() => _dragExtent = -_actionWidth);
        } else {
          _controller.animateTo(0.0);
          setState(() => _dragExtent = 0);
        }
      },
      child: Stack(
        children: [
          // 底层：放置删除按钮
          Positioned.fill(
            child: Container(
              width: _actionWidth,
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: widget.onDelete,
                child: const Text('删除', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: Container(color:Colors.white, child: widget.child),
          ),
        ],
      ),
    );
  }
}
