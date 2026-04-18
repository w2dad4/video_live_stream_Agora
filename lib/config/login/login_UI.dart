import 'dart:ui';
import 'dart:math' as math; // 必须引入，用于计算流动曲线
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_live_stream/config/login/login_provider.dart';
import 'package:video_live_stream/config/toppop-up.dart';
import 'package:video_live_stream/features/auth/auth_provider.dart';

class Login extends ConsumerStatefulWidget {
  const Login({super.key});

  @override
  ConsumerState<Login> createState() => LoginState();
}

class LoginState extends ConsumerState<Login> with SingleTickerProviderStateMixin {
  late AnimationController _liquidController;
  final TextEditingController _phoneController = TextEditingController(); //帐号验证
  final TextEditingController _passwordController = TextEditingController(); //密码验证

  @override
  void initState() {
    super.initState();
    // 15秒循环一次，确保流动极其缓慢、优雅
    _liquidController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _restoreSavedAccount();
  }

  /// 回填上次登录成功的账号（持久化在 SharedPreferences）。
  Future<void> _restoreSavedAccount() async {
    final account = await readSavedUserAccount();
    if (!mounted || account == null) return;
    _phoneController.text = account;
  }

  // 执行校验并登录
  void _handLogin() {
    final account = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    //帐号验证11位数字
    final phoneRegex = RegExp(r'^1\d{10}$');
    if (!phoneRegex.hasMatch(account)) {
      ToastUtil.showRedError(context, '格式错误', '请输入11位手机号');
      return;
    }

    //密码校验是否大于8位
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码必须大于八位')));
      return;
    }
    // 3. 校验通过
    ref.read(loginProvider.notifier).login(account, password);
  }

  @override
  void dispose() {
    _liquidController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);
    ref.listen<AsyncValue<void>>(loginProvider, (previous, next) {
      next.whenOrNull(
        data: (_) async {
          final userId = await ensureUserId();
          ref.read(currentUserIdProvider.notifier).state = userId;
          await ref.read(userDataProvider(userId).notifier).loadUserData();
          final isNewUser = await readIsNewUser(userId: userId);
          final completed = await readProfileCompleted(userId: userId);
          if (!context.mounted) return;
          // 新用户或未完善资料的用户进入资料完善页，老用户直接进入首页
          context.goNamed((isNewUser || !completed) ? 'Onboarding' : 'Mylivestream');
        },
        error: (error, stackTrace) => ToastUtil.showRedError(context, '登陆失败', error.toString()),
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xffC06C84), // 基础背景色（深玫瑰色）
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          '登陆小猫啵啵',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. 底层：流动的彩色“墨水”
          AnimatedBuilder(
            animation: _liquidController,
            builder: (context, child) {
              return Stack(
                children: [
                  _buildDynamicBlob(
                    color: const Color(0xffFF9CDA).withValues(alpha: 0.7),
                    size: 550,
                    motion: (double t) => Offset(
                      0.8 * math.cos(t), // x 轴大幅晃动
                      0.6 * math.sin(t), // y 轴中幅晃动
                    ),
                  ),
                  _buildDynamicBlob(
                    color: const Color(0xffFFB09C),
                    size: 600,
                    motion: (double t) => Offset(
                      0.9 * math.sin(2 * t), // x轴快速振荡
                      0.7 * math.sin(t + math.pi / 4), // y轴振荡
                    ),
                  ),
                  _buildDynamicBlob(
                    color: const Color(0xffE25287).withValues(alpha: 0.5),
                    size: 450,
                    // 运动公式：偏心圆
                    motion: (double t) => Offset(
                      0.4 + 0.5 * math.cos(t * 0.5), // x轴偏右旋转
                      -0.3 + 0.5 * math.sin(t * 0.5), // y轴偏上旋转
                    ),
                  ),
                ],
              );
            },
          ),

          // 2. 中层：强力模糊滤镜（水流感的灵魂）
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50), // 值越大，流动越像液体
              child: Container(color: Colors.transparent),
            ),
          ),

          // 3. 顶层：清晰的交互表单
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 25), child: _buildLoginForm(loginState)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建单个不规则运动的色块
  Widget _buildDynamicBlob({required Color color, required double size, required Offset Function(double t) motion}) {
    // 获取 0.0 到 2π 的弧度值
    final double t = _liquidController.value * 2 * math.pi;
    // 根据传入的公式计算 Alignment
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

  //登陆框
  Widget _buildLoginForm(AsyncValue<void> loginState) {
    return Container(
      padding: EdgeInsets.only(top: 20, bottom: 10),
      child: IntrinsicHeight(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 3),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/icon/Logo.jpg',
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    width: 110,
                    height: 110,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    child: const Icon(Icons.pets, size: 50, color: Color(0xFF1976D2)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
            _frosted(
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: '帐号', border: InputBorder.none),
              ),
            ),
            const SizedBox(height: 20),
            _frosted(
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: '密码', border: InputBorder.none),
              ),
            ),
            const SizedBox(height: 40),
            _buildActionButtons(loginState),
            const Spacer(),
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

  //校验
  Widget _buildActionButtons(AsyncValue<void> loginState) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xffFF5391),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        onPressed: loginState.isLoading ? null : () => _handLogin(),
        child: loginState.isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text(
                '登 录',
                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  //登陆设置
  Widget _buildBottomLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {
            context.pushNamed('NumberLogin');
          },
          child: const Text('手机号登陆', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}
