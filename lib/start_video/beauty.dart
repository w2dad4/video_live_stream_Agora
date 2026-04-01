//美颜
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/live_stream_discover/live_streaming_starts/logic_layer_data/beauty_provider.dart';

class BeautyControlPanel extends ConsumerWidget {
  const BeautyControlPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用 watch 监听状态，read 获取方法
    final notifier = ref.read(beautyProvider.notifier);
    final settings = ref.watch(beautyProvider);
    final heights = MediaQuery.of(context).size.height * 0.45;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: heights,
          width: double.infinity, //
          color: Colors.black.withValues(alpha: 0.7),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            children: [
              // 面板指示针
              _buildHandle(),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: [
                    _buildBeautySlider('磨皮', settings.smooth, (val) => notifier.updataField('smooth', val)),
                    _buildBeautySlider('美白', settings.whiten, (val) => notifier.updataField('whiten', val)),
                    _buildBeautySlider('瘦脸', settings.thsiFace, (val) => notifier.updataField('thsiFace', val)),
                    _buildBeautySlider('清晰度', settings.clarity, (val) => notifier.updataField('clarity', val)), //
                    _buildBeautySlider('亮度', settings.brightness, (val) => notifier.updataField('brightness', val)),
                    _buildBeautySlider('对比度', settings.contrast, (val) => notifier.updataField('contrast', val)),
                    _buildBeautySlider('饱和度', settings.saturation, (val) => notifier.updataField('saturation', val)),
                    _buildBeautySlider('色调', settings.hue, (val) => notifier.updataField('hue', val)),
                    const Divider(color: Colors.white),
                    // 滤镜选择：使用横向列表而非滑动条
                    const Text('滤镜选择', style: TextStyle(fontSize: 14, color: Colors.white)),
                    const SizedBox(height: 10),
                    _buildFilterslider(settings.activeFiler, notifier),
                  ],
                ),
              ),
              _complete(context, notifier),
            ],
          ),
        ),
      ),
    );
  }

  // 辅助：滑块组件
  Widget _buildBeautySlider(String label, double value, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(label, style: TextStyle(fontSize: 15, color: Colors.white)),
          ),
          Expanded(
            child: Slider(
              value: value,
              max: 1,
              min: 0, //
              onChanged: onChanged,
              // 随动关键：滑块拖动瞬间，Provider 状态更新，推流循环下一帧立刻生效
              activeColor: Colors.pinkAccent,
              inactiveColor: Colors.white,
            ),
          ),
          Text((value * 100).toInt().toString(), style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }

  // 辅助：滤镜横向选择
  Widget _buildFilterslider(String active, BeautyNotifier notifier) {
    final filters = ['原图', '冷清', '浪漫', '清新', '胶片'];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal, //排
        itemCount: filters.length, //
        itemBuilder: (context, index) {
          final item = filters[index];
          final isSelect = active == item;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(item),
              selected: isSelect, //
              onSelected: (value) => notifier.updataField('activeFiler', item),
              selectedColor: Colors.pinkAccent,
              labelStyle: TextStyle(color: isSelect ? Colors.white : Colors.black),
            ),
          );
        },
      ),
    );
  }

  //完成/重置
  Widget _complete(BuildContext context, BeautyNotifier notifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => notifier.reset(),
          child: Text('重置', style: TextStyle(color: Colors.white70)),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            context.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
          child: Text('完成', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  //顶部指示针
  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 5,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
    );
  }
}
