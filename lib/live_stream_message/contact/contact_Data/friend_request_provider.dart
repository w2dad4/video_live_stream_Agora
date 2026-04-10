import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_model.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_provider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_repository.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/friend_social_models.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/social_local_storage.dart';
//添加好友
final friendRequestListProvider =
    AsyncNotifierProvider<FriendRequestNotifier, List<FriendRequestModel>>(FriendRequestNotifier.new);

class FriendRequestNotifier extends AsyncNotifier<List<FriendRequestModel>> {
  @override
  Future<List<FriendRequestModel>> build() async {
    return SocialLocalStorage.loadFriendRequests();
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await SocialLocalStorage.loadFriendRequests());
  }

  /// 发起申请（需对方在「新的朋友」里同意）
  Future<String?> sendRequestToCatId({
    required String targetCatId,
    required String targetName,
    required String targetAvatar,
  }) async {
    final me = ref.read(meProvider);
    final myId = me.uid?.trim() ?? 'self';
    if (targetCatId.trim().isEmpty) return '猫猫号不能为空';
    if (targetCatId.trim() == myId) return '不能添加自己';

    final all = await SocialLocalStorage.loadFriendRequests();
    final contacts = await ref.read(contactModelProvider).getContact();
    if (contacts.any((c) => c.id == targetCatId.trim())) {
      return '对方已在联系人中';
    }
    if (all.any(
      (r) =>
          r.fromUserId == myId &&
          r.toUserId == targetCatId.trim() &&
          r.status == FriendRequestStatus.pending,
    )) {
      return '已发送过申请，请等待对方同意';
    }

    final req = FriendRequestModel(
      id: 'fr_${DateTime.now().microsecondsSinceEpoch}',
      fromUserId: myId,
      fromName: me.name ?? '我',
      fromAvatar: me.avatar ?? 'assets/image/002.png',
      toUserId: targetCatId.trim(),
      createdAt: DateTime.now(),
    );
    all.add(req);
    await SocialLocalStorage.saveFriendRequests(all);
    await reload();
    ref.invalidate(contactListProvider);
    return null;
  }

  Future<void> accept(String requestId) async {
    final me = ref.read(meProvider);
    final myId = me.uid?.trim() ?? 'self';
    final all = await SocialLocalStorage.loadFriendRequests();
    final idx = all.indexWhere((r) => r.id == requestId);
    if (idx < 0) return;
    final r = all[idx];
    if (r.toUserId != myId || r.status != FriendRequestStatus.pending) return;

    all[idx] = r.copyWith(status: FriendRequestStatus.accepted);
    await SocialLocalStorage.saveFriendRequests(all);

    final newContact = ContactModel(
      id: r.fromUserId,
      title: r.fromName,
      iconUrl: r.fromAvatar,
      bgUrl: 'assets/image/010.jpeg',
      tag: '朋友',
    );
    await ref.read(contactModelProvider).addContact(newContact);

    await reload();
    ref.invalidate(contactListProvider);
  }

  Future<void> reject(String requestId) async {
    final me = ref.read(meProvider);
    final myId = me.uid?.trim() ?? 'self';
    final all = await SocialLocalStorage.loadFriendRequests();
    final idx = all.indexWhere((r) => r.id == requestId);
    if (idx < 0) return;
    final r = all[idx];
    if (r.toUserId != myId || r.status != FriendRequestStatus.pending) return;
    all[idx] = r.copyWith(status: FriendRequestStatus.rejected);
    await SocialLocalStorage.saveFriendRequests(all);
    await reload();
  }
}

/// 发给我的待处理申请
final incomingFriendRequestsProvider = Provider<List<FriendRequestModel>>((ref) {
  final me = ref.watch(meProvider);
  final myId = me.uid?.trim() ?? 'self';
  final async = ref.watch(friendRequestListProvider);
  return async.maybeWhen(
    data: (list) => list
        .where((r) => r.toUserId == myId && r.status == FriendRequestStatus.pending)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    orElse: () => [],
  );
});

/// 我发出的待处理申请
final outgoingPendingProvider = Provider<List<FriendRequestModel>>((ref) {
  final me = ref.watch(meProvider);
  final myId = me.uid?.trim() ?? 'self';
  final async = ref.watch(friendRequestListProvider);
  return async.maybeWhen(
    data: (list) => list
        .where((r) => r.fromUserId == myId && r.status == FriendRequestStatus.pending)
        .toList(),
    orElse: () => [],
  );
});
