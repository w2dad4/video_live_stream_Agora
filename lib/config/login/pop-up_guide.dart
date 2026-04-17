import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:video_live_stream/config/toppop-up.dart';
import 'package:video_live_stream/features/auth/auth_provider.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_UI/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 资料完善状态
final profileCompletionProvider = StateNotifierProvider<ProfileCompletionNotifier, ProfileCompletionState>((ref) => ProfileCompletionNotifier(ref));

/// 资料完善状态类
class ProfileCompletionState {
  final String? avatarPath;
  final String avatarUrl;
  final String nickname;
  final String? gender;
  final bool isSubmitting;
  final String? error;

  ProfileCompletionState({this.avatarPath, this.avatarUrl = '', this.nickname = '', this.gender, this.isSubmitting = false, this.error});

  bool get canSubmit => avatarPath != null && nickname.isNotEmpty && gender != null && !isSubmitting;

  ProfileCompletionState copyWith({String? avatarPath, String? avatarUrl, String? nickname, String? gender, bool? isSubmitting, String? error}) {
    return ProfileCompletionState(avatarPath: avatarPath ?? this.avatarPath, avatarUrl: avatarUrl ?? this.avatarUrl, nickname: nickname ?? this.nickname, gender: gender ?? this.gender, isSubmitting: isSubmitting ?? this.isSubmitting, error: error);
  }
}

/// 资料完善管理器
class ProfileCompletionNotifier extends StateNotifier<ProfileCompletionState> {
  final Ref ref;
  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10)));

  ProfileCompletionNotifier(this.ref) : super(ProfileCompletionState());

  void setAvatar(String path) => state = state.copyWith(avatarPath: path);
  void setAvatarUrl(String url) => state = state.copyWith(avatarUrl: url);
  void setNickname(String value) => state = state.copyWith(nickname: value.trim());
  void setGender(String value) => state = state.copyWith(gender: value);
  void clearError() => state = state.copyWith(error: null);

  /// 提交资料完善 - 上传头像和资料
  Future<bool> submit(String userId, String token) async {
    if (!state.canSubmit) return false;

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      if (LiveConfig.bypassLoginApi) {
        // 开发模式：模拟上传成功
        await Future.delayed(const Duration(seconds: 1));

        // 更新本地用户数据
        _updateLocalUserData(userId, 'assets/image/002.png');

        state = state.copyWith(isSubmitting: false, avatarUrl: 'assets/image/002.png');
        return true;
      }

      // 1. 上传头像到后端
      final String uploadUrl = 'http://${LiveConfig.serverIP}:8000/api/v1/uploadAvatar';
      final avatarFile = File(state.avatarPath!);

      final formData = FormData.fromMap({'avatar': await MultipartFile.fromFile(avatarFile.path, filename: 'avatar_$userId.jpg')});

      final uploadResponse = await _dio.post(
        uploadUrl,
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      String? avatarUrl;
      if (uploadResponse.statusCode == 200 && uploadResponse.data['code'] == 0) {
        avatarUrl = uploadResponse.data['data']?['url'];
      }

      // 2. 提交完整资料
      final String completeUrl = 'http://${LiveConfig.serverIP}:8000/api/v1/completeProfile';
      final response = await _dio.post(
        completeUrl,
        data: {'nickname': state.nickname, 'gender': state.gender, 'avatarUrl': avatarUrl},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['code'] == 0) {
        // 更新本地用户数据
        final userData = response.data['data']?['user'];
        if (userData != null) {
          _updateLocalUserData(userId, avatarUrl ?? state.avatarPath!, name: state.nickname, gender: state.gender);
        }

        state = state.copyWith(isSubmitting: false, avatarUrl: avatarUrl ?? state.avatarPath!);
        return true;
      } else {
        throw response.data['message'] ?? '资料完善失败';
      }
    } catch (e) {
      String errorMsg = '上传失败，请重试';
      if (e is DioException) {
        errorMsg = e.response?.data['message'] ?? e.message ?? errorMsg;
      } else {
        errorMsg = e.toString();
      }
      state = state.copyWith(isSubmitting: false, error: errorMsg);
      return false;
    }
  }

  /// 更新本地用户数据
  void _updateLocalUserData(String userId, String avatar, {String? name, String? gender}) {
    // 更新 auth provider 中的用户数据
    final userNotifier = ref.read(userDataProvider(userId).notifier);
    final currentData = ref.read(userDataProvider(userId));

    if (currentData != null) {
      userNotifier.updateUserData(currentData.copyWith(name: name ?? currentData.name, avatar: avatar, gender: gender ?? currentData.gender));
    }
  }
}

/// 强制资料完善页 - 注册后必须完成
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final TextEditingController _nicknameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(() {
      ref.read(profileCompletionProvider.notifier).setNickname(_nicknameController.text);
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  /// 验证昵称
  String? _validateNickname(String value) {
    if (value.trim().isEmpty) return '昵称不能为空';
    if (value.trim().length < 2) return '昵称至少2个字符';
    if (value.trim().length > 12) return '昵称最多12个字符';
    final regex = RegExp(r'^[\u4e00-\u9fa5a-zA-Z0-9_]+$');
    if (!regex.hasMatch(value.trim())) return '昵称只能包含中文、英文、数字和下划线';
    return null;
  }

  /// 选择头像
  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);

    if (pickedFile != null) {
      ref.read(profileCompletionProvider.notifier).setAvatar(pickedFile.path);
      ToastUtil.showGreenSuccess(context, '头像已选择', '点击提交完成完善');
    }
  }

  /// 提交资料
  void _submit() async {
    final profileState = ref.read(profileCompletionProvider);

    // 验证头像
    if (profileState.avatarPath == null) {
      ToastUtil.showRedError(context, '请上传头像', '头像为必填项');
      return;
    }

    // 验证昵称
    final nicknameError = _validateNickname(profileState.nickname);
    if (nicknameError != null) {
      ToastUtil.showRedError(context, '昵称格式错误', nicknameError);
      return;
    }

    // 验证性别
    if (profileState.gender == null) {
      ToastUtil.showRedError(context, '请选择性别', '性别为必填项');
      return;
    }

    // 获取当前用户ID和token
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_account') ?? '';
    final token = prefs.getString('token') ?? '';

    if (userId.isEmpty) {
      ToastUtil.showRedError(context, '登录状态异常', '请重新登录');
      return;
    }

    // 提交
    final success = await ref.read(profileCompletionProvider.notifier).submit(userId, token);
    if (success && mounted) {
      ToastUtil.showGreenSuccess(context, '资料完善成功', '欢迎加入小猫啵啵');
      context.goNamed('Mylivestream');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileCompletionProvider);

    return PopScope(
      canPop: false, // 禁止返回，强制完成资料
      child: Scaffold(
        backgroundColor: const Color(0xff1A1A2E),
        body: Stack(
          children: [
            // 背景模糊效果
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.black.withValues(alpha: 0.3)),
              ),
            ),

            // 内容
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // 标题
                    const Text(
                      '完善个人资料',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text('完善资料后才能进入首页', style: TextStyle(fontSize: 14, color: Colors.white60)),
                    const SizedBox(height: 40),

                    // 头像选择
                    _buildAvatarSelector(profileState),
                    const SizedBox(height: 30),

                    // 昵称输入
                    _buildNicknameInput(profileState),
                    const SizedBox(height: 20),

                    // 性别选择
                    _buildGenderSelector(profileState),
                    const SizedBox(height: 50),

                    // 提交按钮
                    _buildSubmitButton(profileState),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 头像选择器
  Widget _buildAvatarSelector(ProfileCompletionState state) {
    return GestureDetector(
      onTap: _pickAvatar,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: state.avatarPath == null ? Colors.white30 : const Color(0xffFF5391), width: 2),
        ),
        child: state.avatarPath == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 40, color: Colors.white60),
                  SizedBox(height: 8),
                  Text('点击上传', style: TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              )
            : ClipOval(
                child: Image.file(
                  File(state.avatarPath!),
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(Icons.person, size: 60, color: Colors.white),
                ),
              ),
      ),
    );
  }

  /// 昵称输入框
  Widget _buildNicknameInput(ProfileCompletionState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: _nicknameController,
        maxLength: 12,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          labelText: '昵称',
          labelStyle: TextStyle(color: Colors.white60),
          border: InputBorder.none,
          counterText: '',
          prefixIcon: Icon(Icons.person_outline, color: Colors.white60),
          hintText: '2-12个字符，支持中英文数字',
          hintStyle: TextStyle(color: Colors.white30, fontSize: 12),
        ),
      ),
    );
  }

  /// 性别选择器
  Widget _buildGenderSelector(ProfileCompletionState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 12),
          child: Text('性别', style: TextStyle(color: Colors.white60, fontSize: 14)),
        ),
        Row(
          children: [
            Expanded(
              child: _genderOption('男', Icons.male, state.gender == 'male', () {
                ref.read(profileCompletionProvider.notifier).setGender('male');
              }),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _genderOption('女', Icons.female, state.gender == 'female', () {
                ref.read(profileCompletionProvider.notifier).setGender('female');
              }),
            ),
          ],
        ),
      ],
    );
  }

  /// 性别选项
  Widget _genderOption(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xffFF5391).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xffFF5391) : Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? const Color(0xffFF5391) : Colors.white60),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  /// 提交按钮
  Widget _buildSubmitButton(ProfileCompletionState state) {
    final bool isReady = state.avatarPath != null && state.nickname.isNotEmpty && state.gender != null;

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isReady ? const Color(0xffFF5391) : Colors.grey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        onPressed: state.isSubmitting ? null : _submit,
        child: state.isSubmitting
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text(
                '进入小猫啵啵',
                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
