import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_live_stream/library.dart';
class SeatTile extends StatelessWidget {
  final VoiceSeat seat;
  final bool isHost;
  final bool isSelf;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  const SeatTile({super.key, required this.seat, required this.isHost, required this.isSelf, required this.onTap, required this.onDoubleTap});

  @override
  Widget build(BuildContext context) {
    final active = seat.uid != null;
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xff232534),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: seat.index == 1 ? const Color(0xffFFD56A) : Colors.white24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 58 + (seat.canSpeak ? seat.volume * 16 : 0),
                  height: 58 + (seat.canSpeak ? seat.volume * 16 : 0),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: seat.canSpeak ? Colors.green.withValues(alpha: 0.28) : Colors.transparent),
                ),
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.grey[700],
                  backgroundImage: active ? _buildAvatarProvider(seat.avatar ?? '') : null,
                  child: !active ? const Icon(Icons.mic_none, color: Colors.white70) : null,
                ),
                if (seat.muted) const Positioned(right: 2, bottom: 2, child: Icon(Icons.mic_off, color: Colors.redAccent, size: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Text(seat.index == 1 ? '1号位(主持)' : '${seat.index}号位', style: const TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 4),
            Text(
              active ? (seat.name ?? '用户') : (seat.allowJoin ? '可上麦' : '禁上麦'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: active ? (isSelf ? const Color(0xff7CC5FF) : Colors.white) : Colors.white54),
            ),
            const SizedBox(height: 4),
            Text(active ? (seat.canSpeak ? '可说话' : '不可说话') : (isHost ? '点击管理' : '点击送礼'), style: const TextStyle(fontSize: 11, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  ImageProvider? _buildAvatarProvider(String path) {
    if (path.isEmpty) return null;
    if (path.startsWith('http')) return NetworkImage(path);
    if (path.startsWith('/')) return FileImage(File(path));
    return AssetImage(path);
  }
}
