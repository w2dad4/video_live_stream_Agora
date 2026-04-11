// 直播项目配置中心 - Agora 声网版本
class LiveConfig {
  /// 为 `true` 时：只做本地校验（手机号格式 + 密码长度），**不请求**登录接口即可进入主页，方便调 UI。
  /// 接上真实后端后请改为 `false`，并保证本机可访问 `http://<serverIP>:8000/api/v1/login` 且返回 `code == 0`。
  static const bool bypassLoginApi = true;
  static const String _agoraTokenServerFromDefine = String.fromEnvironment(
    'AGORA_TOKEN_SERVER',
    defaultValue: '',
  );

  // ==================== Agora 声网配置 ====================

  /// ⚠️ 重要：请替换为你的 Agora App ID
  /// 获取方式：访问 https://console.agora.io/ 注册账号并创建项目
  static const String agoraAppId = '5523e1ece1e84adb82c69c121b500a39';

  /// Agora Token（可选）
  /// 开发阶段可留空（使用 App ID 鉴权）
  /// 生产环境建议使用 Token 鉴权更安全
  static const String agoraToken = '';

  /// 直播频道前缀
  static const String channelPrefix = 'live_';

  /// 对主播 UID / 直播间业务 ID 做统一清洗。
  /// 作用：
  /// 1. 去掉首尾空格
  /// 2. 避免出现空频道
  /// 3. 让上层传来的主播 ID 和 Agora 真正频道号保持稳定映射
  static String normalizeLiveRoomSeed(String roomId) {
    final seed = roomId.trim();
    return seed.isEmpty ? 'unknown_host' : seed;
  }

  /// 生成 Agora 真正使用的频道名。
  /// 约定：
  /// 一个主播 = 一个固定频道。
  /// 例如主播 UID 是 `me_123`，那么频道名就是 `live_me_123`。
  static String getChannelName(String roomId) {
    final normalizedRoomId = normalizeLiveRoomSeed(roomId);
    return '$channelPrefix$normalizedRoomId';
  }

  /// Agora Token 服务开发环境地址。
  /// 当前是本机局域网地址，只适合同一局域网设备调试。
  static const String agoraTokenServerDevBaseUrl = 'http://192.168.1.18:8080';

  /// Agora Token 服务生产环境地址。
  /// 当你的 Node Token 服务部署到公网后，这里改成正式域名即可。
  static const String agoraTokenServerProdBaseUrl =
      'https://api.yourdomain.com';

  /// Agora Token 服务基础地址。
  /// 优先级：
  /// 1. `--dart-define=AGORA_TOKEN_SERVER=...`
  /// 2. 开发/生产环境默认地址
  ///
  /// 作用：
  /// 不同网络的用户想加入同一个频道，前提是都能访问同一个公网 Token 服务。
  static String get agoraTokenServerBaseUrl {
    if (_agoraTokenServerFromDefine.isNotEmpty) {
      return _agoraTokenServerFromDefine;
    }
    return bypassLoginApi
        ? agoraTokenServerDevBaseUrl
        : agoraTokenServerProdBaseUrl;
  }

  /// Agora Token 生成接口。
  static String get agoraTokenUrl =>
      '$agoraTokenServerBaseUrl/api/v1/agora/token';

  /// 当前主播默认房间号同步接口。
  /// 浏览器测试页会通过这个接口自动带出真实房间号。
  static String get agoraDefaultRoomUrl =>
      '$agoraTokenServerBaseUrl/api/v1/agora/default-room';

  // ==================== 直播质量配置 ====================

  /// 视频编码配置
  static const int videoBitrate = 1500; // kbps
  static const int videoFrameRate = 30; // fps
  static const int videoWidth = 1280; // 720p
  static const int videoHeight = 720;

  /// 音频配置
  static const int audioBitrate = 32; // kbps
  static const int audioSampleRate = 48000; // Hz
}
