import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// 1. 定义一个简单的麦克风状态 Provider
final micMutedProvider = StateProvider<bool>((ref) => false);

class Microphone extends ConsumerWidget {
  const Microphone({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Consumer(
          builder: (context, ref, child) {
            final isMuted = ref.watch(micMutedProvider);
            return IconButton(
              icon: Icon(
                isMuted ? Icons.mic_off : Icons.mic, //
                color: isMuted ? Colors.white : Colors.red,
              ),
              onPressed: () {
                ref.read(micMutedProvider.notifier).state = isMuted;
              }, //
            );
          },
        ),
      ],
    );
  }
}
