import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_model.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_repository.dart';

// 使用 AsyncNotifier 管理联系人列表
final contactListProvider =
    AsyncNotifierProvider<ContactNotifier, List<ContactModel>>(() {
      return ContactNotifier();
    });

class ContactNotifier extends AsyncNotifier<List<ContactModel>> {
  @override
  FutureOr<List<ContactModel>> build() async {
    //自动关联仓库，当仓库发生变化时自动刷新
    final me = ref.watch(meProvider);
    final repo = ref.watch(contactModelProvider);
    final contacts = await repo.getContact();
    return _withSelfContact(contacts, me);
  }

  //刷新联系人列表
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final contacts = await ref.read(contactModelProvider).getContact();
      final me = ref.read(meProvider);
      return _withSelfContact(contacts, me);
    });
  }

  // 删除联系人（持久化中同步删除，不含「自己」）
  Future<void> delete(String id) async {
    final myId = ref.read(meProvider)?.uid ?? '';
    if (id == myId) {
      return;
    }
    final previousState = state.value ?? [];
    final nextUi = previousState.where((c) => c.id != id).toList();
    state = AsyncValue.data(nextUi);
    try {
      final toSave = nextUi.where((c) => c.tag != '自己').toList();
      await ref.read(contactModelProvider).replaceAll(toSave);
    } catch (e) {
      state = AsyncValue.data(previousState);
    }
  }

  List<ContactModel> _withSelfContact(List<ContactModel> contacts, UserMe? me) {
    if (me == null) return contacts;
    final myId = me.uid?.trim().isNotEmpty == true ? me.uid!.trim() : 'self';
    final selfContact = ContactModel(
      id: myId,
      title: me.name?.trim().isNotEmpty == true ? me.name!.trim() : '我',
      iconUrl: me.avatar?.trim().isNotEmpty == true
          ? me.avatar!.trim()
          : 'assets/image/002.png',
      bgUrl: 'assets/image/010.jpeg',
      tag: '自己',
    );

    final others = contacts.where((c) => c.id != myId).toList();
    return [selfContact, ...others];
  }
}
