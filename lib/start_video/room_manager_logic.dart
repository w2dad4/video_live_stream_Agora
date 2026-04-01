import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:flutter_riverpod/legacy.dart';
import 'package:video_live_stream/start_video/start_video_mian.dart';

//1, 存储被禁言用户的 UID 集合
final mutedUsersProvider = StateProvider<Set<String>>((ref) => {});
// 2. 房管名单 (存储被设为管理员的用户 UID)
final roomAdminsProvider = StateProvider<Set<String>>((ref) => {});
// 3. 踢出名单 (临时黑名单，存储被踢出的用户 UID)
final kickedUsersProvider = StateProvider<Set<String>>((ref) => {});
// 4. 权限校验 Provider：判断当前用户是否具备管理权限 (主播或房管)
final canManageProvider = Provider<bool>((ref) {
  return true;
});
//5. 定义一个全局清屏模式，用户通过右滑隐藏所有 UI 元素，以获得沉浸式的观看体验。
final isCleanModeProvider = StateProvider<bool>((ref) => false);
//6. 录播
final isRecordingProvider = StateProvider<bool>((ref) => false);
//7.直播时长
final isLiveduration = StateProvider<bool>((ref) => false);
//8. 记录主播的直播时长
final liveSecondsProvider = StateProvider<int>((ref) => 0);
//9. 定义一个消息对话模型
final chatmessageProvider = StateProvider<List<ChatsMessage>>((ref) => [ChatsMessage(userName: '系统提示', content: '欢迎来到直播间，请文明发言', uid: 'sync')]);
