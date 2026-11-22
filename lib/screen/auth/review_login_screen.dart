import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../api/api_error.dart';
import '../../api/auth_api.dart';
import '../../routes/routes.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_primary_button.dart';
import '../../widgets/template/auth_layout.dart';

/// 스토어 심사용 로그인. 심사자는 카카오 계정 없이 Play Console "앱 액세스 권한"에 적어 둔
/// 아이디·비밀번호로 로그인한다. 로그인 화면 하단의 "다른 방법으로 로그인"으로 들어온다.
class ReviewLoginScreen extends StatefulWidget {
  const ReviewLoginScreen({super.key, this.authApi});

  /// 테스트에서 바꿔 끼우기 위한 값. 없으면 기본 [AuthApi] 를 쓴다.
  final AuthApi? authApi;

  @override
  State<ReviewLoginScreen> createState() => _ReviewLoginScreenState();
}

class _ReviewLoginScreenState extends State<ReviewLoginScreen> {
  late final AuthApi _authApi = widget.authApi ?? AuthApi();
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_isLoading &&
      _loginIdController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  Future<void> _login() async {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authApi.loginForReview(
        loginId: _loginIdController.text.trim(),
        password: _passwordController.text,
      );
      unawaited(NotificationService.instance.onLogin());
      if (!mounted) return;
      // 로그인 화면 위에 쌓인 화면이므로 둘 다 걷어내고 홈으로 간다.
      Navigator.of(context).pushNamedAndRemoveUntil(
        Routes.dayDetail,
        (_) => false,
        arguments: NotificationService.instance.takePendingDate() ?? DateTime.now(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _messageFor(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _messageFor(Object e) {
    // 서버에서 심사용 로그인이 꺼져 있으면 경로 자체가 없다.
    if (e is DioException && e.response?.statusCode == 404) {
      return '지금은 이 방법으로 로그인할 수 없습니다.';
    }
    return apiErrorMessage(e, fallback: '로그인에 실패했습니다.');
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      leading: IconButton(
        tooltip: '뒤로',
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
        icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Text(
              '아이디로 로그인',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '안내받은 아이디와 비밀번호로 로그인합니다.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            TextField(
              key: const Key('reviewLoginId'),
              controller: _loginIdController,
              enabled: !_isLoading,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              decoration: _inputDecoration('아이디'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('reviewPassword'),
              controller: _passwordController,
              enabled: !_isLoading,
              obscureText: _obscurePassword,
              autocorrect: false,
              enableSuggestions: false,
              maxLength: 64,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              decoration: _inputDecoration('비밀번호').copyWith(
                counterText: '',
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? '비밀번호 보기' : '비밀번호 숨기기',
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textTertiary,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _login(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
            const SizedBox(height: 24),
            AppPrimaryButton(
              onPressed: _canSubmit ? _login : null,
              label: _isLoading ? '로그인 중...' : '로그인',
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
      );
}
