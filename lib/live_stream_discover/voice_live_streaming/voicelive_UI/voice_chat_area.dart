import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:video_live_stream/library.dart';
import 'package:video_live_stream/live_stream_discover/voice_live_streaming/voicelive_Data/chat_socket_provider.dart';

// 拆分后的聊天区域组件
class VoiceChatArea extends ConsumerStatefulWidget {
  final String roomId;
  final bool isHost;
  final bool canShowGift;
  final String liveDuration;

  const VoiceChatArea({super.key, required this.roomId, required this.isHost, required this.canShowGift, required this.liveDuration});

  @override
  ConsumerState<VoiceChatArea> createState() => VoiceChatAreaState();
}

class VoiceChatAreaState extends ConsumerState<VoiceChatArea> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  StreamSubscription<ChatSocketMessage>? _messageSubscription;

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // 滚动到底部
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // 监听 WebSocket 消息并添加到本地列表
    _setupWebSocketListener();
  }

  // 监听 WebSocket 消息
  void _setupWebSocketListener() {
    // 延迟到 build 完成后设置监听，确保 provider 已初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketNotifier = ref.read(chatSocketProvider(widget.roomId).notifier);
      _messageSubscription = socketNotifier.messageStream.listen(
        (message) {
          // 将收到的消息添加到本地消息列表
          final old = ref.read(voiceChatProvider(widget.roomId));
          ref.read(voiceChatProvider(widget.roomId).notifier).state = [...old, message.toVoiceChatMessage()];
          _scrollToBottom();
        },
        onError: (err) {
          debugPrint('💬 [VoiceChatArea] WebSocket 错误: $err');
        },
      );
      debugPrint('💬 [VoiceChatArea] WebSocket 消息监听已设置');
    });
  }

  // 发送消息 - 通过 WebSocket 发送给所有在线用户
  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // 通过 WebSocket 发送消息（服务端会广播给所有在线用户）
    ref.read(chatSocketProvider(widget.roomId).notifier).sendMessage(text);

    _controller.clear();
    _scrollToBottom();
  }

  // 打开房间管理面板
  void _openRoomManageSheet(BuildContext context) {
    final room = ref.read(voiceRoomProvider(widget.roomId));
    final muted = room.seats.where((s) => s.uid != null && s.muted).toList();
    final onlineCount = room.seats.where((s) => s.uid != null).length;

    final List<_ManageAction> actions = [
      _ManageAction(
        icon: CupertinoIcons.person_crop_circle_badge_exclam,
        label: '禁言名单',
        active: muted.isNotEmpty,
        onTap: () {
          Navigator.pop(context);
          _openMutedManageSheet(context, muted);
        },
      ),
      _ManageAction(
        icon: CupertinoIcons.music_note_2,
        label: room.musicOn ? '音乐(开)' : '音乐',
        active: room.musicOn,
        onTap: () {
          ref.read(voiceRoomProvider(widget.roomId).notifier).setMusic(!room.musicOn);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(room.musicOn ? '音乐已关闭' : '音乐已开启')));
        },
      ),
      _ManageAction(
        icon: CupertinoIcons.videocam,
        label: room.recordingOn ? '录播(开)' : '录播',
        active: room.recordingOn,
        onTap: () {
          ref.read(voiceRoomProvider(widget.roomId).notifier).setRecording(!room.recordingOn);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(room.recordingOn ? '录播已关闭' : '录播已开启')));
        },
      ),
      _ManageAction(
        icon: Icons.access_time,
        label: '直播时长',
        onTap: () {
          Navigator.pop(context);
          _showInfoDialog(context, '直播时长', '当前直播时长：${widget.liveDuration}');
        },
      ),
      _ManageAction(
        icon: CupertinoIcons.person_2_fill,
        label: '观众列表',
        onTap: () {
          Navigator.pop(context);
          _showInfoDialog(context, '观众信息', '当前在线：$onlineCount 人');
        },
      ),
      _ManageAction(
        icon: CupertinoIcons.doc_plaintext,
        label: '房间公告',
        onTap: () {
          Navigator.pop(context);
          _showInfoDialog(context, '房间公告', '欢迎来到语音直播间，请文明发言。');
        },
      ),
      _ManageAction(
        icon: CupertinoIcons.share,
        label: '分享房间',
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('房间分享链接已复制（演示）')));
        },
      ),
      _ManageAction(
        icon: CupertinoIcons.clear_circled,
        label: '清空消息',
        onTap: () {
          ref.read(voiceChatProvider(widget.roomId).notifier).state = const [VoiceChatMessage(uid: 'sync', userName: '系统提示', content: '聊天已由房主清空')];
          Navigator.pop(context);
        },
      ),
    ];
    // 显示房间管理面板
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xff232534),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: 300,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Column(
              children: [
                const Text(
                  '房间管理与设置',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: GridView.builder(
                    itemCount: actions.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 14, crossAxisSpacing: 10, childAspectRatio: 0.82),
                    itemBuilder: (context, index) {
                      final item = actions[index];
                      return _buildManageGridItem(item);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 禁言名单管理页：支持逐个解除禁言
  void _openMutedManageSheet(BuildContext context, List<VoiceSeat> muted) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xff232534),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: 360,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Column(
              children: [
                const Text(
                  '禁言名单',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: muted.isEmpty
                      ? const Center(
                          child: Text('暂无禁言用户', style: TextStyle(color: Colors.white70)),
                        )
                      : ListView.separated(
                          itemCount: muted.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white24),
                          itemBuilder: (context, index) {
                            final seat = muted[index];
                            final title = seat.name?.isNotEmpty == true ? seat.name! : (seat.uid ?? '未知用户');
                            final sub = 'UID: ${seat.uid ?? "未知"} · ${seat.index}号位';
                            return ListTile(
                              title: Text(title, style: const TextStyle(color: Colors.white)),
                              subtitle: Text(sub, style: const TextStyle(color: Colors.white60)),
                              trailing: TextButton(
                                onPressed: () {
                                  ref.read(voiceRoomProvider(widget.roomId).notifier).setMuted(seat.index, false);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('已解除 $title 的禁言')));
                                },
                                child: const Text('解除禁言'),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 显示信息对话框
  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('我知道了'))],
      ),
    );
  }

  // 构建管理网格项
  Widget _buildManageGridItem(_ManageAction item) {
    final color = item.active ? Colors.greenAccent : Colors.white;
    return GestureDetector(
      onTap: item.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
            child: Icon(item.icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final msgs = ref.watch(voiceChatProvider(widget.roomId));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: Color(0xff1A1B25),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 110,
            child: GestureDetector(
              // 点击空白处收起键盘，恢复全屏视野
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (_focusNode.hasFocus) {
                  _focusNode.unfocus();
                }
              },
              child: ListView.builder(
                controller: _scrollController,
                itemCount: msgs.length,
                itemBuilder: (context, index) {
                  final m = msgs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 13),
                        children: [
                          TextSpan(
                            text: '${m.userName}: ',
                            style: const TextStyle(color: Color.fromARGB(255, 97, 181, 255), fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: m.content,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: '说点什么',
                            hintStyle: TextStyle(color: Colors.white60),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      // 发送包裹在 Container 里
                      GestureDetector(
                        onTap: _send,
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xff07C160), borderRadius: BorderRadius.circular(14)),
                          child: const Text('发送', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 原发送位置改成刷礼物 icon（仅观众和上麦者可见；主播不可见）
              if (widget.canShowGift)
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('打开送礼面板')));
                  },
                  child: const Icon(Icons.card_giftcard, color: Colors.orangeAccent, size: 26),
                )
              else
                GestureDetector(
                  // 主播显示房间管理与设置
                  onTap: () => _openRoomManageSheet(context),
                  child: const Icon(Icons.settings, color: Colors.white70, size: 24),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManageAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _ManageAction({required this.icon, required this.label, required this.onTap, this.active = false});
}
