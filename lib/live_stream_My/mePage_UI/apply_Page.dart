import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'package:video_live_stream/utility/icon.dart';

// ==================== 数据模型 ====================

/// 单场直播记录
class LiveRecord {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int diamonds; // 收获的钻石
  final int viewers; // 观众人数
  final int newFans; // 新增粉丝
  final String title;

  LiveRecord({required this.id, required this.startTime, required this.endTime, required this.diamonds, required this.viewers, required this.newFans, this.title = ''});

  /// 直播时长（分钟）
  int get durationMinutes {
    return endTime.difference(startTime).inMinutes;
  }
}

/// 统计数据
class LiveStats {
  final int diamonds;
  final int viewers;
  final int fans;
  final int durationMinutes;

  LiveStats({this.diamonds = 0, this.viewers = 0, this.fans = 0, this.durationMinutes = 0});

  Map<String, String> toDisplayMap() {
    return {'diamonds': diamonds.toString(), 'viewers': viewers.toString(), 'fans': fans.toString(), 'duration': _formatDuration(durationMinutes)};
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes分钟';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '$hours小时$mins分' : '$hours小时';
    }
  }
}

// ==================== WebSocket 配置 ====================

/// 服务器配置
class _LiveStatsConfig {
  static const String _serverFromDefine = String.fromEnvironment('LIVE_SERVER_IP', defaultValue: '');
  static const int unifiedPort = 8080;

  static String get serverIP {
    if (_serverFromDefine.isNotEmpty) return _serverFromDefine;
    if (Platform.isAndroid || Platform.isIOS) return '192.168.1.18';
    return 'localhost';
  }
}

// ==================== Providers ====================

/// 选中的时间区间（0=今日, 7=前7天, 30=前30天）
final selectedDaysProvider = StateProvider<int>((ref) => 0);

/// WebSocket 连接状态
enum LiveStatsSocketStatus { disconnected, connecting, connected, error }

/// 直播历史记录 Notifier - WebSocket 实时更新
class LiveHistoryNotifier extends StateNotifier<List<LiveRecord>> {
  LiveHistoryNotifier(this.ref) : super([]) {
    _initWebSocket();
  }

  final Ref ref;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;

  LiveStatsSocketStatus _status = LiveStatsSocketStatus.disconnected;
  LiveStatsSocketStatus get status => _status;

  void _initWebSocket() {
    connect();
  }

  /// 建立 WebSocket 连接
  void connect() {
    if (_status == LiveStatsSocketStatus.connecting || _status == LiveStatsSocketStatus.connected) {
      return;
    }

    _status = LiveStatsSocketStatus.connecting;
    debugPrint('📊 [LiveStats] WebSocket 连接中...');

    try {
      final me = ref.read(meProvider);
      if (me == null) {
        _status = LiveStatsSocketStatus.error;
        debugPrint('📊 [LiveStats] 用户未登录');
        return;
      }
      final userId = me.uid ?? 'anonymous';

      // 构建 WebSocket URL
      final wsUrl = Uri.parse('ws://${_LiveStatsConfig.serverIP}:${_LiveStatsConfig.unifiedPort}/ws/liveStats?userId=$userId');

      debugPrint('📊 [LiveStats] 连接地址: $wsUrl');

      _channel = WebSocketChannel.connect(wsUrl);

      _subscription = _channel!.stream.listen(_onMessage, onError: _onError, onDone: _onClose);

      _channel!.ready.then((_) {
        debugPrint('📊 [LiveStats] WebSocket 连接成功');
        _status = LiveStatsSocketStatus.connected;
      });
    } catch (e) {
      debugPrint('📊 [LiveStats] 连接失败: $e');
      _status = LiveStatsSocketStatus.error;
      _reconnect();
    }
  }

  /// 接收消息
  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String);
      final type = json['type'] as String?;

      // 处理实时统计数据更新
      if (type == 'liveStatsUpdate') {
        final records = (json['data'] as List<dynamic>? ?? []).map((item) {
          return LiveRecord(id: item['id'] ?? '', startTime: DateTime.parse(item['startTime'] as String), endTime: DateTime.parse(item['endTime'] as String), diamonds: item['diamonds'] ?? 0, viewers: item['viewers'] ?? 0, newFans: item['newFans'] ?? 0, title: item['title'] ?? '');
        }).toList();

        state = records;
        debugPrint('📊 [LiveStats] 收到数据更新: ${records.length} 条记录');
      }

      // 处理单场直播结束时的增量更新（可选优化）
      if (type == 'liveEnded') {
        final newRecord = LiveRecord(id: json['id'] ?? '', startTime: DateTime.parse(json['startTime'] as String), endTime: DateTime.parse(json['endTime'] as String), diamonds: json['diamonds'] ?? 0, viewers: json['viewers'] ?? 0, newFans: json['newFans'] ?? 0, title: json['title'] ?? '');
        // 添加到列表开头
        state = [newRecord, ...state];
        debugPrint('📊 [LiveStats] 新增直播记录: ${newRecord.id}');
      }
    } catch (e) {
      debugPrint('📊 [LiveStats] 消息解析失败: $e');
    }
  }

  /// 错误处理
  void _onError(Object error) {
    debugPrint('📊 [LiveStats] 连接错误: $error');
    _status = LiveStatsSocketStatus.error;
    _reconnect();
  }

  /// 连接关闭
  void _onClose() {
    debugPrint('📊 [LiveStats] 连接关闭');
    _status = LiveStatsSocketStatus.disconnected;
    _reconnect();
  }

  /// 断线重连
  void _reconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (_status != LiveStatsSocketStatus.connected) {
        debugPrint('📊 [LiveStats] 尝试重连...');
        connect();
      }
    });
  }

  /// 手动刷新数据（请求后端重新发送数据）
  void refresh() {
    if (_channel == null || _status != LiveStatsSocketStatus.connected) {
      debugPrint('📊 [LiveStats] 未连接，无法刷新');
      return;
    }
    _channel!.sink.add(jsonEncode({'type': 'getStats'}));
    debugPrint('📊 [LiveStats] 请求刷新数据');
  }

  /// 断开连接
  void disconnect() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _status = LiveStatsSocketStatus.disconnected;
    debugPrint('📊 [LiveStats] 已断开连接');
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

/// 直播历史记录 Provider - WebSocket 实时更新
final liveHistoryProvider = StateNotifierProvider<LiveHistoryNotifier, List<LiveRecord>>((ref) {
  return LiveHistoryNotifier(ref);
});

/// 根据选中的时间区间计算统计数据
final liveStatsProvider = Provider<LiveStats>((ref) {
  final selectedDays = ref.watch(selectedDaysProvider);
  final allRecords = ref.watch(liveHistoryProvider);
  final now = DateTime.now();

  DateTime startDate;
  DateTime endDate;

  if (selectedDays == 0) {
    // 今日：从今天 00:00:00 到 23:59:59
    startDate = DateTime(now.year, now.month, now.day);
    endDate = startDate.add(Duration(days: 1)).subtract(Duration(seconds: 1));
  } else {
    // 前N天：从今天往前(N-1)天，到今天 23:59:59
    // 前7天 = 今天 + 往前6天（共7天）
    // 前30天 = 今天 + 往前29天（共30天）
    startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: selectedDays - 1));
    endDate = DateTime(now.year, now.month, now.day).add(Duration(days: 1)).subtract(Duration(seconds: 1));
  }

  // 过滤时间区间内的直播记录
  final filteredRecords = allRecords.where((record) {
    return record.startTime.isAfter(startDate.subtract(Duration(seconds: 1))) && record.startTime.isBefore(endDate.add(Duration(seconds: 1)));
  }).toList();

  // 计算统计数据
  int totalDiamonds = 0;
  int totalViewers = 0;
  int totalFans = 0;
  int totalDuration = 0;

  for (final record in filteredRecords) {
    totalDiamonds += record.diamonds;
    totalViewers += record.viewers;
    totalFans += record.newFans;
    totalDuration += record.durationMinutes;
  }

  return LiveStats(diamonds: totalDiamonds, viewers: totalViewers, fans: totalFans, durationMinutes: totalDuration);
});

// ==================== UI 组件 ====================

class ApplyPage extends ConsumerWidget {
  const ApplyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        LiveStreamingData(),
        _buildText(
          context,
          label: ' 充值',
          icon: MyIcons.topup,
          iconColor: Colors.redAccent,
          onTap: () {
            print('充值');
          },
        ),
        _buildText(
          context,
          label: "收藏",
          icon: MyIcons.collection,
          iconColor: const Color.fromARGB(255, 241, 231, 25),
          onTap: () {
            print('收藏');
          },
        ),
        _buildText(
          context,
          label: "历史记录",
          icon: MyIcons.history,
          iconColor: const Color.fromARGB(255, 204, 204, 8),
          onTap: () {
            print('历史记录');
          },
        ),
      ],
    );
  }

  Widget _buildText(BuildContext context, {required String label, required VoidCallback onTap, required IconData icon, required Color iconColor}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        margin: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 5, spreadRadius: 1)],
          color: Colors.white,
        ),
        child: Padding(
          padding: EdgeInsets.only(left: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, size: 23, color: iconColor),
              SizedBox(width: 10),
              Text(label, style: TextStyle(fontSize: 15, color: Colors.black)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 直播数据统计组件
class LiveStreamingData extends ConsumerWidget {
  const LiveStreamingData({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDays = ref.watch(selectedDaysProvider);
    final stats = ref.watch(liveStatsProvider);
    final data = stats.toDisplayMap();

    return Container(
      margin: EdgeInsets.only(left: 10, right: 10, bottom: 10),
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 5, spreadRadius: 1)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(height: 5),
          // 1. 顶部：时间切换标签与入口
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTime(ref, label: '今日', isSelected: selectedDays == 0, value: 0),
              _buildTime(ref, label: '前7天', isSelected: selectedDays == 7, value: 7),
              _buildTime(ref, label: '前30天', isSelected: selectedDays == 30, value: 30),
              InkWell(
                onTap: () {},
                child: Row(
                  children: [
                    Text('数据中心', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
          // 2. 中间：数值行
          Expanded(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildDataValue(data['diamonds']!), _buildDataValue(data['viewers']!), _buildDataValue(data['fans']!), _buildDataValue(data['duration']!)]),
          ),
          // 3. 底部：文字描述行
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildLabel('收获钻石'), _buildLabel('观众人数'), _buildLabel('新增粉丝'), _buildLabel('开播时长')]),
        ],
      ),
    );
  }

  /// 时间标签组件
  Widget _buildTime(WidgetRef ref, {required String label, required bool isSelected, required int value}) {
    return GestureDetector(
      onTap: () => ref.read(selectedDaysProvider.notifier).state = value,
      child: Text(
        label,
        style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.blueAccent : Colors.grey),
      ),
    );
  }

  /// 数值展示组件
  Widget _buildDataValue(String value) {
    return Expanded(
      child: Center(
        child: Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
    );
  }

  /// 底部标签组件
  Widget _buildLabel(String text) {
    return Expanded(
      child: Center(
        child: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
      ),
    );
  }
}
