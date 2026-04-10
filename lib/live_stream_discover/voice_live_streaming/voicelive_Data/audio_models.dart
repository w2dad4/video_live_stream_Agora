//1. Models 层：定义基础数据结构
class VoiceChatMessage {
  final String uid;
  final String userName;
  final String content;
  const VoiceChatMessage({required this.uid, required this.userName, required this.content});
}

class VoiceSeat {
  final int index; // 1-8麦位号
  final String? uid;
  final String? name;
  final String? avatar;
  final bool allowJoin; // 谁能上麦
  final bool allowSpeak; // 谁能说话
  final bool muted; // 谁是静音
  final double volume; // 音量波动值

  const VoiceSeat({required this.index, this.uid, this.name, this.avatar, this.allowJoin = true, this.allowSpeak = true, this.muted = false, this.volume = 0});

  bool get canSpeak => uid != null && allowSpeak && !muted;

  VoiceSeat copyWith({String? uid, String? name, String? avatar, bool? allowJoin, bool? allowSpeak, bool? muted, double? volume, bool clearUser = false}) {
    return VoiceSeat(
      index: index,
      uid: clearUser ? null : (uid ?? this.uid),
      name: clearUser ? null : (name ?? this.name),
      avatar: clearUser ? null : (avatar ?? this.avatar), //
      allowJoin: allowJoin ?? this.allowJoin,
      allowSpeak: allowSpeak ?? this.allowSpeak,
      muted: muted ?? this.muted,
      volume: volume ?? this.volume,
    );
  }
}
class VoiceRoomState {
  final List<VoiceSeat> seats;
  final DateTime startAt;
  final bool musicOn;
  final bool recordingOn;

  const VoiceRoomState({required this.seats, required this.startAt, this.musicOn = false, this.recordingOn = false});

  VoiceRoomState copyWith({List<VoiceSeat>? seats, DateTime? startAt, bool? musicOn, bool? recordingOn}) {
    return VoiceRoomState(
      seats: seats ?? this.seats,
      startAt: startAt ?? this.startAt,
      musicOn: musicOn ?? this.musicOn,
      recordingOn: recordingOn ?? this.recordingOn, //
    );
  }
}
