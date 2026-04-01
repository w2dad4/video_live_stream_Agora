import 'dart:io';

class LiveConfig {
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
