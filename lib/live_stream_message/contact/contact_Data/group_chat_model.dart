class GroupMemberProfile {
  final String uid;
  final String remark;
  final String nickname;
  final bool mute;

  const GroupMemberProfile({
    required this.uid,
    this.remark = '',
    this.nickname = '',
    this.mute = false,
  });

  GroupMemberProfile copyWith({String? remark, String? nickname, bool? mute}) {
    return GroupMemberProfile(
      uid: uid,
      remark: remark ?? this.remark,
      nickname: nickname ?? this.nickname,
      mute: mute ?? this.mute,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'remark': remark,
    'nickname': nickname,
    'mute': mute,
  };

  factory GroupMemberProfile.fromJson(Map<String, dynamic> j) {
    return GroupMemberProfile(
      uid: j['uid']?.toString() ?? '',
      remark: j['remark']?.toString() ?? '',
      nickname: j['nickname']?.toString() ?? '',
      mute: j['mute'] == true,
    );
  }
}

class GroupChatModel {
  final String id;
  final String groupName;
  final String ownerId; // 群主（唯一）
  final List<String> adminIds; // 管理员（最多 3 个）
  final List<String> memberIds; // 成员列表（包含群主与管理员）
  final String announcement; // 群公告（所有人可见）
  final Map<String, GroupMemberProfile> memberProfiles; // 每个成员的私有设置（备注、昵称、免打扰）
  final DateTime updatedAt;

  const GroupChatModel({
    required this.id,
    required this.groupName,
    required this.ownerId,
    required this.adminIds,
    required this.memberIds,
    this.announcement = '',
    this.memberProfiles = const {},
    required this.updatedAt,
  });

  GroupChatModel copyWith({
    String? groupName,
    String? ownerId,
    List<String>? adminIds,
    List<String>? memberIds,
    String? announcement,
    Map<String, GroupMemberProfile>? memberProfiles,
    DateTime? updatedAt,
  }) {
    return GroupChatModel(
      id: id,
      groupName: groupName ?? this.groupName,
      ownerId: ownerId ?? this.ownerId,
      adminIds: adminIds ?? this.adminIds,
      memberIds: memberIds ?? this.memberIds,
      announcement: announcement ?? this.announcement,
      memberProfiles: memberProfiles ?? this.memberProfiles,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool isOwner(String uid) => ownerId == uid;
  bool isAdmin(String uid) => adminIds.contains(uid);
  bool canEditName(String uid) => isOwner(uid) || isAdmin(uid);
  bool canEditAnnouncement(String uid) => isOwner(uid) || isAdmin(uid);
  int get memberCount => memberIds.length;

  GroupMemberProfile profileOf(String uid) {
    return memberProfiles[uid] ?? GroupMemberProfile(uid: uid);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'groupName': groupName,
    'ownerId': ownerId,
    'adminIds': adminIds,
    'memberIds': memberIds,
    'announcement': announcement,
    'memberProfiles': memberProfiles.map((k, v) => MapEntry(k, v.toJson())),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory GroupChatModel.fromJson(Map<String, dynamic> j) {
    final rawProfiles = j['memberProfiles'];
    final map = <String, GroupMemberProfile>{};
    if (rawProfiles is Map) {
      rawProfiles.forEach((key, value) {
        map[key.toString()] = GroupMemberProfile.fromJson(
          Map<String, dynamic>.from(value as Map),
        );
      });
    }
    return GroupChatModel(
      id: j['id']?.toString() ?? '',
      groupName: j['groupName']?.toString() ?? '未命名群聊',
      ownerId: j['ownerId']?.toString() ?? '',
      adminIds: (j['adminIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      memberIds: (j['memberIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      announcement: j['announcement']?.toString() ?? '',
      memberProfiles: map,
      updatedAt:
          DateTime.tryParse(j['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
