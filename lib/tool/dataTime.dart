import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// 1. 确保模型中使用 DateTime
class ChatConversation {
  final String id;
  final String title;
  final String lastMessage;
  final String avatar;
  final DateTime createdAt; // 时间锁定在这里

  ChatConversation({
    required this.id,
    required this.title, //
    required this.lastMessage,
    required this.createdAt,
    required this.avatar,
  });
}

// 2. 使用 StateNotifier 管理列表，模拟消息到达
class ConversationNotifier extends StateNotifier<List<ChatConversation>> {
  ConversationNotifier()
    : super([
        // 初始化时时间就已固定
        ChatConversation(
          id: '1',
          title: '张三',
          avatar: 'assets/image/004.jpeg',
          lastMessage: '今天一起吃饭吗？',
          createdAt: DateTime(2026, 3, 9, 19, 18), // 锁定在 19:18
        ),
        ChatConversation(
          id: '2',
          title: 'Flutter 交流群',
          lastMessage: 'Gemini: Riverpod 性能真棒！', //
          avatar: 'assets/image/005.jpeg',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ]);

  // 当有新信息来临时调用此方法
  void receiveNewMessage(String msg) {
    state = [
      ChatConversation(
        id: '1', // 假设还是张三发来的
        title: '张三',
        lastMessage: msg,
        createdAt: DateTime.now(),
        avatar: 'assets/image/004.jpeg', // 只有新消息来时，才取当前时间并锁定
      ),
      ...state.where((e) => e.id != '1'), // 将旧的张三记录移除或更新
    ];
  }
}

final conversationProvider =
    StateNotifierProvider<ConversationNotifier, List<ChatConversation>>((ref) {
      return ConversationNotifier();
    });
final chatDetailProvider = Provider.family<ChatConversation?, String>((
  ref,
  id,
) {
  // 关键：实时监听总列表
  final allList = ref.watch(conversationProvider);
  // 找到对应的那个会话
  try {
    return allList.firstWhere((element) => element.id == id);
  } catch (_) {
    return null; // 找不到则返回 null
  }
});

extension DatatimeX on DateTime {
  String _totime() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String toCanvaerstionTime() {
    final now = DateTime.now();
    // 获取各级时间基准（凌晨0点）
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dataToCheck = DateTime(year, month, day);
    if (dataToCheck == today) {
      return _totime();
    } else if (dataToCheck == yesterday) {
      return '昨天${_totime()}';
    } else if (now.year == year) {
      return '$month月$day日';
    } else {
      return '$year年$month月$day日';
    }
  }
}

//格式化时间格式
String formatDuration(int totalSencode) {
  final hours = totalSencode ~/ 3600;
  final minutes = (totalSencode % 3600) ~/ 60;
  final sencode = totalSencode % 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${sencode.toString().padLeft(2, '0')}';
}


