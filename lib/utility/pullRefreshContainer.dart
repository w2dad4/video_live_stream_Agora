import 'package:flutter/material.dart';

/// 通用下拉刷新容器
class PullRefreshContainer extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const PullRefreshContainer({super.key, required this.child, required this.onRefresh});

  @override
  State<PullRefreshContainer> createState() => _PullRefreshContainerState();
}

class _PullRefreshContainerState extends State<PullRefreshContainer> {
  final ScrollController _controller = ScrollController();
  final ValueNotifier<double> pullDistance = ValueNotifier(0);
  final ValueNotifier<bool> isRefreshing = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (_controller.offset < 0 && !isRefreshing.value) {
      double distance = -_controller.offset;
      if (distance > 100) distance = 100;
      pullDistance.value = distance;
    }
  }

  Future<void> _refresh() async {
    isRefreshing.value = true;
    // 同时执行刷新操作和2秒动画，确保最少显示2秒
    await Future.wait([widget.onRefresh(), Future.delayed(const Duration(seconds: 2))]);
    isRefreshing.value = false;
    pullDistance.value = 0;
  }

  void _onScrollEnd() {
    if (pullDistance.value >= 50 && !isRefreshing.value) {
      _refresh();
    } else if (!isRefreshing.value) {
      pullDistance.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    pullDistance.dispose();
    isRefreshing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollEndNotification>(
      onNotification: (_) {
        _onScrollEnd();
        return false;
      },
      child: CustomScrollView(
        controller: _controller,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // 顶部刷新区域
          SliverToBoxAdapter(
            child: ValueListenableBuilder<double>(
              valueListenable: pullDistance,
              builder: (_, distance, __) {
                return SizedBox(
                  height: distance,
                  child: Center(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: isRefreshing,
                      builder: (_, refreshing, __) {
                        if (refreshing) {
                          return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
                        }
                        if (distance >= 50) {
                          return const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_upward, size: 16, color: Colors.grey),
                              SizedBox(width: 4),
                              Text('松开刷新', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          );
                        }
                        return const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_downward, size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Text('下拉刷新', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          // 内容区域
          SliverToBoxAdapter(child: widget.child),
        ],
      ),
    );
  }
}
