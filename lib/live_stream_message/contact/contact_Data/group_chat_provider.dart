import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_model.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_provider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_repository.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/group_chat_model.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/group_chat_repository.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/social_local_storage.dart';
import 'package:video_live_stream/live_stream_message/message/message_Data/chat_Model.dart';
import 'package:video_live_stream/live_stream_message/message/message_Data/message_Model.dart';

final groupChatListProvider =
    AsyncNotifierProvider<GroupChatNotifier, List<GroupChatModel>>(
      GroupChatNotifier.new,
    );

final groupDetailProvider = Provider.family<GroupChatModel?, String>((ref, id) {
  final groups =
      ref.watch(groupChatListProvider).value ?? const <GroupChatModel>[];
  for (final g in groups) {
    if (g.id == id) return g;
  }
  return null;
});

class GroupChatNotifier extends AsyncNotifier<List<GroupChatModel>> {
  String _uid() {
    final me = ref.read(meProvider);
    return me?.uid?.trim().isNotEmpty == true ? me!.uid!.trim() : 'self';
  }

  @override
  FutureOr<List<GroupChatModel>> build() async {
    final repo = ref.watch(groupChatRepositoryProvider);
    return repo.fetchAll();
  }

  Future<void> refresh() async {
    final repo = ref.read(groupChatRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.fetchAll());
  }

  Future<void> ensureGroupForContact(
    ContactModel groupContact, {
    required String ownerId,
    required List<String> memberIds,
  }) async {
    final current = state.value ?? [];
    final idx = current.indexWhere((e) => e.id == groupContact.id);

    if (idx >= 0) {
      final exists = current[idx];
      final mergedMembers = <String>{
        ...exists.memberIds,
        ...memberIds,
      }.toList();
      final next = [...current];
      next[idx] = exists.copyWith(
        groupName: groupContact.title,
        memberIds: mergedMembers,
        updatedAt: DateTime.now(),
      );
      await _save(next);
      return;
    }

    final profiles = <String, GroupMemberProfile>{};
    for (final uid in memberIds) {
      profiles[uid] = GroupMemberProfile(uid: uid);
    }

    final created = GroupChatModel(
      id: groupContact.id,
      groupName: groupContact.title,
      ownerId: ownerId,
      adminIds: const [],
      memberIds: memberIds.toSet().toList(),
      memberProfiles: profiles,
      updatedAt: DateTime.now(),
    );
    await _save([created, ...current]);
  }

  Future<bool> renameGroup(String groupId, String name) async {
    final me = _uid();
    final current = state.value ?? [];
    final idx = current.indexWhere((e) => e.id == groupId);
    if (idx < 0) return false;
    final target = current[idx];
    if (!target.canEditName(me)) return false;
    if (name.trim().isEmpty) return false;

    final next = [...current];
    next[idx] = target.copyWith(
      groupName: name.trim(),
      updatedAt: DateTime.now(),
    );
    await _save(next);
    await _syncContactTitle(groupId, name.trim());
    return true;
  }

  Future<bool> updateAnnouncement(String groupId, String announcement) async {
    final me = _uid();
    final current = state.value ?? [];
    final idx = current.indexWhere((e) => e.id == groupId);
    if (idx < 0) return false;
    final target = current[idx];
    if (!target.canEditAnnouncement(me)) return false;

    final next = [...current];
    next[idx] = target.copyWith(
      announcement: announcement.trim(),
      updatedAt: DateTime.now(),
    );
    await _save(next);
    return true;
  }

  Future<void> updateMyRemark(String groupId, String remark) async {
    final me = _uid();
    final current = state.value ?? [];
    final idx = current.indexWhere((e) => e.id == groupId);
    if (idx < 0) return;
    final target = current[idx];
    final profile = target.profileOf(me).copyWith(remark: remark.trim());
    final profiles = <String, GroupMemberProfile>{
      ...target.memberProfiles,
      me: profile,
    };
    final next = [...current];
    next[idx] = target.copyWith(
      memberProfiles: profiles,
      updatedAt: DateTime.now(),
    );
    await _save(next);
  }

  Future<void> updateMyNickname(String groupId, String nickname) async {
    final me = _uid();
    final current = state.value ?? [];
    final idx = current.indexWhere((e) => e.id == groupId);
    if (idx < 0) return;
    final target = current[idx];
    final profile = target.profileOf(me).copyWith(nickname: nickname.trim());
    final profiles = <String, GroupMemberProfile>{
      ...target.memberProfiles,
      me: profile,
    };
    final next = [...current];
    next[idx] = target.copyWith(
      memberProfiles: profiles,
      updatedAt: DateTime.now(),
    );
    await _save(next);
  }

  Future<void> updateMyMute(String groupId, bool mute) async {
    final me = _uid();
    final current = state.value ?? [];
    final idx = current.indexWhere((e) => e.id == groupId);
    if (idx < 0) return;
    final target = current[idx];
    final profile = target.profileOf(me).copyWith(mute: mute);
    final profiles = <String, GroupMemberProfile>{
      ...target.memberProfiles,
      me: profile,
    };
    final next = [...current];
    next[idx] = target.copyWith(
      memberProfiles: profiles,
      updatedAt: DateTime.now(),
    );
    await _save(next);
  }

  Future<bool> toggleAdmin(String groupId, String targetUid) async {
    final me = _uid();
    final current = state.value ?? [];
    final idx = current.indexWhere((e) => e.id == groupId);
    if (idx < 0) return false;
    final target = current[idx];
    if (!target.isOwner(me)) return false;
    if (target.ownerId == targetUid) return false;

    final admins = [...target.adminIds];
    if (admins.contains(targetUid)) {
      admins.remove(targetUid);
    } else {
      if (admins.length >= 3) return false;
      admins.add(targetUid);
    }
    final next = [...current];
    next[idx] = target.copyWith(adminIds: admins, updatedAt: DateTime.now());
    await _save(next);
    return true;
  }

  Future<void> clearLocalChatRecords(String groupId) async {
    await SocialLocalStorage.clearChatMessages(groupId);
    ref.invalidate(messageProvider(groupId));
    ref.read(messageModelProvider.notifier).clearConversationPreview(groupId);
  }

  Future<void> exitAndReleaseGroup(String groupId) async {
    final current = state.value ?? [];
    final next = current.where((e) => e.id != groupId).toList();
    await _save(next);

    await SocialLocalStorage.clearChatMessages(groupId);
    ref.invalidate(messageProvider(groupId));
    ref.read(messageModelProvider.notifier).deleteConversation(groupId);

    final contacts = await ref.read(contactModelProvider).getContact();
    final filtered = contacts.where((c) => c.id != groupId).toList();
    await ref.read(contactModelProvider).replaceAll(filtered);
    ref.invalidate(contactListProvider);
  }

  bool shouldNotifyForIncoming({
    required String groupId,
    required String messageContent,
    required String myUid,
  }) {
    final group = (state.value ?? const <GroupChatModel>[])
        .where((e) => e.id == groupId)
        .firstOrNull;
    if (group == null) return true;
    final profile = group.profileOf(myUid);
    if (!profile.mute) return true;
    // 开启免打扰后，仅 @我 或 @all 时触发提醒
    return messageContent.contains('@$myUid') ||
        messageContent.contains('@all');
  }

  Future<void> _syncContactTitle(String groupId, String title) async {
    final contacts = await ref.read(contactModelProvider).getContact();
    final next = [
      for (final c in contacts)
        if (c.id == groupId)
          ContactModel(
            id: c.id,
            title: title,
            iconUrl: c.iconUrl,
            bgUrl: c.bgUrl,
            remark: c.remark,
            tag: c.tag,
          )
        else
          c,
    ];
    await ref.read(contactModelProvider).replaceAll(next);
    ref.invalidate(contactListProvider);
    final conv = ref
        .read(messageModelProvider)
        .where((e) => e.id == groupId)
        .firstOrNull;
    if (conv != null) {
      ref
          .read(messageModelProvider.notifier)
          .updateUserInfo(groupId, title, conv.avatar);
    }
  }

  Future<void> _save(List<GroupChatModel> next) async {
    state = AsyncValue.data(next);
    await ref.read(groupChatRepositoryProvider).saveAll(next);
  }
}
