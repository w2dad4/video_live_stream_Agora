import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncValue, Ref;
import 'package:flutter_riverpod/legacy.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_model.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_provider.dart';
import 'package:video_live_stream/live_stream_message/message/message_Data/chat_Model.dart';

//用于更新发送时间和信息
//会话列表provider,
final messageModelProvider =
    StateNotifierProvider<MessageModelNotifier, List<ChatConversation>>((ref) {
      final notifier = MessageModelNotifier(ref);
      ref.listen<UserMe>(meProvider, (previous, next) {
        notifier.syncSelfConversation(next);
      });
      ref.listen<AsyncValue<List<ContactModel>>>(contactListProvider, (
        previous,
        next,
      ) {
        final contacts = next.value;
        if (contacts != null) {
          notifier.syncConversationProfiles(contacts);
        }
      });
      return notifier;
    });

class ChatConversation {
  final String id;
  final String title;
  final String avatar;
  final String bgUrl;
  final String lastMessage; //仅存在最后一条数据
  final DateTime createdAt; //最后发送信息的时间
  ChatConversation({
    required this.title,
    required this.avatar,
    required this.id, //
    required this.lastMessage,
    required this.createdAt,
    this.bgUrl = 'assets/image/010.jpeg',
  });
  ChatConversation copyWith({
    String? title,
    String? avatar,
    String? bgUrl,
    String? lastMessage, //
    DateTime? createdAt,
  }) {
    return ChatConversation(
      id: id,
      title: title ?? this.title,
      avatar: avatar ?? this.avatar, //
      bgUrl: bgUrl ?? this.bgUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class MessageModelNotifier extends StateNotifier<List<ChatConversation>> {
  MessageModelNotifier(this.ref) : super([]) {
    _bootstrapSelfConversation();
  }

  final Ref ref;

  void _bootstrapSelfConversation() {
    final me = ref.read(meProvider);
    final uid = me.uid?.trim().isNotEmpty == true ? me.uid!.trim() : 'self';
    final title = (me.name?.trim().isNotEmpty == true)
        ? me.name!.trim()
        : '我'; //
    final avatar = (me.avatar?.trim().isNotEmpty == true)
        ? me.avatar!.trim()
        : 'assets/image/002.png';
    state = [
      ChatConversation(
        id: uid,
        title: title,
        avatar: avatar,
        bgUrl: 'assets/image/010.jpeg',
        lastMessage: '这是你自己',
        createdAt: DateTime(2026, 1, 1, 0, 0),
      ),
      ...state.where((e) => e.id != uid),
    ];
  }

  void syncSelfConversation(UserMe me) {
    final uid = me.uid?.trim().isNotEmpty == true ? me.uid!.trim() : 'self';
    final title = (me.name?.trim().isNotEmpty == true)
        ? me.name!.trim()
        : '我'; //
    final avatar = (me.avatar?.trim().isNotEmpty == true)
        ? me.avatar!.trim()
        : 'assets/image/002.png';

    final idx = state.indexWhere((e) => e.id == uid);
    if (idx >= 0) {
      final updated = [...state];
      updated[idx] = updated[idx].copyWith(title: title, avatar: avatar); //
      state = updated;
      return;
    }
    state = [
      ChatConversation(
        id: uid,
        title: title,
        avatar: avatar,
        bgUrl: 'assets/image/010.jpeg', //
        lastMessage: '这是你自己',
        createdAt: DateTime(2026, 1, 1, 0, 0),
      ),
      ...state,
    ];
  }

  void syncConversationProfiles(List<ContactModel> contacts) {
    if (contacts.isEmpty || state.isEmpty) return;
    final contactMap = {for (final c in contacts) c.id: c};
    state = [
      for (final conv in state)
        if (contactMap.containsKey(conv.id)) //
          conv.copyWith(
            title: contactMap[conv.id]!.title,
            avatar: contactMap[conv.id]!.iconUrl,
            bgUrl: contactMap[conv.id]!.bgUrl,
          )
        else
          conv,
    ];
  }

  ({String title, String avatar, String bgUrl}) _resolveProfile(String chatId) {
    final contacts =
        ref.read(contactListProvider).value ?? const <ContactModel>[];
    for (final c in contacts) {
      if (c.id == chatId) {
        return (title: c.title, avatar: c.iconUrl, bgUrl: c.bgUrl); //
      }
    }
    final me = ref.read(meProvider);
    if (me.uid == chatId) {
      return (
        title: me.name?.isNotEmpty == true ? me.name! : '我', //
        avatar: me.avatar?.isNotEmpty == true
            ? me.avatar!
            : 'assets/image/002.png',
        bgUrl: 'assets/image/010.jpeg',
      );
    }
    return (
      title: '用户$chatId',
      avatar: 'assets/image/002.png',
      bgUrl: 'assets/image/010.jpeg', //
    );
  }

  //当聊天输入页面有了新消息时，那么就会更新聊天预览页面
  void updataListsMessage(
    String chatId,
    MessageModel latestMsg, {
    String? title,
    String? avatar,
    String? bgUrl,
  }) {
    final idx = state.indexWhere((conv) => conv.id == chatId);
    if (idx >= 0) {
      final updated = [...state];
      updated[idx] = updated[idx].copyWith(
        title: title,
        avatar: avatar,
        bgUrl: bgUrl, //
        lastMessage: latestMsg.content,
        createdAt: latestMsg.timestamp,
      );
      updated.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = updated;
      return;
    }

    final fallback = _resolveProfile(chatId);
    final newItem = ChatConversation(
      id: chatId,
      title: title ?? fallback.title,
      avatar: avatar ?? fallback.avatar,
      bgUrl: bgUrl ?? fallback.bgUrl,
      lastMessage: latestMsg.content,
      createdAt: latestMsg.timestamp, //
    );
    final sorted = <ChatConversation>[newItem, ...state];
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = sorted;
  }

  //当用户换了头像以及名称,
  void updateUserInfo(String chatIds, String newTitle, String newAvatar) {
    state = [
      for (final conv in state)
        if (conv.id == chatIds)
          conv.copyWith(title: newTitle, avatar: newAvatar) //
        else
          conv,
    ];
  }

  //删除聊天记录逻辑
  void deleteConversation(String chatId) {
    state = [
      for (final conv in state)
        if (conv.id != chatId) conv,
    ];
  }

  // 仅清空会话预览文案，不删除会话本身
  void clearConversationPreview(String chatId) {
    state = [
      for (final conv in state)
        if (conv.id == chatId) conv.copyWith(lastMessage: '') else conv,
    ];
  }
}
