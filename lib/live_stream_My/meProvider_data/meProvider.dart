// 模拟当前登录用户的信息
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:video_live_stream/features/auth/auth_provider.dart';
import 'package:video_live_stream/live_stream_discover/select_Album/dialogbox.dart';
import 'package:video_live_stream/services/live_room_service.dart';

/// 🔐 当前登录用户信息（带数据隔离）
/// 返回 null 表示未登录
final meProvider = Provider<UserMe?>((ref) {
  final userData = ref.watch(currentUserDataProvider);
  if (userData == null) return null;
  
  return UserMe(
    uid: userData.uid,
    name: userData.name,
    avatar: userData.avatar ?? 'assets/image/002.png',
    ip: 'null',
    gender: userData.gender,
    region: userData.region,
    signature: userData.signature,
  );
});

class UserMe {
  final String? uid;
  final String? name;
  final String? avatar;
  final String? ip;
  final String? gender; // 性别
  final String? region; // 地区
  final String? signature; // 个性签名
  // ignore: non_constant_identifier_names
  UserMe({
    required this.uid,
    required this.name,
    this.avatar,
    this.ip,
    this.gender = '未设置',
    this.region = '未设置',
    this.signature = '这个人很懒，还没有签名', //
  });

  UserMe copyWith({
    String? avatar,
    String? name,
    String? gender,
    String? region,
    String? signature, //
  }) {
    return UserMe(
      uid: uid,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      ip: ip,
      gender: gender ?? this.gender, //
      region: region ?? this.region,
      signature: signature ?? this.signature,
    );
  }
}

//暂且用直播数据
// 定义当前选中的类型：0(今日), 7(前7天), 30(前30天)
final selectedDeysProvider = StateProvider<int>((ref) => 0);
// 根据选中的天数，模拟返回不同的直播数据
final liveStatesProvider = Provider((ref) {
  final days = ref.watch(selectedDeysProvider);
  // 实际业务中这里会从 API 获取数据，这里先写死模拟数据
  if (days == 7) {
    return {'diamonds': '1,200', 'viewers': '800', 'fans': '50', 'duration': '15h'};
  } else if (days == 30) {
    return {'diamonds': '5,800', 'viewers': '3,200', 'fans': '210', 'duration': '60h'};
  } else {
    return {'diamonds': '120', 'viewers': '45', 'fans': '3', 'duration': '1.5h'};
  }
});

// 1. 直播详情模型：只关注直播业务
class LiveDataMode {
  final String liveID; //直播间ID
  final String title; //直播标题
  final String hostName; // 主播名字（来自 UserMe）
  final String hostAvarat; //主播的头像（来自 UserMe）
  final int watchCount; //实时观看人数
  final bool isRecording; //是否正在录制
  LiveDataMode({
    required this.liveID,
    required this.title,
    required this.hostName, //
    required this.hostAvarat,
    this.watchCount = 0,
    this.isRecording = false,
  });
}

// 2. 定义聚合 Provider
// 它监听 meProvider 和 liveTitleProvider，生成最终的直播间详情
final liveDataProvider = Provider.family<LiveDataMode, String>((ref, liveID) {
  //监听当前登录用户的信息
  final me = ref.watch(meProvider);
  // 监听在准备页面设置的标题 (family 参数需要匹配，假设为 LiveMode.video)
  final title = ref.watch(liveTitleProvider(LiveMode.video));
  // 组合成直播间专用的模型
  return LiveDataMode(
    liveID: liveID, 
    title: title, 
    hostName: me?.name ?? "", 
    hostAvarat: me?.avatar ?? '', 
    watchCount: 0
  );
});

/// 🎯 服务端在线人数 Provider（每5秒轮询一次）
/// 基于服务端 Set 统计，自动去重，不会重复计数
final onlineCountProvider = StreamProvider.family<int, String>((ref, roomId) async* {
  // 初始值
  yield 0;

  // 创建定时器，每5秒获取一次
  final timer = Stream.periodic(const Duration(seconds: 5));

  await for (final _ in timer) {
    try {
      final count = await LiveRoomService.getOnlineCount(roomId);
      yield count;
    } catch (e) {
      // 出错时保持上次值，不中断流
      print('👥 [OnlineCount] 获取失败: $e');
    }
  }
});

//数据类，定义了一个直播间在推荐列表中显示时所需的所有信息
class LiveRecommndItem {
  final String liveID; //唯一标识符
  final String title; //标题
  final String hostname; //主播名称
  final String cover; //封面
  final String region; //地区
  final DateTime startedAt;
  final int watchCount; // 观看人数
  LiveRecommndItem({
    required this.liveID,
    required this.title,
    required this.hostname, //
    required this.cover,
    required this.region,
    required this.startedAt,
    this.watchCount = 0,
  });
  //copyWith 方法：这是 Flutter 中处理不可变数据的标准做法
  LiveRecommndItem copyWith({
    String? hostname,
    String? title,
    String? cover, //
    String? region,
    DateTime? startedAt,
    int? watchCount,
  }) {
    return LiveRecommndItem(
      liveID: liveID,
      title: title ?? this.title,
      hostname: hostname ?? this.hostname,
      cover: cover ?? this.cover,
      region: region ?? this.region,
      startedAt: startedAt ?? this.startedAt, //
      watchCount: watchCount ?? this.watchCount,
    );
  }
}

//这是整个逻辑的“大脑”，负责列表的增删改
class LiveRecommendNotifier extends StateNotifier<List<LiveRecommndItem>> {
  LiveRecommendNotifier() : super(const []);

  void startUpdata({
    required String liveID,
    required String hostname, //
    required String title,
    required String cover,
    required String region,
  }) {
    final idx = state.indexWhere((e) => e.liveID == liveID);
    final item = LiveRecommndItem(
      liveID: liveID,
      title: title, //
      hostname: hostname,
      cover: cover,
      region: region,
      startedAt: DateTime.now(),
    );
    //如果 liveID 在现有列表中找不到（idx < 0），它会将这个新主播放在列表的最前面
    if (idx < 0) {
      state = [item, ...state];
    } else {
      final next = [...state];
      next[idx] = next[idx].copyWith(hostname: hostname, cover: cover, region: region, title: title);
      state = next;
    }
  }

  void stop(String liveID) {
    state = state.where((e) => e.liveID != liveID).toList();
  }
}

final liverecommendProvider = StateNotifierProvider<LiveRecommendNotifier, List<LiveRecommndItem>>((ref) => LiveRecommendNotifier());
