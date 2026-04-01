import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 建议去高德后台申请一个 "Web服务" 类型的 Key
const String amapKey = "529fb59cf586cece95a17f76e012cdd3";

final userLocationProvider = FutureProvider<String>((ref) async {
  // 1. 获取经纬度 (保持之前的权限检查逻辑)
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return '权限被拒绝';
  }

  try {
    // 2. 拿到坐标 (vivo手机室内建议增加超时时间)
    Position position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.high, // 直接传递精度
  timeLimit: const Duration(seconds: 10), // 可选：超时时间
);

    // 3. 【关键】调用高德 Web API
    final dio = Dio();
    final response = await dio.get(
      'https://restapi.amap.com/v3/geocode/regeo',
      queryParameters: {
        'key': amapKey,
        'location': '${position.longitude},${position.latitude}', // 高德要求：经度在前，纬度在后
        'extensions': 'base',
        'output': 'JSON',
      },
    );

    if (response.data['status'] == '1') {
      final regeocode = response.data['regeocode'];
      final addressComponent = regeocode['addressComponent'];

      // 提取省份和城市
      String province = addressComponent['province'];
      // 处理直辖市（如北京市），此时 city 字段可能是空列表 []
      dynamic city = addressComponent['city'];
      String cityName = (city is List || city == null || city.isEmpty) ? province : city.toString();

      return '$province·$cityName';
    } else {
      return '位置解析失败';
    }
  } catch (e) {
    // 如果超时或网络错误，优雅降级
    return '定位超时';
  }
});
