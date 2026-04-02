//统一管理整个项目的路由
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/config/login_UI.dart';
import 'package:video_live_stream/live_stream_discover/onair_Page.dart';
import 'package:video_live_stream/over_video/end.dart';
import 'package:video_live_stream/start_video/start_video_mian.dart';
import 'package:video_live_stream/live_stream_discover/voice_live_streaming/voicelive_UI/audio_video.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_UI/search_friend.dart';
import 'package:video_live_stream/live_stream_message/message/message_UI/chat_page.dart';
import 'package:video_live_stream/live_stream_message/details_page.dart';
import 'package:video_live_stream/live_stream_message/message/message_UI/message_page.dart';
import 'package:video_live_stream/live_stream_message/message/message_UI/seeting.dart';
import 'package:video_live_stream/live_stream_message/messagepage_main.dart';
import 'package:video_live_stream/main.dart';

class Approute {
  // 1. 定义全局唯一 Key，用于在没有 Context 的地方跳转（比如 Token 失效自动跳登录）
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
  //
  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey, //把GoRouter绑定到全局Navigator
    initialLocation: '/Login', //应用启动时默认进入的页面('/')表示首页
    routes: [
      //登陆按钮路由配置
      GoRoute(path: '/Login', name: 'Login', builder: (context, state) => const Login()),
      //1，首页
      GoRoute(path: '/', name: 'Mylivestream', builder: (context, state) => const Mylivestream()),

      //2,消息(消息Tab)
      GoRoute(
        path: '/message', //路由地址
        name: 'message',
        builder: (context, state) => const MessagePage(),
      ),
      //3. 视频消息列表页
      GoRoute(path: '/VideoMessage', name: 'VideoMessage', builder: (context, state) => const VideoMessagePage()),

      // 4. 聊天详情页（作为子路由，路径不加 /）
      GoRoute(
        path: '/chat/:chatId',
        name: 'chat',
        builder: (context, state) {
          final id = state.pathParameters['chatId'] ?? '';
          return ChatPage(chatId: id);
        },
      ),

      //5. 联系人添加好友(子路由)
      GoRoute(path: '/AddFriend', name: 'AddFriend', builder: (context, state) => const AddFriendPage()),

      //6. 联系人详情页面
      GoRoute(
        path: '/Details/:detailsId',
        name: 'Details',
        builder: (context, state) {
          final id = state.pathParameters['detailsId'] ?? '';
          final isFuren = state.uri.queryParameters['isFuren'] == 'true'; //用于判断当前详情页是聊天页面还是联系人的详情页
          final extra = state.extra as Map<String, dynamic>?;
          return DetailsPage(
            detailsId: id,
            isFuren: isFuren, //
            initialTitle: extra?['title']?.toString(),
            initialAvatar: extra?['avatar']?.toString(),
            initialBgUrl: extra?['bgUrl']?.toString(),
          );
        },
      ),
      //7.联系人的设置页面（子路由）
      GoRoute(path: '/Setting', name: 'Setting', builder: (context, state) => const SettingPage()),

      //8,跳转视频主播
      GoRoute(
        path: '/StartVideo',
        name: 'StartVideo',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          // final roomId = state.pathParameters['roomId']!;
          // 提取具体参数，并提供兜底默认值
          final liveID = data?['id'] ?? "";
          final dynamic rawIsHost = data?['isHost'];
          bool isHostBool = false;

          if (rawIsHost != null) {
            if (rawIsHost is bool) {
              isHostBool = rawIsHost;
            } else if (rawIsHost is String) {
              isHostBool = rawIsHost.toLowerCase() == 'true';
            }
          }
          return StartVideoPage(liveID: liveID, isHost: isHostBool.toString());
        },
      ),
      //9.跳转到语音主播
      GoRoute(
        path: '/AudioViode',
        name: 'AudioViode',
        builder: (context, state) {
          final id = state.extra as Map<String, dynamic>?;
          final audioID = id?['id'] ?? '';
          return AudioViodePage(audioID: audioID);
        },
      ),
      //10.当直播结束后，进入到结算页面，
      GoRoute(
        path: '/End',
        name: 'End',
        builder: (context, state) {
          //接收ID
          final extra = state.extra as Map<String, dynamic>?;
          final audioID = extra?['id'] ?? '';
          //接收传递过来的开播时间
          final startTime = extra?['startTime'] as DateTime? ?? DateTime.now();

          return EndPage(audioID: audioID, startTime: startTime);
        },
      ),
      //11. 从结算页面跳转到直播预览页面
      GoRoute(
        path: '/Onair',
        name: 'Onair',
        builder: (context, state) {
          return OnairPage();
        },
      ),
    ],

    //错误处理：找不到页面时跳转404
    errorBuilder: (context, state) => const Scaffold(body: Center(child: Text('404 Not found'))),
  );
}
