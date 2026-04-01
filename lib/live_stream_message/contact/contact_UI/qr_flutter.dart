import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

//逻辑层. 二维码
final authQrProvider = NotifierProvider<AutoQrNotifier, String>(AutoQrNotifier.new);

class AutoQrNotifier extends Notifier<String> {
  late Timer _timer;
  @override
  String build() {
    _startTimer();
    return _generateQrContent(); // 返回初始显示的内容
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      state = _generateQrContent(); // 每分钟刷新 state，通知 UI 重绘
    });
    // 3. 当 Provider 被销毁时（用户离开页面），自动关闭定时器，防止内存泄漏
    ref.onDispose(() => _timer.cancel());
  }

  String _generateQrContent() {
    return 'https://yourshow.com/pay?token=${DateTime.now().minute}_${DateTime.now().second}';
  }
}

//UI层
class QrGeneratorPage extends ConsumerWidget {
  const QrGeneratorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听 Provider，实现动态更新
    final qrData = ref.watch(authQrProvider);

    return QrImageView(
      data: qrData,
      version: QrVersions.auto,
      size: 200.0,
      gapless: false,
      // ，确保中间有 Logo 时依然能秒扫
      errorCorrectionLevel: QrErrorCorrectLevel.H,
      embeddedImage: const AssetImage('assets/image/010.jpeg'),
      embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(50, 50)),
      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
    );
  }
}
