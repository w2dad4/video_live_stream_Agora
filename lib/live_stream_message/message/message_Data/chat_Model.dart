import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_model.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_provider.dart';
import 'package:video_live_stream/live_stream_message/message/message_Data/chat_repository.dart';
import 'package:video_live_stream/live_stream_message/message/message_Data/message_Model.dart';

// 1. 扩展消息模型，增加状态
enum MessageStatus { sending, sent, fail }

class MessageModel {
  final String id;
  final String content;
  final MessageStatus status;
  final bool isMe;
  final DateTime timestamp;
  MessageModel({required this.id, required this.isMe, required this.timestamp, required this.content, this.status = MessageStatus.sent});
  // 提供 copyWith 方便局部更新状态
  MessageModel copyWith({MessageStatus? status, String? content}) {
    return MessageModel(id: id, isMe: isMe, timestamp: timestamp, content: content ?? this.content, status: status ?? this.status);
  }
}

// 2. Provider 定义
final messageProvider = AsyncNotifierProvider.family<MessageNotifier, List<MessageModel>, String>(MessageNotifier.new);

// 2. Provider 定义
final chatDetailProvider = Provider.family<ContactModel?, String>((ref, id) {
  // 1. 监听完整的联系人列表状态
  final contactState = ref.watch(contactListProvider);
  // 2. 从数据中检索匹配的对象
  return contactState.value?.where((c) => c.id == id).firstOrNull;
});

// 3. Notifier 类
class MessageNotifier extends AsyncNotifier<List<MessageModel>> {
  final String roomId;
  MessageNotifier(this.roomId);

  @override
  FutureOr<List<MessageModel>> build() async {
    // 灵活点：通过 repository 异步获取
    final repo = ref.watch(chatRepositoryProvider);
    return await repo.fetchMessage(roomId);
  }

  // 发送逻辑
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final repo = ref.read(chatRepositoryProvider);
    final detail = ref.read(chatDetailProvider(roomId));
    final me = ref.read(meProvider);
    final isSelf = me.uid == roomId;
    // 1. 创建唯一的消息实体（包含时间戳）
    final tempMsg = MessageModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(), //
      isMe: true,
      timestamp: DateTime.now(),
      content: text,
      status: MessageStatus.sending,
    );
    // 2. 聊天页本地立刻更新
    final previousState = state.value ?? [];
    state = AsyncValue.data([tempMsg, ...previousState]); //立刻让消息上屏
    //将会话列表也指向同一个实体
    ref
        .read(messageModelProvider.notifier)
        .updataListsMessage(
          roomId,
          tempMsg,
          title: detail?.title ?? (isSelf ? (me.name ?? '我') : '用户$roomId'), //
          avatar: detail?.iconUrl ?? (isSelf ? (me.avatar ?? 'assets/image/002.png') : 'assets/image/002.png'),
          bgUrl: detail?.bgUrl ?? 'assets/image/010.jpeg',
        );
    try {
      await repo.sendMessage(roomId, tempMsg);
      // 发送成功：更新该条消息状态为 sent
      state = AsyncValue.data(state.value!.map((m) => m.id == tempMsg.id ? m.copyWith(status: MessageStatus.sent) : m).toList());
    } catch (e) {
      // 发送失败：更新该条消息状态为 fail (修复笔误)
      state = AsyncValue.data(state.value!.map((m) => m.id == tempMsg.id ? m.copyWith(status: MessageStatus.fail) : m).toList());
    }
  }

  Future<void> clearLocalMessages() async {
    final repo = ref.read(chatRepositoryProvider);
    state = const AsyncValue.data([]);
    await repo.clearRoomMessages(roomId);
  }
}
