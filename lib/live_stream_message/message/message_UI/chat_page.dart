import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/live_stream_message/message/message_Data/chat_Model.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';

//发消息页面
class ChatPage extends ConsumerStatefulWidget {
  final String chatId;
  const ChatPage({super.key, required this.chatId});
  @override
  ConsumerState<ChatPage> createState() => ChatPageState();
}

class ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _textController = TextEditingController(); //控制器
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  //发送消息的处理函数，包含输入验证和状态更新
  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    ref.read(messageProvider(widget.chatId).notifier).sendMessage(text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    //1. 监听特定 chatId 的消息列表
    final messageindex = ref.watch(messageProvider(widget.chatId));
    // 2. 监听自己的信息
    final me = ref.watch(meProvider);
    // 3.监听对方的联系人详情
    final info = ref.watch(chatDetailProvider(widget.chatId));

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); //点击空白处能自动收缩键盘
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 233, 231, 231),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 233, 231, 231),
          elevation: 0,
          centerTitle: true,
          //昵称
          title: Text(info?.title ?? "", style: TextStyle(fontSize: 20, color: Colors.black)),
          leading: GestureDetector(
            child: Icon(Icons.arrow_back_ios),
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed('VideoMessage');
              }
            },
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 10),
              //x详细信息
              child: GestureDetector(
                onTap: () {
                  context.pushNamed(
                    'Details',
                    pathParameters: {'detailsId': widget.chatId}, //
                    queryParameters: {'isFuren': 'true'}, //告诉详情页“我是聊天页，你等会点发信息直接 pop 就行”
                  );
                },
                child: Icon(Icons.auto_awesome_sharp),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            //消息区域
            Expanded(
              child: messageindex.when(
                data: (message) => ListView.builder(
                  reverse: true, // 【核心优化】新消息在底部，且键盘弹出时自动跟随
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                  itemCount: message.length,
                  itemBuilder: (context, index) {
                    return _MessageBubble(
                      message: message[index], // 传入消息数据
                      avatar: info?.iconUrl ?? '',
                      myAvatar: me.avatar,
                    );
                  },
                ),
                error: (err, stack) => Center(child: Text('加载失败:$err')),
                loading: () => Center(child: CircularProgressIndicator()),
              ),
            ),
            //输入区域
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      color: Color(0xffF7F7F7),
      child: SafeArea(
        child: Row(
          children: [
            //语音
            GestureDetector(
              onTap: () {
                print('点击了语音');
              },
              child: Icon(CupertinoIcons.speaker_2, size: 25),
            ),
            const SizedBox(width: 8),
            //输入框
            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 40,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.white),
                child: TextField(
                  controller: _textController,
                  onSubmitted: (value) => _handleSend(), //按回车键发送消息
                  onChanged: (value) => _handleSend, //输入内容变化时也调用发送函数，保持输入框和消息列表的同步
                  decoration: const InputDecoration(
                    border: InputBorder.none, //
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: -16), //调整光标的位置，使其垂直居中
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            //表情
            GestureDetector(
              onTap: () {
                print('点击了表情');
              },
              child: Icon(Icons.emoji_emotions_outlined, size: 28),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _handleSend,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: const Color(0xff07C160)),
                child: GestureDetector(
                  onTap: _handleSend,
                  child: Text('发送', style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//抽取气泡组件，减少主页面重绘压力
class _MessageBubble extends StatelessWidget {
  final String? avatar; //对方的头像
  final String? myAvatar; //自己的头像
  final MessageModel message;
  const _MessageBubble({required this.message, required this.avatar, required this.myAvatar});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start, //
        children: [
          if (!message.isMe) _builAvatar(avatar, isMe: false), // 对方消息显示在左侧，先显示头像
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10), //
                color: message.isMe ? Color(0xFF95EC69) : Colors.white,
              ),
              child: Text(message.content, style: TextStyle(fontSize: 16, color: Colors.black)),
            ),
          ),
          const SizedBox(width: 10),
          if (message.isMe) _builAvatar(myAvatar, isMe: true), // 自己的消息显示在右侧，最后显示头像
        ],
      ),
    );
  }

  Widget _builAvatar(String? url, {required bool isMe}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5), //
        color: Colors.transparent,
      ),
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () {
          print('点击了${isMe ? "自己的" : "对方的"}头像');
        },
        child: (url != null && url.isNotEmpty)
            ? ClipRRect(borderRadius: BorderRadius.circular(5), child: _buildAvatarImage(url))
            : Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: Colors.grey[500]),
                child: Icon(isMe ? Icons.person : Icons.face, size: 40, color: isMe ? Colors.blue : Colors.green),
              ),
      ),
    );
  }

  Widget _buildAvatarImage(String url) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => Image.asset('assets/image/002.png', width: 40, height: 40, fit: BoxFit.cover),
      );
    }
    if (url.startsWith('/')) {
      return Image.file(
        File(url),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => Image.asset('assets/image/002.png', width: 40, height: 40, fit: BoxFit.cover),
      );
    }
    return Image.asset(
      url,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      errorBuilder: (_, error, stackTrace) => Image.asset('assets/image/002.png', width: 40, height: 40, fit: BoxFit.cover),
    );
  }
}
