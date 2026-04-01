import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'package:video_live_stream/live_stream_discover/select_Album/dialogbox.dart';
import 'package:video_live_stream/live_stream_discover/select_Album/select_Album.dart';

//这是语音
class SpeechMainTab extends ConsumerWidget {
  final dynamic autios;
  const SpeechMainTab({super.key, this.autios});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPadding = MediaQuery.of(context).size.height * 0.15;
    return Scaffold(
      backgroundColor: Color(0xffBDA6CE),
      body: Stack(
        children: [
          const SelectAlbum(mode: LiveMode.audio),
          Positioned(
            bottom: bottomPadding,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.only(left: 30, right: 30),
              child: Startaudio(width: MediaQuery.of(context).size.width * 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

//开始直播按钮
class Startaudio extends ConsumerWidget {
  final double width;
  const Startaudio({super.key, required this.width});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        //先弹出确认的弹窗
        final bool? shoulbEnter = await _enterthelivestream(context);
        //判断用户是否点击了开启直播
        if (shoulbEnter == true && context.mounted) {
          final audioID = ref.read(meProvider).uid;
          //执行真正跳转的逻辑
          context.pushNamed('/AudioViode', extra: {"id": audioID});
        }
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(colors: [Colors.redAccent, Colors.red]),
        ),
        width: width,
        height: 50,
        child: Text('开启语音直播', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  //进入直播的一个弹窗
  Future<bool?> _enterthelivestream(BuildContext context) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('开始语音直播'),
        content: const Text('即将进入直播间开启直播，请确认网络状态良好。'),
        actions: [
          CupertinoDialogAction(child: const Text('我再想想'), onPressed: () => context.pop(false)),
          CupertinoDialogAction(child: const Text('确认进入'), onPressed: () => context.pop(true)),
        ],
      ),
    );
  }
}
