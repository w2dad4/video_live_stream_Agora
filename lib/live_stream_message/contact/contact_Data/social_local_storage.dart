import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_model.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/friend_social_models.dart';

/// 联系人、好友申请、面对面房间码、聊天消息的本地持久化（SharedPreferences）
class SocialLocalStorage {
  SocialLocalStorage._();
  static const _contactsKey = 'social_contacts_v1';
  static const _requestsKey = 'social_friend_requests_v1';
  static const _f2fPrefix = 'f2f_room_v1_';
  static const _chatPrefix = 'chat_messages_v1_';
  static const _groupMetaKey = 'group_meta_v1';
  static const _groupReadStateKey = 'group_read_state_v1';

  static Future<List<ContactModel>> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_contactsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ContactModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> saveContacts(List<ContactModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(list.map((c) => _contactToJson(c)).toList());
    await prefs.setString(_contactsKey, raw);
  }

  static Map<String, dynamic> _contactToJson(ContactModel c) => {
    'id': c.id,
    'title': c.title,
    'icon': c.iconUrl,
    'bgUrl': c.bgUrl,
    'remark': c.remark,
    'tag': c.tag,
  };

  static Future<List<FriendRequestModel>> loadFriendRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_requestsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map(
          (e) =>
              FriendRequestModel.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  static Future<void> saveFriendRequests(List<FriendRequestModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(list.map((r) => r.toJson()).toList());
    await prefs.setString(_requestsKey, raw);
  }

  /// 面对面建群：6 位数字 -> 群聊 id
  static Future<String?> getFaceToFaceGroupId(String sixDigits) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_f2fPrefix$sixDigits');
  }

  static Future<void> setFaceToFaceRoom(
    String sixDigits,
    String groupId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_f2fPrefix$sixDigits', groupId);
  }

  static Future<List<Map<String, dynamic>>> loadChatMessagesJson(
    String chatId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_chatPrefix$chatId');
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> saveChatMessagesJson(
    String chatId,
    List<Map<String, dynamic>> list,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_chatPrefix$chatId', jsonEncode(list));
  }

  static Future<void> clearChatMessages(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_chatPrefix$chatId');
  }

  static Future<List<Map<String, dynamic>>> loadGroupMetaJson() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_groupMetaKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> saveGroupMetaJson(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_groupMetaKey, jsonEncode(list));
  }

  static Future<Map<String, String>> loadGroupReadState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_groupReadStateKey);
    if (raw == null || raw.isEmpty) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((key, value) => MapEntry(key, value?.toString() ?? ''));
  }

  static Future<void> saveGroupReadState(Map<String, String> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_groupReadStateKey, jsonEncode(map));
  }
}
