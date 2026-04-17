import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';
// 假设这是你的数据模型路径
import 'package:video_live_stream/library.dart';

// --- 使用 Riverpod 定义状态模型 ---
class AnchorState {
  final List<NearbyAnchor> anchors;
  final bool isLoading;
  final String? error;

  AnchorState({this.anchors = const [], this.isLoading = false, this.error});

  AnchorState copyWith({List<NearbyAnchor>? anchors, bool? isLoading, String? error}) {
    return AnchorState(anchors: anchors ?? this.anchors, isLoading: isLoading ?? this.isLoading, error: error ?? this.error);
  }
}

// --- Riverpod 控制器 ---
class AnchorNotifier extends StateNotifier<AnchorState> {
  AnchorNotifier() : super(AnchorState());

  Future<void> initData() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 调用修复后的权限与定位逻辑
      // final position = await getValidatedPosition();

      // 模拟请求与排序逻辑
      await Future.delayed(const Duration(seconds: 2));
      var mockList = List<NearbyAnchor>.from([]);
      mockList.sort((a, b) => a.distance.compareTo(b.distance));
      state = state.copyWith(anchors: mockList, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

// 定义全局 Provider
final anchorProvider = StateNotifierProvider<AnchorNotifier, AnchorState>((ref) {
  return AnchorNotifier();
});

// --- 修复后的定位函数 ---
Future<Position> getValidatedPosition() async {
  // 1. 检查定位服务
  bool serviceEnable = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnable) return Future.error('定位服务未开启，请在设置中打开');

  // 2. 权限校验
  LocationPermission perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied) return Future.error('定位权限被拒绝');
  }

  if (perm == LocationPermission.deniedForever) return Future.error('定位权限被永久拒绝，请手动开启');

  // 3. 核心修复点：适配 geolocator 12.0.0 的平铺参数写法
  // 注意：getCurrentPosition 是单次获取，不支持 distanceFilter 参数
  return await Geolocator.getCurrentPosition(
    // ignore: deprecated_member_use
    desiredAccuracy: LocationAccuracy.low, // 这里传枚举，不传对象
    // ignore: deprecated_member_use
    timeLimit: const Duration(seconds: 10), // 超时设置
  );
}
