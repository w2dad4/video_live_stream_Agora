import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:video_live_stream/library.dart';

// 语音房间状态：1-8 麦位、上麦权限、发言权限、静音、音量动画、房间设置
final voiceRoomProvider = StateNotifierProvider.family<VoiceRoomNotifier, VoiceRoomState, String>((ref, roomId) => VoiceRoomNotifier(ref, roomId));
// 语音房聊天消息（房间维度）
final voiceChatProvider = StateProvider.family<List<VoiceChatMessage>, String>(
  (ref, roomId) => const [VoiceChatMessage(uid: 'sync', userName: '系统提示', content: '欢迎来到语音直播间，请文明发言')], //
);

class VoiceRoomNotifier extends StateNotifier<VoiceRoomState> {
  VoiceRoomNotifier(this.ref, this.roomId)
    : super(
        VoiceRoomState(
          seats: List.generate(8, (i) => VoiceSeat(index: i + 1)),
          startAt: DateTime.now(),
        ),
      ) {
    _startVolumeTicker();
  }

  final Ref ref;
  final String roomId;
  Timer? _timer;
  final Random _random = Random();

  void initRoom({required String hostId, required String hostName, required String hostAvatar}) {
    final current = [...state.seats];
    current[0] = current[0].copyWith(uid: hostId, name: hostName, avatar: hostAvatar, allowJoin: false, allowSpeak: true, muted: false);
    state = state.copyWith(seats: current);
  }

  void toggleMute(int seatIndex) {
    final current = [...state.seats];
    final idx = current.indexWhere((s) => s.index == seatIndex);
    if (idx < 0) return;
    if (current[idx].uid == null) return;
    current[idx] = current[idx].copyWith(muted: !current[idx].muted);
    state = state.copyWith(seats: current);
  }

  // 指定设置某个麦位的禁言状态（用于禁言名单管理页）
  void setMuted(int seatIndex, bool muted) {
    final current = [...state.seats];
    final idx = current.indexWhere((s) => s.index == seatIndex);
    if (idx < 0) return;
    if (current[idx].uid == null) return;
    current[idx] = current[idx].copyWith(muted: muted);
    state = state.copyWith(seats: current);
  }

  void toggleSelfMute({required String uid}) {
    final current = [...state.seats];
    final idx = current.indexWhere((s) => s.uid == uid);
    if (idx < 0) return;
    current[idx] = current[idx].copyWith(muted: !current[idx].muted);
    state = state.copyWith(seats: current);
  }

  void setAllowJoin(int seatIndex, bool allowJoin) {
    if (seatIndex == 1) return;
    final current = [...state.seats];
    final idx = current.indexWhere((s) => s.index == seatIndex);
    if (idx < 0) return;
    current[idx] = current[idx].copyWith(allowJoin: allowJoin);
    state = state.copyWith(seats: current);
  }

  void kickFromMic(int seatIndex) {
    if (seatIndex == 1) return;
    final current = [...state.seats];
    final idx = current.indexWhere((s) => s.index == seatIndex);
    if (idx < 0) return;
    current[idx] = current[idx].copyWith(clearUser: true, muted: false, volume: 0);
    state = state.copyWith(seats: current);
  }

  void leaveMic(String uid) {
    final current = [...state.seats];
    final idx = current.indexWhere((s) => s.uid == uid);
    if (idx < 0) return;
    if (current[idx].index == 1) return;
    current[idx] = current[idx].copyWith(clearUser: true, muted: false, volume: 0);
    state = state.copyWith(seats: current);
  }

  void setMusic(bool value) {
    state = state.copyWith(musicOn: value);
  }

  void setRecording(bool value) {
    state = state.copyWith(recordingOn: value);
  }

  void _startVolumeTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 260), (_) {
      final next = [
        for (final s in state.seats)
          if (s.canSpeak) s.copyWith(volume: 0.25 + _random.nextDouble() * 0.75) else s.copyWith(volume: 0),
      ];
      state = state.copyWith(seats: next);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
// class VoiceRoomNotifier extends StateNotifier<VoiceRoomState> {
//   VoiceRoomNotifier(this.ref, this.roomId)
//     : super(
//         VoiceRoomState(
//           seats: List.generate(8, (i) => VoiceSeat(index: i + 1)),
//           startAt: DateTime.now(),
//         ),
//       ) {
//     _startVolumeTicker();
//   }

//   final Ref ref;
//   final String roomId;
//   Timer? _timer;
//   final Random _random = Random();

//   void initRoom({required String hostId, required String hostName, required String hostAvatar}) {
//     final current = [...state.seats];
//     current[0] = current[0].copyWith(uid: hostId, name: hostName, avatar: hostAvatar, allowJoin: false);
//     state = state.copyWith(seats: current);
//   }

//   // 麦位控制方法 (toggleMute, kickFromMic, leaveMic 等保持原逻辑...)
//   void setMusic(bool value) => state = state.copyWith(musicOn: value);
//   void setRecording(bool value) => state = state.copyWith(recordingOn: value);

//   void _startVolumeTicker() {
//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(milliseconds: 260), (_) {
//       final next = [for (final s in state.seats) s.canSpeak ? s.copyWith(volume: 0.25 + _random.nextDouble() * 0.75) : s.copyWith(volume: 0)];
//       state = state.copyWith(seats: next);
//     });
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }
// }
