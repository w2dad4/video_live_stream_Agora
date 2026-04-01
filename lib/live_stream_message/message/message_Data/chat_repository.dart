// 抽象接口，方便后续做单元测试或更换实现
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_live_stream/live_stream_message/message/message_Data/chat_Model.dart';

class ChatRepository {
  //模拟从数据库或服务器中获取历史数据
  Future<List<MessageModel>> fetchMessage(String chatID) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    // 这里未来可以替换为 Dio 请求或 Room/Isar 数据库查询
    return [MessageModel(id: '1', isMe: false, timestamp: DateTime.now().subtract(const Duration(days: 1)), content: '历史信息')];
  }

  //模拟发送信息
  Future<bool> sendMessage(String chatID, MessageModel message) async {
    await Future.delayed(const Duration(microseconds: 300));
    return true;
  }
}

final chatRepositoryProvider = Provider((ref) => ChatRepository());
