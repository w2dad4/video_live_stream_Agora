import 'dart:async';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 高德 Web 服务 Key
const String amapKey = "529fb59cf586cece95a17f76e012cdd3";

final userLocationProvider = FutureProvider<String>((ref) async {
  bool serviceEnabled;
  LocationPermission permission;

  // 1. 检查定位服务
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return '定位服务未开启';

  // 2. 权限检查
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return '权限被拒绝';
  }
  if (permission == LocationPermission.deniedForever) return '请在设置中允许定位';

  try {
    // 3. 【修复点】移除 forceLocationManager 参数，直接调用
    // 先尝试获取系统缓存位置，这是最快的方式
    Position? position = await Geolocator.getLastKnownPosition();

    // 4. 【优化点】如果没缓存，发起“最低精度”定位
    // 精度设为 lowest 能够强制手机使用网络定位而非 GPS，从而在室内实现秒开
    position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 10));

    // 5. 调用高德 API 逆地理编码
    final dio = Dio();
    final response = await dio.get('https://restapi.amap.com/v3/geocode/regeo', queryParameters: {'key': amapKey, 'location': '${position.longitude},${position.latitude}', 'extensions': 'base', 'output': 'JSON'});

    if (response.data['status'] == '1') {
      final component = response.data['regeocode']['addressComponent'];
      String province = component['province'].toString();
      dynamic city = component['city'];
      // 处理直辖市逻辑
      String cityName = (city is List || city == null || city.isEmpty) ? province : city.toString();
      return '$province·$cityName';
    }

    return '坐标: (${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)})';
  } on TimeoutException {
    return '定位超时，请检查网络';
  } catch (e) {
    return '位置获取失败';
  }
});
