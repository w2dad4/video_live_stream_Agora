import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_Data/friend_social_models.dart';

/// 我的小猫码：猫猫号 + 二维码（与扫一扫 [CatQrPayload] 对应）
final myCatQrDataProvider = Provider<String>((ref) {
  final me = ref.watch(meProvider);
  final id = me?.uid?.trim().isNotEmpty == true ? me!.uid!.trim() : 'me';
  return CatQrPayload(catId: id, name: me?.name ?? '匿名').toQrString();
});

class QrGeneratorPage extends ConsumerWidget {
  const QrGeneratorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrData = ref.watch(myCatQrDataProvider);

    return QrImageView(
      data: qrData,
      version: QrVersions.auto,
      size: 200,
      gapless: false,
      errorCorrectionLevel: QrErrorCorrectLevel.H,
      embeddedImage: const AssetImage('assets/image/010.jpeg'),
      embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(50, 50)),
      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
    );
  }
}
