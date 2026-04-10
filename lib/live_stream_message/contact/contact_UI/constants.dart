import 'dart:io';

//直播项目定义的流媒体服务器配置中心。它主要负责生成和管理直播推流（发送视频）和拉流（播放视频）所需要的各种网络地址（URL）。
class LiveConfig {
  /// 为 `true` 时：只做本地校验（手机号格式 + 密码长度），**不请求**登录接口即可进入主页，方便调 UI。
  /// 接上真实后端后请改为 `false`，并保证本机可访问 `http://<serverIP>:8000/api/v1/login` 且返回 `code == 0`。
  static const bool bypassLoginApi = true;

  static const String _serverFromDefine = String.fromEnvironment('LIVE_SERVER_IP', defaultValue: '');
  static const int apiPort = 1985;
  static const int hlsPort = 8080;
  static const String appName = 'live';

  static String get serverIP {
    if (_serverFromDefine.isNotEmpty) return _serverFromDefine;
    if (Platform.isAndroid || Platform.isIOS) return '192.168.1.29';
    return 'localhost';
  }

  static Uri whipUri(String streamID) {
    return Uri(
      scheme: 'http',
      host: serverIP,
      port: apiPort, //
      path: '/rtc/v1/whip/',
      queryParameters: {'app': appName, 'stream': streamID},
    );
  }

  static Uri whepUri(String streamID) {
    return Uri(
      scheme: 'http',
      host: serverIP,
      port: apiPort, //
      path: '/rtc/v1/whep/',
      queryParameters: {'app': appName, 'stream': streamID},
    );
  }

  static Uri hlsUri(String streamID) {
    return Uri(
      scheme: 'http',
      host: serverIP, //
      port: hlsPort,
      path: '/$appName/$streamID.m3u8',
    );
  }

  static String get whipUrl => whipUri('test').toString();
  static String get hlsUrl => hlsUri('test').toString();
}
