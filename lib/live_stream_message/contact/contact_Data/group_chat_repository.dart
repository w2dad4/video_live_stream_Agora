import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/group_chat_model.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/social_local_storage.dart';

class GroupChatRepository {
  Future<List<GroupChatModel>> fetchAll() async {
    final raw = await SocialLocalStorage.loadGroupMetaJson();
    return raw.map(GroupChatModel.fromJson).toList();
  }

  Future<void> saveAll(List<GroupChatModel> groups) async {
    final raw = groups.map((e) => e.toJson()).toList();
    await SocialLocalStorage.saveGroupMetaJson(raw);
  }
}

final groupChatRepositoryProvider = Provider((ref) => GroupChatRepository());
