import 'package:flutter_riverpod/legacy.dart';
import 'package:video_live_stream/live_stream_message/message/message_Data/chat_Model.dart';

//用于更新发送时间和信息
//会话列表provider,
final messageModelProvider = StateNotifierProvider<MessageModelNotifier, List<ChatConversation>>((ref) {
  return MessageModelNotifier();
});

class ChatConversation {
  final String id;
  final String title;
  final String avatar;
  final String lastMessage; //仅存在最后一条数据
  final DateTime createdAt; //最后发送信息的时间
  ChatConversation({required this.title, required this.avatar, required this.id, required this.lastMessage, required this.createdAt});
  ChatConversation copyWith({String? title, String? avatar, String? lastMessage, DateTime? createdAt}) {
    return ChatConversation(
      id: id,
      title: title ?? this.title,
      avatar: avatar ?? this.avatar, //
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class MessageModelNotifier extends StateNotifier<List<ChatConversation>> {
  MessageModelNotifier() : super([]);
  //当聊天输入页面有了新消息时，那么就会更新聊天预览页面
  void updataListsMessage(String chatId, MessageModel latestMsg) {
    state = [
      for (final conv in state)
        if (conv.id == chatId)
          conv.copyWith(
            lastMessage: latestMsg.content, //副标题
            createdAt: latestMsg.timestamp, //时间戳
          )
        else
          conv,
    ];
    state.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = [...state];
  }

  //当用户换了头像以及名称,
  void updateUserInfo(String chatIds, String newTitle, String newAvatar) {
    state = [
      for (final conv in state)
        if (conv.id == chatIds) conv.copyWith(title: newTitle, avatar: newAvatar),
    ];
  }
}
