import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_model.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/contact_provider.dart';

class ContactPage extends ConsumerWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用 Riverpod 监听数据，实现响应式 UI
    final contactAsync = ref.watch(contactListProvider);
    final double topPadding = MediaQuery.of(context).padding.top;
    return contactAsync.when(
      data: (contacs) => CustomScrollView(
        slivers: [
          //顶部添加好友的icon
          _buildTopHeader(context, topPadding),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) => _ContactTile(item: contacs[index]), childCount: contacs.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      error: (err, stack) => Center(child: Text('数据加载失败')),
      loading: () => Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildTopHeader(BuildContext context, double topPadding) {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        height: topPadding + 30,
        color: Colors.white,
        padding: EdgeInsets.only(top: topPadding, right: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () {
                context.pushNamed('AddFriend');
              },
              child: Icon(Icons.person_add_alt_1, size: 27),
            ),
          ],
        ),
      ),
    );
  }
}

//抽取Tile组件提高性能，能治list view滚动时重绘
class _ContactTile extends StatelessWidget {
  final ContactModel item;
  const _ContactTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        if (item.id.isNotEmpty) {
          context.pushNamed('Details', pathParameters: {'detailsId': item.id});
        }
      },
      leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: _buildAvatar(item.iconUrl)),
      title: Text(item.title, style: const TextStyle(fontSize: 16)),
      subtitle: Transform.translate(offset: const Offset(0, 10), child: const Divider(height: 1, thickness: 0.5)),
    );
  }

  Widget _buildAvatar(String url) {
    if (url.isEmpty) {
      return Container(
        width: 45,
        height: 45,
        color: Colors.grey[200],
        child: const Icon(Icons.person, color: Colors.grey),
      );
    }
    // 灵活处理多种图片来源
    if (url.startsWith('http')) {
      return Image.network(url, width: 45, height: 45, fit: BoxFit.cover);
    } else if (url.startsWith('assets/')) {
      return Image.asset(url, width: 45, height: 45, fit: BoxFit.cover);
    } else {
      return Image.file(File(url), width: 45, height: 45, fit: BoxFit.cover);
    }
  }
}
