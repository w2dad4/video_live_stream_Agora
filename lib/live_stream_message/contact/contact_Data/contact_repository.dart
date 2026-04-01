//处理异步获取联系人的逻辑
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_model.dart';

class ContactRepository {
  // 模拟从后端或本地数据库获取联系人

  Future<List<ContactModel>> getContact() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      ContactModel(id: '1', title: '张三', iconUrl: 'assets/image/004.jpeg', bgUrl: 'assets/image/002.png', tag: '朋友'),
      ContactModel(id: '2', title: '李四', iconUrl: 'assets/image/005.jpeg', bgUrl: 'assets/image/006.png', tag: '朋友'), //
      ContactModel(id: '3', title: 'Flutter 交流群', iconUrl: 'assets/image/007.jpeg', bgUrl: 'assets/image/006.png', tag: '群聊'),
      ContactModel(id: '4', title: '原则', iconUrl: 'assets/image/009.jpeg', bgUrl: 'assets/image/010.jpeg', tag: '朋友'),
    ];
  }

  //搜索联系人逻辑
  Future<List<ContactModel>> searchContacts(String query) async {
    final all = await getContact();
    return all.where((c) => c.title.contains(query)).toList();
  }
}

//暴露仓库provider
final contactModelProvider = Provider((ref) => ContactRepository());
