import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 引入 Riverpod
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
// 建议将逻辑层拆分，此处为方便演示合在一起
// import 'package:video_live_stream/live_stream_discover/logic_layer.dart';

class NearbyAnchor {
  final String id;
  final String name;
  final String coverUrl;
  final bool isAule;
  final double distance;
  NearbyAnchor({required this.name, required this.coverUrl, this.isAule = true, required this.distance, required this.id});
  factory NearbyAnchor.fromjson(Map<String, dynamic> json) {
    return NearbyAnchor(name: json['name'] ?? "主播", coverUrl: json['cover_url'] ?? '', distance: (json['distance'] ?? 0.0).toDouble(), id: json['id'] ?? "");
  }
}

// --- 1. 定义 Riverpod 状态模型 ---
class AnchorState {
  final List<NearbyAnchor> anchors;
  final bool isLoading;
  final String? error;
  AnchorState({this.anchors = const [], this.isLoading = false, this.error});

  AnchorState copyWith({List<NearbyAnchor>? anchors, bool? isLoading, String? error}) {
    return AnchorState(anchors: anchors ?? this.anchors, isLoading: isLoading ?? this.isLoading, error: error ?? this.error);
  }
}

// --- 2. 定义 Riverpod 控制器 ---
class AnchorNotifier extends StateNotifier<AnchorState> {
  AnchorNotifier() : super(AnchorState());

  // 初始化获取定位和数据
  Future<void> initData() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 定位只作为“附近排序”辅助，不应阻塞页面展示
      await _getValidatedPosition();
    } catch (e) {
      debugPrint('定位流程降级: $e');
    }

    try {
      // 模拟网络请求和排序逻辑
      await Future.delayed(const Duration(seconds: 1));
      final list = List<NearbyAnchor>.from(VideoDiscoverPage.mockData)..sort((a, b) => a.distance.compareTo(b.distance));

      state = state.copyWith(anchors: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // 修复后的定位权限逻辑 (适配 geolocator 12.0.0)
  Future<Position> _getValidatedPosition() async {
    bool serviceEnable = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnable) {
      throw '定位未开启';
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        throw '定位权限被拒绝';
      }
    }
    if (perm == LocationPermission.deniedForever) {
      throw '定位权限被永久拒绝';
    }

    final last = await Geolocator.getLastKnownPosition();
    if (last != null) return last;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.lowest,
        timeLimit: const Duration(seconds: 28),
      );
    } on TimeoutException {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 35),
      );
    }
  }
}

// 定义全局 Provider
final anchorProvider = StateNotifierProvider<AnchorNotifier, AnchorState>((ref) {
  return AnchorNotifier();
});

// --- 3. 发现页 UI 转换 ---
class VideoDiscoverPage extends ConsumerWidget {
  // 改为 ConsumerWidget
  const VideoDiscoverPage({super.key});

  static final List<NearbyAnchor> mockData = [
    NearbyAnchor(name: '隔壁老王', coverUrl: 'assets/image/002.png', distance: 1.2, id: '1'),
    NearbyAnchor(name: '小猫酱', coverUrl: 'assets/image/003.png', distance: 2.5, id: '2'),
    NearbyAnchor(name: '健身达人', coverUrl: 'assets/image/004.jpeg', distance: 4.8, id: '3'),
    NearbyAnchor(name: '鱼王', coverUrl: 'assets/image/005.jpeg', distance: 9.1, id: '4'),
    NearbyAnchor(name: '美妙味道', coverUrl: 'assets/image/006.png', distance: 22.7, id: '5'), //
    NearbyAnchor(name: '健身', coverUrl: 'assets/image/007.jpeg', distance: 66.9, id: '6'),
    NearbyAnchor(name: '呆萌', coverUrl: 'assets/image/008.jpeg', distance: 55.7, id: '7'), //
    NearbyAnchor(name: '可爱', coverUrl: 'assets/image/009.jpeg', distance: 11.6, id: '8'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(anchorProvider);
    double bottomPadding = MediaQuery.of(context).padding.bottom;

    // 自动在首次加载时调用 initData
    // 使用 Future.microtask 避免在 build 过程中修改状态
    Future.microtask(() {
      if (state.anchors.isEmpty && !state.isLoading && state.error == null) {
        ref.read(anchorProvider.notifier).initData();
      }
    });

    return Scaffold(backgroundColor: Colors.white, body: _buildBody(state, ref, bottomPadding));
  }

  Widget _buildBody(AnchorState state, WidgetRef ref, double bottomPadding) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('出错了：${state.error}', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: () => ref.read(anchorProvider.notifier).initData(), child: const Text('重试')),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(10, 10, 10, bottomPadding + 5),
      itemCount: state.anchors.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.8),
      itemBuilder: (context, index) => _AnchorCard(anchor: state.anchors[index]),
    );
  }
}

class _AnchorCard extends StatelessWidget {
  final NearbyAnchor anchor;
  const _AnchorCard({required this.anchor});

  @override
  Widget build(BuildContext context) {
    final String liveId = anchor.id;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              context.pushNamed('/StartVideo', extra: {'id': liveId, 'isHost': false});
            },
            child: Positioned.fill(child: Image.asset(anchor.coverUrl, fit: BoxFit.cover)),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)]),
              ),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${anchor.name}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 14),
                    Text('${anchor.distance}km', style: const TextStyle(fontSize: 12, color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
