import 'package:flutter/material.dart';

import '../../api/auth_api.dart';
import '../../api/api_error.dart';
import '../../routes/routes.dart';
import '../../widgets/template/auth_layout.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();
  final AuthApi _authApi = AuthApi();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submitSignup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final passwordConfirm = _passwordConfirmController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('이메일과 비밀번호를 입력해주세요.');
      return;
    }
    // 백엔드 검증(@Size(min = 8))과 동일한 규칙을 미리 확인합니다.
    if (password.length < 8) {
      _showMessage('비밀번호는 8자 이상이어야 합니다.');
      return;
    }
    if (password != passwordConfirm) {
      _showMessage('비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authApi.signUp(email: email, password: password);
      if (!mounted) return;
      _showMessage('회원가입이 완료되었습니다. 로그인해주세요.');
      Navigator.of(context).pushReplacementNamed(Routes.login);
    } catch (e) {
      if (!mounted) return;
      _showMessage(apiErrorMessage(e, fallback: '회원가입에 실패했습니다.'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.chevron_left, size: 28),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          const Center(child: AuthSymbol(icon: Icons.person_add_alt_1_rounded)),
          const SizedBox(height: 28),
          const AuthFieldLabel('Email'),
          const SizedBox(height: 8),
          AuthInput(
            controller: _emailController,
            hintText: 'example@cashdiary.com',
          ),
          const SizedBox(height: 16),
          const AuthFieldLabel('Password'),
          const SizedBox(height: 8),
          AuthInput(
            controller: _passwordController,
            hintText: 'Enter your password',
            obscureText: true,
          ),
          const SizedBox(height: 16),
          const AuthFieldLabel('Confirm password'),
          const SizedBox(height: 8),
          AuthInput(
            controller: _passwordConfirmController,
            hintText: 'Re-enter your password',
            obscureText: true,
          ),
          const SizedBox(height: 28),
          AuthPrimaryButton(
            onPressed: _isLoading ? null : _submitSignup,
            label: _isLoading ? 'Loading...' : 'Create account',
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
