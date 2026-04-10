import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

// 高德「Web 服务」Key（控制台需开通「Web 服务 API」；Android/iOS 原生 Key 不能混用）
const String amapKey = '529fb59cf586cece95a17f76e012cdd3';

final _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 15)));

final userLocationProvider = FutureProvider<String>((ref) async {
  if (kIsWeb) {
    return 'Web 端请使用浏览器定位或后端解析';
  }

  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return '定位服务未开启';

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return '权限被拒绝';
  }
  if (permission == LocationPermission.deniedForever) {
    return '请在设置中允许定位';
  }

  try {
    final position = await _resolvePosition();
    return await _reverseGeocodeAmap(position);
  } on TimeoutException {
    final approx = await _fallbackApproxLocationByIp();
    if (approx != null && approx.isNotEmpty) {
      return '定位超时';
    }
    return '定位超时';
  } on DioException catch (e) {
    return '网络异常：${e.message ?? e.type.name}';
  } catch (e) {
    return '位置获取失败：$e';
  }
});

Future<String> _reverseGeocodeAmap(Position position) async {
  final response = await _dio.get<Map<String, dynamic>>('https://restapi.amap.com/v3/geocode/regeo', queryParameters: {'key': amapKey, 'location': '${position.longitude},${position.latitude}', 'extensions': 'base', 'output': 'JSON'});

  final data = response.data;
  if (data == null) return _coordFallback(position);

  if (data['status'] == '1' && data['regeocode'] != null) {
    final component = data['regeocode']['addressComponent'];
    if (component == null) return _coordFallback(position);

    final province = component['province']?.toString() ?? '';
    final dynamic city = component['city'];
    final cityName = (city is List || city == null || (city is String && city.isEmpty)) ? province : city.toString();
    return '$province·$cityName';
  }

  final info = data['info']?.toString() ?? '';
  if (info.isNotEmpty) return '逆地理失败($info)，${_coordFallback(position)}';
  return _coordFallback(position);
}

String _coordFallback(Position position) {
  return '坐标(${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)})';
}

/// 无 GPS 时用公网 IP 粗定位（HTTPS，不需定位权限），仅作展示兜底。
Future<String?> _fallbackApproxLocationByIp() async {
  try {
    final r = await _dio.get<Map<String, dynamic>>('https://get.geojs.io/v1/ip/geo.json');
    final d = r.data;
    if (d == null) return null;
    final region = d['region']?.toString().trim() ?? '';
    final city = d['city']?.toString().trim() ?? '';
    if (region.isNotEmpty && city.isNotEmpty) return '$region·$city';
    if (city.isNotEmpty) return city;
    if (region.isNotEmpty) return region;
    return null;
  } catch (_) {
    return null;
  }
}

/// 室内优先走网络定位：先缓存 → 最低精度（基站/Wi‑Fi）→ 再提高精度；超时再抛 [TimeoutException]。
Future<Position> _resolvePosition() async {
  final last = await Geolocator.getLastKnownPosition();
  if (last != null) return last;

  Future<Position> once(LocationAccuracy acc, Duration limit) {
    return Geolocator.getCurrentPosition(desiredAccuracy: acc, timeLimit: limit);
  }

  try {
    // 室内/冷启动：lowest 最容易先出结果
    return await once(LocationAccuracy.lowest, const Duration(seconds: 28));
  } on TimeoutException {
    try {
      return await once(LocationAccuracy.medium, const Duration(seconds: 35));
    } on TimeoutException {
      return await once(LocationAccuracy.low, const Duration(seconds: 30));
    }
  }
}
