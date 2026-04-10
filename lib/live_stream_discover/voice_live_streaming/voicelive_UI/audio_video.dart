import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/library.dart';

//语音直播的整个UI
class AudioViodePage extends ConsumerStatefulWidget {
  final String audioID;
  const AudioViodePage({super.key, required this.audioID});

  @override
  ConsumerState<AudioViodePage> createState() => _AudioViodePageState();
}

class _AudioViodePageState extends ConsumerState<AudioViodePage> {
  bool _inited = false;
  Timer? _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider);
    final myId = me.uid?.trim().isNotEmpty == true ? me.uid!.trim() : 'self';
    final isHost = myId == widget.audioID;
    final room = ref.watch(voiceRoomProvider(widget.audioID));

    if (!_inited) {
      _inited = true;
      Future.microtask(() {
        ref
            .read(voiceRoomProvider(widget.audioID).notifier)
            .initRoom(
              hostId: widget.audioID,
              hostName: isHost ? (me.name ?? '主播') : '主播', //
              hostAvatar: isHost ? (me.avatar ?? 'assets/image/002.png') : 'assets/image/002.png',
            );
      });
    }

    final hostSeat = room.seats.first;
    final duration = _formatDuration(_now.difference(room.startAt));

    return Scaffold(
      backgroundColor: const Color(0xff1A1B25),
      appBar: AppBar(
        backgroundColor: const Color(0xff1A1B25),
        automaticallyImplyLeading: false,
        titleSpacing: 8,
        title: _HostInfoCard(
          hostName: hostSeat.name ?? '主播',
          hostAvatar: hostSeat.avatar ?? 'assets/image/002.png', //
          onlineCount: max(1, room.seats.where((s) => s.uid != null).length),
        ),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
        actions: [
          if (isHost)
            IconButton(
              icon: const Icon(Icons.adjust, color: Color.fromARGB(255, 170, 37, 37)),
              onPressed: () async {
                final shouldClose = await _showCloseDialog(context);
                if (shouldClose == true && context.mounted) {
                  context.pop();
                }
              },
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xff2B2D3A), borderRadius: BorderRadius.circular(10)),
            child: Text(isHost ? '你正在语音开播，1号位默认主持位' : '你正在低延迟收听，支持实时聊天与连麦', style: const TextStyle(color: Colors.white70)),
          ),

          // 1-8 麦位区域
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              itemCount: room.seats.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 12, crossAxisSpacing: 10, childAspectRatio: 0.53),
              itemBuilder: (context, index) {
                final seat = room.seats[index];
                return SeatTile(
                  seat: seat,
                  isHost: isHost,
                  isSelf: seat.uid == myId,
                  onTap: () => _handleSeatTap(context, seat, isHost, myId), //
                  onDoubleTap: () => _handleSeatDoubleTap(context, seat),
                );
              },
            ),
          ),

          // 底部聊天区（参考视频直播消息位）
          VoiceChatArea(
            roomId: widget.audioID,
            isHost: isHost,
            canShowGift: !isHost, // 观众和上麦者可见（主播不可见）
            liveDuration: duration,
          ),
        ],
      ),
    );
  }

  // 单击麦位：按角色触发不同操作
  void _handleSeatTap(BuildContext context, VoiceSeat seat, bool isHost, String myId) {
    final notifier = ref.read(voiceRoomProvider(widget.audioID).notifier);

    if (isHost) {
      if (seat.index == 1 || seat.uid == null) return;
      showModalBottomSheet<void>(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                title: const Text('关闭上麦'),
                onTap: () {
                  notifier.kickFromMic(seat.index);
                  notifier.setAllowJoin(seat.index, false);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(seat.muted ? '取消静音该麦' : '静音该麦'),
                onTap: () {
                  notifier.toggleMute(seat.index);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      );
      return;
    }

    // 用户点击自己的麦位：下麦 + 静音
    if (seat.uid == myId) {
      showModalBottomSheet<void>(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                title: const Text('下麦'),
                onTap: () {
                  notifier.leaveMic(myId);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(seat.muted ? '取消静音' : '静音'),
                onTap: () {
                  notifier.toggleSelfMute(uid: myId);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      );
      return;
    }

    // 用户点击其他麦位：送礼
    if (seat.uid != null) {
      _showGiftSheet(context, seat);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('点击空麦位，可等待主播开放上麦')));
  }

  // 双击麦位：展示上麦者信息
  void _handleSeatDoubleTap(BuildContext context, VoiceSeat seat) {
    if (seat.uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('当前是空麦位')));
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('麦位信息'),
        content: Text('昵称：${seat.name ?? "未知"}\nUID：${seat.uid}\n麦位：${seat.index}号位\n状态：${seat.canSpeak ? "可发言" : "不可发言"}'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('知道了'))],
      ),
    );
  }

  void _showGiftSheet(BuildContext context, VoiceSeat seat) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xff232534),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: 280,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('送给 ${seat.name ?? "用户"}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 4,
                    children: const [
                      _GiftItem(icon: '🌹', label: '玫瑰'),
                      _GiftItem(icon: '🍦', label: '冰淇淋'),
                      _GiftItem(icon: '🚀', label: '火箭'),
                      _GiftItem(icon: '👑', label: '皇冠'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showCloseDialog(BuildContext context) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('关闭直播'),
        content: const Text('确定要结束当前语音直播吗？'),
        actions: [
          CupertinoDialogAction(child: const Text('取消'), onPressed: () => context.pop(false)),
          CupertinoDialogAction(isDestructiveAction: true, child: const Text('确认关闭'), onPressed: () => context.pop(true)),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

//顶部的主播信息
class _HostInfoCard extends StatelessWidget {
  final String hostName;
  final String hostAvatar;
  final int onlineCount;

  const _HostInfoCard({required this.hostName, required this.hostAvatar, required this.onlineCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.black26),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 20, backgroundImage: _avatarProvider(hostAvatar)),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(hostName, style: const TextStyle(fontSize: 12, color: Colors.white)),
                  const SizedBox(width: 5),
                  const Text('直播中', style: TextStyle(fontSize: 13, color: Colors.redAccent)),
                ],
              ),
              Row(
                children: [
                  const Icon(CupertinoIcons.person_2_fill, size: 18, color: Colors.white),
                  const Text(': ', style: TextStyle(fontSize: 15, color: Colors.white)),
                  Text('$onlineCount', style: const TextStyle(fontSize: 13, color: Colors.white)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  ImageProvider _avatarProvider(String path) {
    if (path.startsWith('http')) return NetworkImage(path);
    if (path.startsWith('/')) return FileImage(File(path));
    return AssetImage(path);
  }
}

class _GiftItem extends StatelessWidget {
  final String icon;
  final String label;
  const _GiftItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 32)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
