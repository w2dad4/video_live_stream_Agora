import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_live_stream/utility/live_online_count_widget.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'package:video_live_stream/start_video/gift_view.dart';
import 'package:video_live_stream/start_video/room_manager_logic.dart';
import 'package:video_live_stream/start_video/showUserActionMenu.dart';
import 'package:video_live_stream/start_video/start_video_mian.dart';

//1,顶上的主播的头像，名称，观看人数以及信息发送及显示
class LiveRoomComponents extends ConsumerWidget {
  final LiveDataMode info;
  final bool isHost; // 🎯 是否是主播模式

  const LiveRoomComponents({super.key, required this.info, this.isHost = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.black26),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          //主播头像
          CircleAvatar(backgroundImage: AssetImage(info.hostAvarat), radius: 20),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                //主播的名称
                children: [
                  Text(info.hostName, style: TextStyle(fontSize: 12, color: Colors.white)),
                  const SizedBox(width: 5),
                  //直播中
                  const Text('直播中', style: TextStyle(fontSize: 13, color: Colors.redAccent)),
                ],
              ),
              //人数显示 - 使用通用在线人数组件
              LiveOnlineCountWidget(
                roomId: info.liveID,
                isHost: isHost,
                iconSize: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 2. 交互层核心重组
class LiveChatOverlay extends ConsumerWidget {
  final String roomID; // 🟢 增加 roomID

  final bool isHost;
  const LiveChatOverlay({super.key, required this.isHost, required this.roomID});
  //管理生命周期,避免主页面重绘导致状态丢失
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 无论主播观众都看得到消息列表
          BuildChatList(),
          // 根据主播观众显示不同的底部工具栏
          isHost ? HostActionRow(roomID: roomID) : ChatInput(roomID: roomID),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

//信息显示区域
class BuildChatList extends ConsumerStatefulWidget {
  const BuildChatList({super.key});

  @override
  ConsumerState<BuildChatList> createState() => BuildChatListState();
}

class BuildChatListState extends ConsumerState<BuildChatList> {
  final ScrollController _scrollController = ScrollController(); //监听滚动

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = ref.watch(chatmessageProvider);

    return Container(
      constraints: const BoxConstraints(maxHeight: 150), //限制字体出现高度
      child: ListView.builder(
        controller: _scrollController,
        shrinkWrap: true, // 关键：让列表根据内容收缩
        itemCount: message.length,
        itemBuilder: (context, index) {
          final item = message[index];
          return GestureDetector(
            onTap: () {
              final canManage = ref.read(canManageProvider);
              if (canManage && item.uid != 'sync') {
                showUserActionMenu(context, ref, item.uid, item.userName);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 66, 66, 66).withValues(alpha: 0.3), //
                borderRadius: BorderRadius.circular(10),
              ),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14),
                  children: [
                    TextSpan(
                      text: "${item.userName}: ",
                      style: const TextStyle(fontSize: 15, color: Color.fromARGB(255, 61, 163, 247), fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: item.content,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

//主播端特有的工具栏
class HostActionRow extends ConsumerWidget {
  final String roomID; // 🟢 增加 roomID

  const HostActionRow({super.key, required this.roomID});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _hostBtn(
          icon: CupertinoIcons.person_2_fill,
          label: '连麦',
          color: Colors.blueAccent,
          onTap: () {
            print('点击了连麦');
          },
        ),
        const SizedBox(width: 10),
        _hostBtn(
          icon: CupertinoIcons.bolt_horizontal_circle_fill,
          label: 'PK',
          color: Colors.orangeAccent,
          onTap: () {
            print('点击了PK');
          },
        ),
        const Spacer(),
        BottomActionBar(isHost: true, roomID: roomID),
      ],
    );
  }

  Widget _hostBtn({required IconData icon, required String label, required Color color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white.withValues(alpha: 0.2)),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

//发送信息
class ChatInput extends ConsumerStatefulWidget {
  final String roomID;
  const ChatInput({super.key, required this.roomID});

  @override
  ConsumerState<ChatInput> createState() => ChatInputState();
}

class ChatInputState extends ConsumerState<ChatInput> {
  final TextEditingController _textcontroller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  //2.自动滚动的方法
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
      }
    });
  }

  void _handleSend() {
    // 1. 获取并检查输入内容
    final text = _textcontroller.text.trim();
    if (text.isEmpty) return;

    // 2. 获取当前发送者的用户信息
    final me = ref.read(meProvider);
    // 3. 构造消息模型
    final newMessage = ChatsMessage(content: text, uid: me?.uid ?? '', userName: me?.name ?? "匿名用户");

    // 4. 使用 Riverpod 更新全局消息列表
    ref.read(chatmessageProvider.notifier).update((state) => [...state, newMessage]);
    // 5. 交互收尾工作
    _textcontroller.clear(); // 清空输入框
    _scrollToBottom(); // 确保用户能看到自己刚发的最新消息
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white.withValues(alpha: 0.4)),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textcontroller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: '说点什么',
                      helperStyle: TextStyle(color: Color.fromARGB(255, 192, 190, 190), fontSize: 14),
                      contentPadding: EdgeInsets.symmetric(horizontal: 15),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                TextButton(
                  onPressed: _handleSend,
                  child: Text('发送', style: TextStyle(fontSize: 15, color: Colors.red)),
                ),
              ],
            ),
          ),
        ),
        //送礼物
        const SizedBox(width: 10),
        BottomActionBar(isHost: false, roomID: widget.roomID),
      ],
    );
  }
}
