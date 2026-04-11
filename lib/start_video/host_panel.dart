// 主播端内容，主播控制UI等等

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:video_live_stream/start_video/beauty.dart';
import 'package:video_live_stream/live_stream_discover/live_streaming_starts/shiping_UI/video_shiping.dart';
import 'package:video_live_stream/start_video/logic/agora_service.dart';
import 'package:video_live_stream/start_video/maxim.dart';

final isPanelExpandedProvider = StateProvider<bool>((ref) => false);

class HostPanel extends StatelessWidget {
  final String roomID;
  const HostPanel({super.key, required this.roomID});

  @override
  Widget build(BuildContext context) {
    return _CameraActionControls(roomID: roomID);
  }
}

class _CameraActionControls extends ConsumerWidget {
  final String roomID;
  const _CameraActionControls({required this.roomID});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final starsState = ref.watch(stars);
    final isNot = ref.watch(isPanelExpandedProvider);
    final notifier = ref.watch(agoraHostServiceProvider(roomID).notifier);
    // Agora 麦克风状态从 notifier 获取
    final isMicEnabled = !notifier.isMicrophoneMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isNot) ...[
          const SizedBox(width: 15),
          _PanelIconButton(
            icon: Icons.group_off,
            color: Colors.white,
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => const ShowMuteManagement(),
              );
            },
          ),
        ],
        const SizedBox(width: 5),
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 主开关按钮
              _PanelIconButton(
                icon: isNot
                    ? Icons.zoom_out_map_outlined
                    : Icons.zoom_in_map_outlined,
                color: isNot ? Colors.pink : Colors.white,
                onTap: () {
                  ref.read(isPanelExpandedProvider.notifier).state = !isNot;
                },
              ),
              if (isNot) ...[
                // 麦克风控制 — 通过 Agora SDK
                const SizedBox(height: 7),
                _PanelIconButton(
                  icon: isMicEnabled
                      ? CupertinoIcons.mic_fill
                      : CupertinoIcons.mic_slash_fill,
                  color: isMicEnabled ? Colors.white : Colors.redAccent,
                  onTap: () async {
                    await notifier.toggleMicrophone();
                    // 强制刷新 UI
                    ref.invalidate(agoraHostServiceProvider(roomID));
                  },
                ),
                // 美颜控制
                const SizedBox(height: 7),
                _PanelIconButton(
                  icon: CupertinoIcons.wand_stars,
                  color: starsState ? Colors.pink : Colors.white, //
                  onTap: () => _showBeautyPanel(context),
                ),
                const SizedBox(height: 7),
                // 切换摄像头 — 通过 Agora SDK
                _PanelIconButton(
                  icon: CupertinoIcons.camera_viewfinder,
                  color: Colors.white,
                  onTap: () async {
                    await notifier.switchCamera();
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showBeautyPanel(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.white,
      context: context,
      builder: (context) => const BeautyControlPanel(),
    );
  }
}

class _PanelIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _PanelIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 24),
    );
  }
}
