import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/config/login/login_provider.dart';
import 'package:video_live_stream/config/toppop-up.dart';
import 'package:video_live_stream/features/auth/auth_provider.dart';

/// 手机验证码登录页面
class NumberLoginPage extends ConsumerStatefulWidget {
  const NumberLoginPage({super.key});

  @override
  ConsumerState<NumberLoginPage> createState() => _NumberLoginState();
}

class _NumberLoginState extends ConsumerState<NumberLoginPage> with SingleTickerProviderStateMixin {
  late AnimationController _liquidController;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _liquidController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _restoreSavedAccount();
  }

  /// 回填上次登录成功的手机号
  Future<void> _restoreSavedAccount() async {
    final account = await readSavedUserAccount();
    if (!mounted || account == null) return;
    _phoneController.text = account;
  }

  @override
  void dispose() {
    _liquidController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 发送验证码 - 调用 Provider
  void _sendVerificationCode() {
    final phone = _phoneController.text.trim();
    ref.read(smsCodeProvider.notifier).sendCode(phone);
  }

  /// 执行注册/登录 - 调用 Provider
  void _handleLogin() {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // 验证手机号
    final phoneRegex = RegExp(r'^1\d{10}$');
    if (!phoneRegex.hasMatch(phone)) {
      ToastUtil.showRedError(context, '格式错误', '请输入11位手机号');
      return;
    }

    // 验证验证码
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      ToastUtil.showRedError(context, '格式错误', '请输入6位数字验证码');
      return;
    }

    // 验证密码（8-20位，包含字母和数字）
    if (password.length < 8 || password.length > 20) {
      ToastUtil.showRedError(context, '密码太短', '密码长度需8-20位');
      return;
    }
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(password)) {
      ToastUtil.showRedError(context, '密码格式错误', '密码需包含字母和数字');
      return;
    }

    // 验证确认密码
    if (password != confirmPassword) {
      ToastUtil.showRedError(context, '密码不匹配', '两次输入的密码不一致');
      return;
    }

    // 调用注册 API（phone + code + password）
    ref.read(smsRegisterProvider.notifier).register(phone, code, password);
  }

  @override
  Widget build(BuildContext context) {
    // 监听验证码发送状态
    final smsCodeState = ref.watch(smsCodeProvider);
    // 监听验证码注册状态
    final smsRegisterState = ref.watch(smsRegisterProvider);

    // 监听注册结果 - 注册成功后设置用户ID并跳转到引导页
    ref.listen<AsyncValue<void>>(smsRegisterProvider, (previous, next) {
      next.whenOrNull(
        data: (_) async {
          // 设置当前用户ID，使userDataProvider能加载用户数据
          final phone = _phoneController.text.trim();
          ref.read(currentUserIdProvider.notifier).state = phone;

          // 初始化用户数据（从本地存储）
          final userNotifier = ref.read(userDataProvider(phone).notifier);
          await userNotifier.loadUserData();

          if (mounted) {
            context.goNamed('Onboarding');
          }
        },
        error: (error, stackTrace) => ToastUtil.showRedError(context, '注册失败', error.toString()),
      );
    });

    // 监听验证码发送结果
    ref.listen<SmsCodeState>(smsCodeProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ToastUtil.showRedError(context, '发送失败', next.error!);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xffC06C84),
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          '手机号登录',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // 1. 底层：流动的彩色"墨水"
          AnimatedBuilder(
            animation: _liquidController,
            builder: (context, child) {
              return Stack(
                children: [
                  _buildDynamicBlob(color: const Color(0xffFF9CDA).withValues(alpha: 0.7), size: 550, motion: (double t) => Offset(0.8 * math.cos(t), 0.6 * math.sin(t))),
                  _buildDynamicBlob(color: const Color(0xffFFB09C), size: 600, motion: (double t) => Offset(0.9 * math.sin(2 * t), 0.7 * math.sin(t + math.pi / 4))),
                  _buildDynamicBlob(color: const Color(0xffE25287).withValues(alpha: 0.5), size: 450, motion: (double t) => Offset(0.4 + 0.5 * math.cos(t * 0.5), -0.3 + 0.5 * math.sin(t * 0.5))),
                ],
              );
            },
          ),

          // 2. 中层：强力模糊滤镜
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.transparent),
            ),
          ),

          // 3. 顶层：清晰的交互表单
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 25), child: _buildLoginForm(smsCodeState, smsRegisterState)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建单个不规则运动的色块
  Widget _buildDynamicBlob({required Color color, required double size, required Offset Function(double t) motion}) {
    final double t = _liquidController.value * 2 * math.pi;
    final Offset alignmentOffset = motion(t);

    return Align(
      alignment: Alignment(alignmentOffset.dx, alignmentOffset.dy),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }

  // 注册表单
  Widget _buildLoginForm(SmsCodeState smsCodeState, AsyncValue<void> smsRegisterState) {
    return Container(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: IntrinsicHeight(
        child: Column(
          children: [
            const SizedBox(height: 50),

            // 手机号输入框
            _frosted(
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                decoration: const InputDecoration(
                  labelText: '手机号',
                  border: InputBorder.none,
                  counterText: '',
                  prefixIcon: Icon(Icons.phone_android, color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 验证码输入框（带发送按钮）
            _frosted(
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: '验证码',
                        border: InputBorder.none,
                        counterText: '',
                        prefixIcon: Icon(Icons.message, color: Colors.white70),
                      ),
                    ),
                  ),
                  // 发送验证码按钮
                  GestureDetector(
                    onTap: smsCodeState.canSend && !smsCodeState.isSending ? _sendVerificationCode : null,
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: smsCodeState.canSend && !smsCodeState.isSending ? const Color(0xffFF5391) : Colors.grey.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
                      child: smsCodeState.isSending
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              smsCodeState.canSend ? '获取验证码' : '${smsCodeState.countdown}s',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 密码输入框
            _frosted(
              TextField(
                controller: _passwordController,
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                decoration: const InputDecoration(
                  labelText: '设置密码',
                  hintText: '8-20位，包含字母和数字',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.lock_outline, color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 确认密码输入框
            _frosted(
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                decoration: const InputDecoration(
                  labelText: '确认密码',
                  hintText: '再次输入密码',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.lock, color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 40),
            // 注册按钮
            _buildActionButtons(smsRegisterState),
            const Spacer(),
            // 底部链接
            _buildBottomLinks(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 毛玻璃输入框
  Widget _frosted(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  // 注册按钮
  Widget _buildActionButtons(AsyncValue<void> smsRegisterState) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xffFF5391),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        onPressed: smsRegisterState.isLoading ? null : _handleLogin,
        child: smsRegisterState.isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text(
                '注 册',
                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  // 底部链接
  Widget _buildBottomLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () => context.pop(), // 返回账号密码登录
          child: const Text('密码登录', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}
