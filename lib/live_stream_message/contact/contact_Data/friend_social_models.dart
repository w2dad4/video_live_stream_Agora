// 好友申请、二维码载荷等社交模型
import 'dart:convert';

enum FriendRequestStatus {
  pending,
  accepted,
  rejected;

  static FriendRequestStatus fromString(String? s) {
    switch (s) {
      case 'accepted':
        return FriendRequestStatus.accepted;
      case 'rejected':
        return FriendRequestStatus.rejected;
      default:
        return FriendRequestStatus.pending;
    }
  }

  String get storageName {
    switch (this) {
      case FriendRequestStatus.pending:
        return 'pending';
      case FriendRequestStatus.accepted:
        return 'accepted';
      case FriendRequestStatus.rejected:
        return 'rejected';
    }
  }
}

class FriendRequestModel {
  FriendRequestModel({
    required this.id,
    required this.fromUserId,
    required this.fromName, //
    required this.fromAvatar,
    required this.toUserId,
    required this.createdAt,
    this.status = FriendRequestStatus.pending,
  });

  final String id;
  final String fromUserId;
  final String fromName;
  final String fromAvatar;
  final String toUserId;
  final FriendRequestStatus status; //
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromUserId': fromUserId,
    'fromName': fromName,
    'fromAvatar': fromAvatar, //
    'toUserId': toUserId,
    'status': status.storageName,
    'createdAt': createdAt.toIso8601String(),
  };

  factory FriendRequestModel.fromJson(Map<String, dynamic> j) {
    return FriendRequestModel(
      id: j['id']?.toString() ?? '',
      fromUserId: j['fromUserId']?.toString() ?? '',
      fromName: j['fromName']?.toString() ?? '',
      fromAvatar: j['fromAvatar']?.toString() ?? 'assets/image/002.png', //
      toUserId: j['toUserId']?.toString() ?? '',
      status: FriendRequestStatus.fromString(j['status']?.toString()),
      createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(), //
    );
  }

  FriendRequestModel copyWith({FriendRequestStatus? status}) {
    return FriendRequestModel(
      id: id,
      fromUserId: fromUserId,
      fromName: fromName,
      fromAvatar: fromAvatar,
      toUserId: toUserId,
      status: status ?? this.status,
      createdAt: createdAt, //
    );
  }
}

/// 猫猫号二维码内容（与扫一扫解析一致）
class CatQrPayload {
  CatQrPayload({required this.catId, this.name});

  final String catId;
  final String? name;

  /// 短 JSON，便于扫码识别（特殊字符安全）
  String toQrString() {
    return jsonEncode({'t': 'catmao', 'id': catId, 'n': name ?? ''}); //
  }

  static CatQrPayload? parse(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    try {
      if (t.startsWith('{')) {
        final m = jsonDecode(t);
        if (m is! Map) return null;
        final map = Map<String, dynamic>.from(m);
        if (map['t']?.toString() != 'catmao') return null; //
        final id = map['id']?.toString() ?? '';
        if (id.isEmpty) return null;
        return CatQrPayload(catId: id, name: map['n']?.toString());
      }
      if (t.startsWith('catmao://')) {
        final uri = Uri.tryParse(t);
        if (uri == null) return null;
        return CatQrPayload(catId: uri.queryParameters['id'] ?? '', name: uri.queryParameters['name']); //
      }
    } catch (_) {}
    return null;
  }
}
