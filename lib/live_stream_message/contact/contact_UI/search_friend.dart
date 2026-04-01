import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/search_provider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_UI/qr_flutter.dart';

// 1. 定义一个用于存储搜索关键字的 Provider

class AddFriendPage extends ConsumerWidget {
  const AddFriendPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menitems = ref.watch(addFriendMenuPrvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('添加朋友'),
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed('VideoMessage');
            }
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), //点击空白处能自动收缩键盘
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSearchBar(),
            Expanded(
              child: ListView.separated(
                itemCount: menitems.length,
                separatorBuilder: (context, index) => const Divider(height: 0.5, indent: 60),
                itemBuilder: (context, index) {
                  final item = menitems[index];
                  return ListTile(
                    leading: Icon(item['icon'] as IconData, color: Colors.blueAccent),
                    title: Text(item['title'] as String),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 15, color: Colors.grey),
                    onTap: () => print('点击了:${item['action']}'),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(
                  children: [
                    Text('我的小猫帐号：YourID_M1Pro', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 10),
                    const QrGeneratorPage(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //搜索框内容
  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.only(left: 10, right: 10),
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15), //
        color: const Color.fromARGB(255, 227, 225, 225),
      ),
      child: const TextField(
        textAlignVertical: TextAlignVertical.center, // 【核心 1】强制文字和光标垂直居中
        decoration: InputDecoration(
          isDense: true,
          hintText: '手机号/帐号', //
          prefixIcon: Icon(Icons.search, size: 30),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
