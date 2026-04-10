import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/social_local_storage.dart';

/// 群聊已读状态：key=groupId，value=最后已读时间
final groupReadProvider =
    AsyncNotifierProvider<GroupReadNotifier, Map<String, DateTime>>(
      GroupReadNotifier.new,
    );

class GroupReadNotifier extends AsyncNotifier<Map<String, DateTime>> {
  @override
  FutureOr<Map<String, DateTime>> build() async {
    final raw = await SocialLocalStorage.loadGroupReadState();
    return _parse(raw);
  }

  Future<void> markGroupAsRead(String groupId) async {
    final current = state.value ?? <String, DateTime>{};
    final next = <String, DateTime>{...current, groupId: DateTime.now()};
    state = AsyncValue.data(next);
    await _save(next);
  }

  DateTime? lastReadAt(String groupId) {
    return state.value?[groupId];
  }

  Map<String, DateTime> _parse(Map<String, String> raw) {
    final out = <String, DateTime>{};
    raw.forEach((key, value) {
      final dt = DateTime.tryParse(value);
      if (dt != null) out[key] = dt;
    });
    return out;
  }

  Future<void> _save(Map<String, DateTime> data) async {
    final raw = data.map((k, v) => MapEntry(k, v.toIso8601String()));
    await SocialLocalStorage.saveGroupReadState(raw);
  }
}
