// 联系人：本地持久化 + 默认演示数据
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_model.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/social_local_storage.dart';

class ContactRepository {
  static final List<ContactModel> _seed = [
    
    ContactModel(id: '1', title: '张三', iconUrl: 'assets/image/004.jpeg', bgUrl: 'assets/image/002.png', tag: '朋友'),
    ContactModel(id: '2', title: '李四', iconUrl: 'assets/image/005.jpeg', bgUrl: 'assets/image/006.png', tag: '朋友'),
    ContactModel(id: '3', title: 'Flutter 交流群', iconUrl: 'assets/image/007.jpeg', bgUrl: 'assets/image/006.png', tag: '群聊'), //
    ContactModel(id: '4', title: '原则', iconUrl: 'assets/image/009.jpeg', bgUrl: 'assets/image/010.jpeg', tag: '朋友'),
  ];

  Future<List<ContactModel>> getContact() async {
    final saved = await SocialLocalStorage.loadContacts();
    if (saved.isNotEmpty) return saved;
    await SocialLocalStorage.saveContacts(List.from(_seed));
    return List.from(_seed);
  }

  Future<void> addContact(ContactModel c) async {
    final all = await getContact();
    if (all.any((x) => x.id == c.id)) return;
    all.add(c);
    await SocialLocalStorage.saveContacts(all);
  }

  Future<void> replaceAll(List<ContactModel> list) async {
    await SocialLocalStorage.saveContacts(list);
  }

  Future<List<ContactModel>> searchContacts(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final all = await getContact();
    return all.where((c) => c.title.contains(q) || c.id.contains(q)).toList();
  }
}

final contactModelProvider = Provider((ref) => ContactRepository());
