import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/live_stream_discover/live_streaming_starts/logic_layer_data/logic_layer.dart';
import 'package:video_live_stream/start_video/beauty.dart';
import 'package:video_live_stream/start_video/logic/music/music_main.dart';
import 'package:video_live_stream/start_video/logic/stream_service.dart';
import 'package:video_live_stream/start_video/maxim.dart';
import 'package:video_live_stream/start_video/room_manager_logic.dart';
import 'package:video_live_stream/tool/dataTime.dart';
import 'package:video_live_stream/utility/dialogbox.dart'; // 禁言管理

//主播内容
class BottomActionBar extends ConsumerWidget {
  final bool isHost;
  final String roomID;
  const BottomActionBar({super.key, required this.isHost, required this.roomID});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showMenu(context, ref),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: Color(0xffEE6983), shape: BoxShape.circle),
        child: Icon(isHost ? CupertinoIcons.slider_horizontal_3 : CupertinoIcons.heart_circle, color: Colors.white, size: 28),
      ),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // 允许自定义高度
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: SafeArea(
              child: isHost ? BuildHostMenu(roomID: roomID) : BuildAudienceMenu(roomID: roomID),
            ),
          );
        },
      ),
    );
  }
}

// 🟢 主播控制菜单：提取 HostPanel 的控制能力
class BuildHostMenu extends ConsumerWidget {
  final String roomID;

  const BuildHostMenu({super.key, required this.roomID});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMicEnabled = ref.watch(isMicOpenProvider);
    final notifier = ref.read(livePublisherProvider(roomID).notifier);
    final isRecording = ref.watch(isRecordingProvider); //用于控制录播颜色
    final currentQuality = ref.watch(currentQualityProvider);


    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '房间管理与设置',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 25),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 4, // 四列布局
          mainAxisSpacing: 20,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            //摄像头反转
            _menuItem(CupertinoIcons.camera_rotate, '翻转', () => notifier.switchCamera()),
            //静音
            _menuItem(
              isMicEnabled ? CupertinoIcons.mic_fill : CupertinoIcons.mic_slash_fill,
              isMicEnabled ? '已开麦' : '已静音', //
              () => notifier.toggleMic(),
              color: isMicEnabled ? Colors.white : Colors.redAccent,
            ),
            //美颜
            _menuItem(CupertinoIcons.wand_stars, '美颜', () {
              context.pop(); // 先关底部菜单
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent, //
                builder: (context) => const BeautyControlPanel(),
              );
            }),
            //禁言名单
            _menuItem(CupertinoIcons.person_crop_circle_badge_exclam, '禁言名单', () {
              context.pop();
              showModalBottomSheet(context: context, builder: (_) => const ShowMuteManagement());
            }),
            //音乐
            _menuItem(CupertinoIcons.music_note_2, '音乐', () {
              context.pop();
              showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => const MusicMain());
            }),
            //录播
            _menuItem(
              CupertinoIcons.smallcircle_fill_circle,
              '录播',
              color: isRecording ? Colors.redAccent : Colors.white, //
              () {
                final isRecording = ref.read(isRecordingProvider);
                AppDialogs.showconfirmDialog(
                  context: context,
                  title: isRecording ? '停止录制' : '开始录制',
                  content: isRecording ? '是否结束并保存当前录制？' : '是否开始录制当前直播画面？',
                  confirmText: isRecording ? '停止' : '开始',
                  isDestructive: isRecording, // 停止时显示红色警示文字
                  onConfirm: () {
                    ref.read(isRecordingProvider.notifier).state = !isRecording;
                  },
                );
              },
            ),
            //清晰度
            _menuItem(
              Icons.blur_on,
              currentQuality.name, // 显示当前选中的清晰度名称
              () => _showQualityPicker(context, ref),
              color: Colors.lightBlueAccent,
            ),

            //直播时长
            _menuItem(Icons.access_time, '直播时长', () {
              final currentSeconds = ref.read(liveSecondsProvider);
              final timeString = formatDuration(currentSeconds);
              final liveduration = ref.read(isLiveduration);
              AppDialogs.showconfirmDialog(
                context: context,
                title: '直播时长',
                content: '本次直播已持续:$timeString', //
                onConfirm: () {
                  ref.read(isLiveduration.notifier).state = !liveduration;
                },
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap, {Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  // 弹出清晰度选择器
  void _showQualityPicker(BuildContext context, WidgetRef ref) {
    AppDialogstate.showSelectionSheet<LiveQuality>(
      context: context,
      title: '选择直播清晰度',
      message: '更高的清晰度需要更好的网络带宽',
      options: LiveQuality.values,
      getlabel: (quality) => quality.name,
      onSelected: (quality) {
        ref.read(livePublisherProvider(roomID).notifier).changeQuality(quality);
      },
    );
  }
}

// 🟢 观众互动菜单
class BuildAudienceMenu extends ConsumerWidget {
  final String roomID;
  const BuildAudienceMenu({super.key, required this.roomID});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '更多互动',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _menuItem(Icons.card_giftcard, '送礼', () {}, color: Colors.orangeAccent),
            _menuItem(Icons.share, '分享', () {}, color: Colors.blueAccent),
            _menuItem(Icons.report, '举报', () {}, color: Colors.grey),
          ],
        ),
      ],
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap, {Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
