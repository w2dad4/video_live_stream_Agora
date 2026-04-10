import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'package:video_live_stream/utility/icon.dart';

class ApplyPage extends ConsumerWidget {
  const ApplyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        LiveStreamingData(),
        _buildText(
          context,
          label: ' 充值',
          icon: MyIcons.topup,
          iconColor: Colors.redAccent,
          onTap: () {
            print('充值');
          },
        ),
        _buildText(
          context,
          label: "收藏",
          icon: MyIcons.collection,
          iconColor: const Color.fromARGB(255, 241, 231, 25),
          onTap: () {
            print('收藏');
          },
        ),
        _buildText(
          context,
          label: "历史记录",
          icon: MyIcons.history,
          iconColor: const Color.fromARGB(255, 204, 204, 8),
          onTap: () {
            print('历史记录');
          },
        ),
      ],
    );
  }

  Widget _buildText(BuildContext context, {required String label, required VoidCallback onTap, required IconData icon, required Color iconColor}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        margin: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 5, spreadRadius: 1)],
          color: Colors.white,
        ),
        child: Padding(
          padding: EdgeInsets.only(left: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, size: 23, color: iconColor),
              SizedBox(width: 10),
              Text(label, style: TextStyle(fontSize: 15, color: Colors.black)),
            ],
          ),
        ),
      ),
    );
  }
}

//直播数据
class LiveStreamingData extends ConsumerWidget {
  const LiveStreamingData({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听当前选中的天数
    final selectDays = ref.watch(selectedDeysProvider);
    // 监听对应的数据
    final data = ref.watch(liveStatesProvider);
    return Container(
      margin: EdgeInsets.only(left: 10, right: 10, bottom: 10),
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 5, spreadRadius: 1)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(height: 5),
          // 1. 顶部：时间切换标签与入口
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, //
            children: [
              _buildTime(ref, label: '今日', isSelected: selectDays == 0, value: 0),
              _buildTime(ref, label: '前7天', isSelected: selectDays == 7, value: 7),
              _buildTime(ref, label: '前30天', isSelected: selectDays == 30, value: 30),
              InkWell(
                onTap: () {},
                child: Row(children: [Text('数据中心'), Icon(Icons.arrow_forward_ios)]),
              ),
            ],
          ),
          // 2. 中间：数值行 (Expanded 确保它占据剩余空间)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround, //
              children: [_buildDataValue(data['diamonds']!), _buildDataValue(data['viewers']!), _buildDataValue(data['fans']!), _buildDataValue(data['duration']!)],
            ),
          ),
          // 3. 底部：文字描述行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, //
            children: [_buildLabel('收获钻石'), _buildLabel('观众人数'), _buildLabel('新增粉丝'), _buildLabel('开播时长')],
          ),
        ],
      ),
    );
  }

  // 辅助组件：时间标签
  Widget _buildTime(WidgetRef ref, {required String label, required bool isSelected, required value}) {
    return GestureDetector(
      onTap: () => ref.read(selectedDeysProvider.notifier).state = value, //点击后切换状态
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, //
          color: isSelected ? Colors.blueAccent : Colors.grey,
        ),
      ),
    );
  }

  // 辅助组件：数值展示
  Widget _buildDataValue(String value) {
    return Expanded(
      child: Center(
        child: Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
    );
  }

  // 辅助组件：底部标签
  Widget _buildLabel(String text) {
    return Expanded(
      child: Center(
        child: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
      ),
    );
  }
}
