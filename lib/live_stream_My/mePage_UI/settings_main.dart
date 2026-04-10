import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/live_stream_My/meProvider_data/meProvider.dart';
import 'package:video_live_stream/utility/dialogbox.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // 浅灰色背景更像设置页
      appBar: AppBar(
        title: Text('设置'),
        centerTitle: true,
        leading: IconButton(onPressed: () => context.pop(), icon: Icon(Icons.arrow_back)),
      ),
      body: ListView(
        children: [
          _buildGrey(([
            SettingsUI.groupByItems([
              //个人资料
              SettingsItem(
                title: "个人资料",
                onTap: () {
                  context.pushNamed('PersonalProfile');
                },
              ),
              //帐号安全
              SettingsItem(
                title: "帐号安全",
                onTap: () {
                  context.pushNamed('Security');
                },
              ),
            ]),
          ])),
          _buildGrey(([
            SettingsUI.groupByItems([
              //消息通知
              SettingsItem(
                title: "消息通知",
                onTap: () {
                  context.pushNamed('Notification');
                },
              ),
              //隐私设置
              SettingsItem(
                title: "隐私设置",
                onTap: () {
                  context.pushNamed('PrivacySettings');
                },
              ),
            ]),
          ])),
          _buildGrey(([
            SettingsUI.groupByItems([
              //版本更新
              SettingsItem(
                title: "版本更新",
                onTap: () {
                  context.pushNamed('VersionUpdate');
                },
              ),
              //功能介绍
              SettingsItem(
                title: "功能介绍",
                onTap: () {
                  context.pushNamed('FeatureIntroduction');
                },
              ),
            ]),
          ])),
          //退出当前帐号
          InkWell(
            onTap: () => _handLongLogut(context, ref),
            child: Container(
              alignment: Alignment.center,
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.red.withValues(alpha: 0.3)),
              child: Text('退出当前帐号'),
            ),
          ),
        ],
      ),
    );
  }

  //分组容器，增加层次感
  Widget _buildGrey(List<Widget> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
        ),
      ),
      child: Column(children: items),
    );
  }

  //退出登陆逻辑
  void _handLongLogut(BuildContext context, WidgetRef ref) {
    AppDialogs.showconfirmDialog(
      context: context,
      title: '退出账号',
      content: '确定退出当前帐号吗？',
      confirmText: '确定退出',
      isDestructive: true,
      onConfirm: () {
        ref.invalidate(meProvider);
        context.go('Login');
      },
    );
  }
}
