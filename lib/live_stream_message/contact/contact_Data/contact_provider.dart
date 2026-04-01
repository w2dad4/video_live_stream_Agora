import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_model.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_repository.dart';

// 使用 AsyncNotifier 管理联系人列表
final contactListProvider = AsyncNotifierProvider<ContactNotifier, List<ContactModel>>(() {
  return ContactNotifier();
});

class ContactNotifier extends AsyncNotifier<List<ContactModel>> {
  @override
  FutureOr<List<ContactModel>> build() async {
    //自动关联仓库，当仓库发生变化时自动刷新
    final repo = ref.watch(contactModelProvider);
    return await repo.getContact();
  }

  //刷新联系人列表
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(contactModelProvider).getContact());
  }

  // 删除联系人
  Future<void> delete(String id) async {
    final previousState = state.value ?? [];
    state = AsyncValue.data(previousState.where((c) => c.id != id).toList());
    try {
      // await ref.read(contactRepositoryProvider).apiDelete(id);
    } catch (e) {
      state = AsyncValue.data(previousState); //失败回滚
    }
  }
}
