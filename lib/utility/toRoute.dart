//统一管理整个项目的路由
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/library.dart';

class Approute {
  // 1. 定义全局唯一 Key，用于在没有 Context 的地方跳转（比如 Token 失效自动跳登录）
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
  static String initialLocation = '/Login';
  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey, //把GoRouter绑定到全局Navigator
    initialLocation: initialLocation,
    routes: [
      // ==================== 认证模块路由 ====================
      // 登录页：未登录时的默认入口
      GoRoute(path: '/Login', name: 'Login', builder: (context, state) => const Login()),
      GoRoute(path: '/NumberLogin', name: 'NumberLogin', builder: (context, state) => const NumberLoginPage()),
      // 引导页：新用户注册后展示
      GoRoute(path: '/Onboarding', name: 'Onboarding', builder: (context, state) => const OnboardingPage()),
      // ==================== 主框架路由 ====================
      // 首页：主容器页面（底部导航）
      GoRoute(path: '/', name: 'Mylivestream', builder: (context, state) => const Mylivestream()),

      // 消息 Tab：仅消息列表页
      GoRoute(
        path: '/message', //路由地址
        name: 'message',
        builder: (context, state) => const MessagePage(),
      ),
      // 视频消息主页：包含「消息/联系人」双 Tab
      GoRoute(path: '/VideoMessage', name: 'VideoMessage', builder: (context, state) => const VideoMessagePage()),

      // ==================== 聊天模块路由 ====================
      // 聊天页：根据 chatId 进入对应会话
      GoRoute(
        path: '/chat/:chatId',
        name: 'chat',
        builder: (context, state) {
          final id = state.pathParameters['chatId'] ?? '';
          return ChatPage(chatId: id);
        },
      ),

      // ==================== 联系人模块路由 ====================
      // 添加好友入口页
      GoRoute(path: '/AddFriend', name: 'AddFriend', builder: (context, state) => const AddFriendPage()),
      // 扫码页
      GoRoute(path: '/ScanQr', name: 'ScanQr', builder: (context, state) => const ScanQrPage()),
      // 新建群聊页
      GoRoute(path: '/NewGroupChat', name: 'NewGroupChat', builder: (context, state) => const NewGroupChatPage()),
      // 面对面建群页
      GoRoute(path: '/FaceToFaceGroup', name: 'FaceToFaceGroup', builder: (context, state) => const FaceToFaceGroupPage()),
      // 新朋友页
      GoRoute(path: '/NewFriends', name: 'NewFriends', builder: (context, state) => const NewFriendsPage()),
      // 我的群聊总入口页（联系人页点击「群聊」进入）
      GoRoute(path: '/GroupChatHub', name: 'GroupChatHub', builder: (context, state) => const GroupChatHubPage()),
      // 群聊信息页（群名称/公告/备注/免打扰等）
      GoRoute(
        path: '/GroupInfo/:groupId',
        name: 'GroupInfo',
        builder: (context, state) {
          final id = state.pathParameters['groupId'] ?? '';
          return GroupInfoPage(groupId: id);
        },
      ),
      // 群成员页（查看成员、群主管理员管理）
      GoRoute(
        path: '/GroupMembers/:groupId',
        name: 'GroupMembers',
        builder: (context, state) {
          final id = state.pathParameters['groupId'] ?? '';
          return GroupMembersPage(groupId: id);
        },
      ),

      // 联系人详情页（私聊对象详情）
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
      // 联系人设置页（详情页右上角进入）
      GoRoute(path: '/Setting', name: 'Setting', builder: (context, state) => const SettingPage()),

      // ==================== 直播模块路由 ====================
      // 视频开播/进房页
      GoRoute(
        path: '/StartVideo',
        name: 'StartVideo',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          // final roomId = state.pathParameters['roomId']!;
          // 提取具体参数，并提供兜底默认值
          final liveID = data?['id'] ?? "";
          final dynamic rawIsHost = data?['isHost'];
          final dynamic rawAutoStart = data?['autoStart'];
          bool isHostBool = false;
          bool autoStartBool = false;

          if (rawIsHost != null) {
            if (rawIsHost is bool) {
              isHostBool = rawIsHost;
            } else if (rawIsHost is String) {
              isHostBool = rawIsHost.toLowerCase() == 'true';
            }
          }

          if (rawAutoStart != null) {
            if (rawAutoStart is bool) {
              autoStartBool = rawAutoStart;
            } else if (rawAutoStart is String) {
              autoStartBool = rawAutoStart.toLowerCase() == 'true';
            }
          }

          return StartVideoPage(liveID: liveID, isHost: isHostBool.toString(), autoStart: autoStartBool);
        },
      ),

      // 语音直播页
      GoRoute(
        path: '/AudioViode',
        name: 'AudioViode',
        builder: (context, state) {
          final id = state.extra as Map<String, dynamic>?;
          final audioID = id?['id'] ?? '';
          return AudioViodePage(audioID: audioID);
        },
      ),

      // 结算页（直播结束后跳转）
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

      // 直播预览页（从结算页返回）
      GoRoute(
        path: '/Onair',
        name: 'Onair',
        builder: (context, state) {
          return OnairPage();
        },
      ),

      // 主播已结束直播页（观众端显示）
      GoRoute(
        path: '/Conclude',
        name: 'Conclude',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return Conclude(hostName: extra?['hostName'] ?? '主播', hostAvatar: extra?['hostAvatar']?.toString(), roomId: extra?['roomId']?.toString() ?? '');
        },
      ),
      // ==================== 我的模块路由 ====================
      GoRoute(path: '/Settings', name: 'Settings', builder: (context, state) => const SettingsPage()),
      GoRoute(path: '/PersonalProfile', name: 'PersonalProfile', builder: (context, state) => const PersonalProfile()),
      GoRoute(path: '/Security', name: 'Security', builder: (context, state) => const SecurityPage()),
      GoRoute(path: '/ChangePhone', name: 'ChangePhone', builder: (context, state) => const ChangePhonePage()), //修改手机号
      GoRoute(path: '/ChangePassword', name: 'ChangePassword', builder: (context, state) => const ChangePasswordPage()), //修改密码
      GoRoute(path: '/ForgotPassword', name: 'ForgotPassword', builder: (context, state) => const ForgotPasswordPage()), //忘记密码
      GoRoute(path: '/DeviceManage', name: 'DeviceManage', builder: (context, state) => const DeviceManagePage()), //设备管理
      GoRoute(path: '/SecurityCenter', name: 'SecurityCenter', builder: (context, state) => const SecurityCenterPage()), //帐号安全中心
      GoRoute(path: '/Notification', name: 'Notification', builder: (context, state) => const NotificationPage()), //消息通知
      GoRoute(path: '/PrivacySettings', name: 'PrivacySettings', builder: (context, state) => const PrivacySettingsPage()), //隐私设置
      GoRoute(path: '/PrivacyPolicy', name: 'PrivacyPolicy', builder: (context, state) => const PrivacyPolicyPage()), //隐私政策
      GoRoute(path: '/UserAgreement', name: 'UserAgreement', builder: (context, state) => const UserAgreementPage()), //用户协议
      GoRoute(path: '/AboutUs', name: 'AboutUs', builder: (context, state) => const AboutUsPage()), //关于我们
      GoRoute(path: '/PersonalInfoProtection', name: 'PersonalInfoProtection', builder: (context, state) => const PersonalInfoProtectionPage()), //个人信息保护
      GoRoute(path: '/VersionUpdate', name: 'VersionUpdate', builder: (context, state) => const VersionUpdatePage()), //版本更新
      GoRoute(path: '/FeatureIntroduction', name: 'FeatureIntroduction', builder: (context, state) => const FeatureIntroduction()), //功能介绍
    ],

    //错误处理：找不到页面时跳转404
    errorBuilder: (context, state) => const Scaffold(body: Center(child: Text('404 Not found'))),
  );
}
