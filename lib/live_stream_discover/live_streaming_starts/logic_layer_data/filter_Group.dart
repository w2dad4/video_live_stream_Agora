import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:video_live_stream/live_stream_discover/live_streaming_starts/logic_layer_data/beauty_provider.dart';

class BeautyProcessor {
  static cv.Mat process(cv.Mat src, BeautySettings s, {bool isFrontCamera = false}) {
    // 1. 基础格式转换 (BGRA -> BGR)
    cv.Mat bgr = cv.cvtColor(src, cv.COLOR_BGRA2BGR);

    // 2. 如果开启了美颜总开关且清晰度大于 0
    if (s.isEnable && s.clarity > 0) {
      // 计算锐化强度 (将 0.0-1.0 映射到合理的锐化范围，例如 0.0-2.0)
      double amount = s.clarity * 1.5;

      cv.Mat blurred = cv.Mat.empty();
      // 使用高斯模糊提取背景平滑部分
      cv.gaussianBlur(bgr, blurred as (int, int), (0, 0) as double, borderType: 3);

      // 执行锐化叠加：Result = bgr * (1 + amount) + blurred * (-amount)
      cv.Mat sharpened = cv.addWeighted(bgr, 1 + amount, blurred, -amount, 0);

      bgr.dispose();
      blurred.dispose();
      bgr = sharpened; // 替换为锐化后的图像
    }

    // 3. 镜像处理
    if (isFrontCamera) {
      cv.Mat mirrored = cv.flip(bgr, 1);
      bgr.dispose();
      return mirrored;
    }

    return bgr;
  }
}
