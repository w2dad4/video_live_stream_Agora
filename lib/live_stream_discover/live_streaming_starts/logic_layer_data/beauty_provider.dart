//美颜

//定义一个关于美颜的

import 'package:flutter_riverpod/flutter_riverpod.dart';

//定义一个全局provider
final beautyProvider = NotifierProvider<BeautyNotifier, BeautySettings>(
  BeautyNotifier.new,
);

class BeautySettings {
  final bool isEnable; //总开关
  final double smooth; //磨皮
  final double whiten; //美白
  final double thsiFace; //瘦脸
  final double clarity; //清晰度
  final double brightness; //亮度
  final double contrast; //对比度
  final double saturation; //饱和度
  final double hue; //色调
  final String activeFiler; //当前滤镜名称
  BeautySettings({
    this.isEnable = false,
    this.smooth = 0.5,
    this.whiten = 0.5,
    this.thsiFace = 0.5, //
    this.clarity = 0.5,
    this.brightness = 0.5,
    this.contrast = 0.5,
    this.saturation = 0.5,
    this.hue = 0.5,
    this.activeFiler = '原图',
  });
  BeautySettings copyWith({
    bool? isEnable,
    double? smooth,
    double? whiten,
    double? thsiFace,
    double? clarity,
    double? brightness,
    double? contrast, //
    double? saturation,
    double? hue,
    String? activeFiler,
  }) {
    return BeautySettings(
      isEnable: isEnable ?? this.isEnable,
      smooth: smooth ?? this.smooth,
      whiten: whiten ?? this.whiten,
      thsiFace: thsiFace ?? this.thsiFace, //
      clarity: clarity ?? this.clarity,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      hue: hue ?? this.hue,
      activeFiler: activeFiler ?? this.activeFiler,
    );
  }
}

// 2. 创建 Notifier
class BeautyNotifier extends Notifier<BeautySettings> {
  @override
  BeautySettings build() => BeautySettings();
  // 更新总开关
  void toggleBeauty() => state = state.copyWith(isEnable: !state.isEnable);
  //重置功能
  void reset() => state = BeautySettings();

  // 统一更新方法 (便捷写法)
  void updataField(String fieldName, dynamic value) {
    switch (fieldName) {
      case 'smooth':
        state = state.copyWith(smooth: value);
        break; //磨皮
      case 'whiten':
        state = state.copyWith(whiten: value);
        break; //美白
      case 'thsiFace':
        state = state.copyWith(thsiFace: value);
        break; //瘦脸
      case 'clarity':
        state = state.copyWith(clarity: value);
        break; //清晰度
      case 'brightness':
        state = state.copyWith(brightness: value);
        break; //亮度
      case 'contrast':
        state = state.copyWith(contrast: value);
        break; //对比度
      case 'saturation':
        state = state.copyWith(saturation: value);
        break; //饱和度
      case 'hue':
        state = state.copyWith(hue: value);
        break; //色调
      case 'activeFiler':
        state = state.copyWith(activeFiler: value);
        break; //滤镜
    }
  }
}
