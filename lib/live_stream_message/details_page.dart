import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_model.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_provider.dart';
import 'package:video_live_stream/live_stream_message/message/message_Data/chat_Model.dart';

//这是聊天用户信息
class DetailsPage extends ConsumerWidget {
  final String detailsId;
  final bool isFuren;
  final String? initialTitle;
  final String? initialAvatar;
  final String? initialBgUrl;

  const DetailsPage({super.key, required this.detailsId, this.isFuren = false, this.initialTitle, this.initialAvatar, this.initialBgUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 利用 Riverpod 的 AsyncValue 处理状态
    final contactAsync = ref.watch(contactListProvider);
    final me = ref.watch(meProvider);

    return contactAsync.when(
      data: (contacts) {
        ContactModel? targetContact;
        // 2. 优先使用路由传参（避免跨页数据不同步）
        if ((initialTitle?.isNotEmpty ?? false) || (initialAvatar?.isNotEmpty ?? false) || (initialBgUrl?.isNotEmpty ?? false)) {
          targetContact = ContactModel(
            id: detailsId,
            title: initialTitle?.isNotEmpty == true ? initialTitle! : '未知用户', //
            iconUrl: initialAvatar ?? '',
            bgUrl: initialBgUrl ?? 'assets/image/010.jpeg',
          );
        }
        // 3. 再用联系人列表兜底
        targetContact ??= contacts.where((c) => c.id == detailsId).firstOrNull;
        // 4. 再从聊天详情 Provider 兜底
        targetContact ??= ref.watch(chatDetailProvider(detailsId));
        // 5. 如果是自己，使用 meProvider 信息兜底
        if (targetContact == null && me.uid == detailsId) {
          targetContact = ContactModel(
            id: detailsId,
            title: me.name?.isNotEmpty == true ? me.name! : '我', //
            iconUrl: me.avatar?.isNotEmpty == true ? me.avatar! : 'assets/image/002.png',
            bgUrl: 'assets/image/010.jpeg',
          );
        }
        // 4. 终极兜底：真的找不到该用户
        if (targetContact == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text("用户 $detailsId 不存在", style: const TextStyle(fontSize: 16))),
          );
        }
        // --- 核心渲染区：此时 targetContact 绝对是强类型的 ContactModel ---
        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: const Color.fromARGB(255, 251, 249, 249),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent, //
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(icon: const Icon(Icons.settings), onPressed: () => context.pushNamed('Setting')),
              ),
            ],
          ),
          body: Stack(
            children: [
              // 背景：完全由对象的 bgUrl 决定
              Positioned(left: 0, right: 0, top: 0, height: 225, child: _buildBackgroundImage(targetContact.bgUrl)),
              ListView(
                children: [
                  const SizedBox(height: 120),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10), //
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildImage(targetContact.iconUrl), // 传入明确的 String
                        const SizedBox(width: 5),
                        _buildTitleArea(targetContact.title, targetContact.id), // 传入明确的 String
                        _buildMessageButton(targetContact.id, context, isFuren), // 传入明确的 String
                      ],
                    ),
                  ),
                  const Positions(),
                ],
              ),
            ],
          ),
        );
      },
      // AsyncValue 的兜底：加载中与错误状态
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('数据加载失败: $err'))),
    );
  }

  Widget _buildBackgroundImage(String path) {
    if (path.isEmpty) return _buildDefaultBg();
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _buildDefaultBg(), //
      );
    }
    if (path.startsWith('/')) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _buildDefaultBg(), //
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => _buildDefaultBg(), //
    );
  }

  Widget _buildDefaultBg() => Image.asset('assets/image/010.jpeg', fit: BoxFit.cover);

  Widget _buildImage(String url) {
    return Container(
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        color: Colors.white,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)], //
      ),
      margin: const EdgeInsets.all(10),
      child: ClipRRect(borderRadius: BorderRadius.circular(40), child: _buildAvatarImage(url)),
    );
  }

  Widget _buildAvatarImage(String url) {
    if (url.isEmpty) return _fallbackIcon();
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _fallbackIcon(), //
      );
    }
    if (url.startsWith('/')) {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _fallbackIcon(), //
      );
    }
    return Image.asset(
      url,
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => _fallbackIcon(), //
    );
  }

  Widget _fallbackIcon() => Container(
    color: Colors.grey[300],
    child: const Icon(Icons.person, color: Colors.white, size: 40),
  );

  Widget _buildTitleArea(String title, String id) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, //
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis, //
          ),
          const SizedBox(height: 4),
          Text('猫猫号: $id', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMessageButton(String id, BuildContext context, bool isFuren) {
    return GestureDetector(
      onTap: () {
        if (isFuren) {
          context.pop();
        } else {
          context.pushReplacementNamed('chat', pathParameters: {'chatId': id});
        }
      },
      child: Container(
        margin: const EdgeInsets.only(left: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.red),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: Colors.yellow, size: 18),
            SizedBox(width: 4),
            Text(
              '发信息',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class Positions extends StatelessWidget {
  const Positions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          _buildSignatureItem(),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _buildItem('送礼', Icons.card_giftcard, onTap: () => print('点击了送礼')),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _buildItem('动态', Icons.camera_alt_outlined, onTap: () => print('点击了动态')),
        ],
      ),
    );
  }

  Widget _buildItem(String label, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 16)),
      trailing: Icon(icon, color: Colors.grey[400], size: 20),
    );
  }

  Widget _buildSignatureItem() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('签名', style: TextStyle(fontSize: 16)),
      subtitle: const Text('这只小猫很懒，还没有签名喵~', style: TextStyle(fontSize: 13, color: Colors.grey)),
      trailing: Icon(Icons.edit_note_outlined, color: Colors.grey[400], size: 20),
    );
  }
}
