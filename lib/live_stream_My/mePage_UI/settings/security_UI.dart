//帐号安全
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/library.dart';

// ==================== 主页面 ====================
class SecurityPage extends ConsumerWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final security = ref.watch(securityProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(centerTitle: true, title: const Text('帐号安全设置')), //
      body: ListView(
        children: [
          SettingsUI.groupByItems([
            //修改手机号
            SettingsItem(
              title: "修改手机号",
              trailing: security.phone,
              onTap: () {
                context.pushNamed('ChangePhone');
              },
            ),
            //修改密码   需求：历史密码、重复使用限制，长度、英文，数字组合
            SettingsItem(
              title: "修改密码",
              onTap: () {
                context.pushNamed('ChangePassword');
              },
            ),
            //忘记密码   需求：手机号、邮箱、身份验证重置
            SettingsItem(
              title: "忘记密码",
              onTap: () {
                context.pushNamed('ForgotPassword');
              },
            ),
            //设备管理   需求：在哪登的、什么时间、什么设备。可：强制下线、删除陌生设备
            SettingsItem(
              title: "设备管理",
              onTap: () {
                context.pushNamed('DeviceManage');
              },
            ),
            //帐号安全中心
            SettingsItem(
              title: "帐号安全中心",
              onTap: () {
                context.pushNamed('SecurityCenter');
              },
            ),
          ]),
        ],
      ),
    );
  }
}

// ==================== 子页面 1：修改手机号 ====================
class ChangePhonePage extends ConsumerStatefulWidget {
  const ChangePhonePage({super.key});

  @override
  ConsumerState<ChangePhonePage> createState() => _ChangePhonePageState(); //
}

class _ChangePhonePageState extends ConsumerState<ChangePhonePage> {
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _code = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    final p = _phone.text.trim();
    if (!RegExp(r'^\d{11}$').hasMatch(p)) {
      _toast('请先输入有效手机号');
      return;
    }
    final ok = await ref.read(verifyCodeProvider.notifier).sendCode(account: p);
    if (!ok && mounted) {
      _toast('验证码发送失败，请稍后再试');
    } else if (mounted) {
      _toast('验证码已发送');
    }
  }

  @override
  Widget build(BuildContext context) {
    final security = ref.watch(securityProvider);
    final verify = ref.watch(verifyCodeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('修改手机号')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('当前手机号：${security.phone}', style: const TextStyle(color: Colors.grey)), //
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: '新手机号',
              border: OutlineInputBorder(), //
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              //
              labelText: '验证码',
              border: const OutlineInputBorder(),
              suffix: TextButton(onPressed: (verify.canSend && !verify.sending) ? _handleSendCode : null, child: Text(verify.sending ? '发送中...' : (verify.canSend ? '发送验证码' : '${verify.seconds}s'))),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final p = _phone.text.trim();
              final c = _code.text.trim();
              if (!RegExp(r'^\d{11}$').hasMatch(p)) {
                //
                _toast('请输入有效手机号');
                return;
              }
              if (c.length < 4) {
                _toast('验证码格式不正确');
                return;
              }
              ref.read(securityProvider.notifier).updatePhone(p); //
              _toast('手机号修改成功');
              Navigator.pop(context);
            },
            child: const Text('确认修改'),
          ),
        ],
      ),
    );
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); //
  }
}

// ==================== 子页面 2：修改密码 ====================
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState(); //
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final TextEditingController _oldPwd = TextEditingController();
  final TextEditingController _newPwd = TextEditingController();
  final TextEditingController _confirmPwd = TextEditingController();

  @override
  void dispose() {
    _oldPwd.dispose();
    _newPwd.dispose();
    _confirmPwd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final security = ref.watch(securityProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('修改密码')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('密码规则：8-20位，需包含英文和数字，不能重复使用历史密码', style: TextStyle(color: Colors.grey)), //
          const SizedBox(height: 12),
          TextField(
            controller: _oldPwd,
            obscureText: true,
            decoration: const InputDecoration(labelText: '历史密码', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPwd,
            obscureText: true,
            decoration: const InputDecoration(labelText: '新密码', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPwd,
            obscureText: true,
            decoration: const InputDecoration(labelText: '确认新密码', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final old = _oldPwd.text.trim();
              final next = _newPwd.text.trim();
              final confirm = _confirmPwd.text.trim();
              if (next != confirm) {
                _toast('两次新密码不一致');
                return;
              }
              if (!_isStrongPassword(next)) {
                _toast('密码需8-20位，包含英文和数字');
                return;
              }
              if (security.passwordHistory.contains(next) || security.password == next) {
                _toast('新密码不能与历史密码重复');
                return;
              }
              final ok = ref.read(securityProvider.notifier).updatePassword(oldPwd: old, newPwd: next);
              if (!ok) {
                _toast('历史密码不正确');
                return;
              }
              _toast('密码修改成功');
              Navigator.pop(context);
            },
            child: const Text('确认修改'),
          ),
        ],
      ),
    );
  }

  bool _isStrongPassword(String pwd) {
    if (pwd.length < 8 || pwd.length > 20) return false;
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(pwd);
    final hasNumber = RegExp(r'\d').hasMatch(pwd);
    return hasLetter && hasNumber;
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

// ==================== 子页面 3：忘记密码 ====================
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  int _tab = 0; // 0 手机号 1 邮箱 2 身份验证
  final TextEditingController _account = TextEditingController();
  final TextEditingController _verify = TextEditingController();
  final TextEditingController _newPwd = TextEditingController();

  @override
  void dispose() {
    _account.dispose();
    _verify.dispose();
    _newPwd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['手机号重置', '邮箱重置'];
    return Scaffold(
      appBar: AppBar(title: const Text('忘记密码')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<int>(
            segments: [for (int i = 0; i < labels.length; i++) ButtonSegment<int>(value: i, label: Text(labels[i]))],
            selected: {_tab},
            onSelectionChanged: (set) {
              setState(() => _tab = set.first);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _account,
            decoration: InputDecoration(
              labelText: _tab == 0 ? '手机号' : ('邮箱'), //
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _verify,
            decoration: const InputDecoration(labelText: '验证码', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPwd,
            obscureText: true,
            decoration: const InputDecoration(labelText: '新密码', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final account = _account.text.trim();
              final verify = _verify.text.trim();
              final newPwd = _newPwd.text.trim();
              if (account.isEmpty || verify.isEmpty || newPwd.isEmpty) {
                _toast('请填写完整信息');
                return;
              }
              if (!_isStrongPassword(newPwd)) {
                _toast('新密码需8-20位，包含英文和数字');
                return;
              }
              ref.read(securityProvider.notifier).resetPassword(newPwd);
              _toast('密码已重置成功');
              Navigator.pop(context);
            },
            child: const Text('确认重置'),
          ),
        ],
      ),
    );
  }

  bool _isStrongPassword(String pwd) {
    if (pwd.length < 8 || pwd.length > 20) return false;
    return RegExp(r'[A-Za-z]').hasMatch(pwd) && RegExp(r'\d').hasMatch(pwd);
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); //
  }
}

// ==================== 子页面 4：设备管理 ====================
class DeviceManagePage extends ConsumerStatefulWidget {
  const DeviceManagePage({super.key});

  @override
  ConsumerState<DeviceManagePage> createState() => _DeviceManagePageState();
}

class _DeviceManagePageState extends ConsumerState<DeviceManagePage> {
  @override
  void initState() {
    super.initState();
    // 页面首次进入再触发设备识别，避免插件初始化时机导致 MissingPluginException
    Future<void>.microtask(() {
      ref.read(securityProvider.notifier).ensureCurrentDeviceLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final security = ref.watch(securityProvider);
    final devices = security.devices;
    return Scaffold(
      appBar: AppBar(
        title: const Text('设备管理'),
        actions: [
          TextButton(
            onPressed: security.deviceLoading
                ? null
                : () {
                    ref.read(securityProvider.notifier).reloadCurrentDevice();
                  },
            child: Text(security.deviceLoading ? '识别中...' : '重试识别设备'),
          ),
        ],
      ),
      body: ListView(
        children: [
          if (security.deviceLoading) const Padding(padding: EdgeInsets.fromLTRB(16, 12, 16, 0), child: LinearProgressIndicator(minHeight: 3)),
          if (security.deviceError.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFF3F3), borderRadius: BorderRadius.circular(10)),
              child: Text(security.deviceError, style: const TextStyle(color: Color(0xFFD32F2F))),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Text('登录设备', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    ref.read(securityProvider.notifier).removeUnknownDevices(); //
                  },
                  child: const Text('删除陌生设备'),
                ),
              ],
            ),
          ),
          if (devices.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('暂无设备数据，请点击右上角重试识别设备')),
          for (final d in devices)
            ListTile(
              title: Text(d.deviceName),
              subtitle: Text('${d.location}  ·  ${d.loginTime}'),
              trailing: d.isCurrent
                  ? const Text('当前设备', style: TextStyle(color: Colors.green)) //
                  : TextButton(
                      onPressed: () {
                        ref.read(securityProvider.notifier).forceOffline(d.id);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已强制该设备下线')));
                      },
                      child: const Text('强制下线'),
                    ),
            ),
        ],
      ),
    );
  }
}

// ==================== 子页面 5：帐号安全中心 ====================
class SecurityCenterPage extends ConsumerWidget {
  const SecurityCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final security = ref.watch(securityProvider);
    final score = _calcScore(security);
    return Scaffold(
      appBar: AppBar(title: const Text('帐号安全中心')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xffEAF5FF), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '安全评分',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), //
                ),
                const SizedBox(height: 8),
                Text('$score 分', style: const TextStyle(fontSize: 28, color: Colors.blue)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            title: const Text('登录保护'),
            subtitle: const Text('新设备登录需要二次验证'),
            value: security.loginProtect,
            onChanged: (v) => ref.read(securityProvider.notifier).toggleLoginProtect(v), //
          ),
          SwitchListTile(
            title: const Text('支付保护'),
            subtitle: const Text('敏感操作需要密码验证'),
            value: security.payProtect,
            onChanged: (v) => ref.read(securityProvider.notifier).togglePayProtect(v), //
          ),
          ListTile(title: const Text('最近安全建议'), subtitle: const Text('建议定期更换密码，并开启登录保护')),
        ],
      ),
    );
  }

  int _calcScore(SecurityState s) {
    int score = 60;
    if (s.loginProtect) score += 15;
    if (s.payProtect) score += 15;
    if (s.password.length >= 8) score += 10;
    return score.clamp(0, 100);
  }
}
