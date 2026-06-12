import 'package:flutter/material.dart';

import '../../routes/routes.dart';
import '../../api/auth_api.dart';
import '../../api/api_error.dart';
import '../../widgets/template/auth_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthApi _authApi = AuthApi();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = '이메일과 비밀번호를 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authApi.login(email: email, password: password);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        Routes.main,
        arguments: {'loginEmail': email},
      );
    } catch (e) {
      setState(() => _errorMessage =
          apiErrorMessage(e, fallback: '로그인에 실패했습니다.'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          const Spacer(flex: 2),
          const Center(child: AuthSymbol()),
          const Spacer(flex: 2),
          const AuthFieldLabel('Email'),
          const SizedBox(height: 8),
          AuthInput(
            controller: _emailController,
            hintText: 'Enter your email',
          ),
          const SizedBox(height: 18),
          const AuthFieldLabel('Password'),
          const SizedBox(height: 8),
          AuthInput(
            controller: _passwordController,
            hintText: 'Enter your password',
            obscureText: true,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
          const SizedBox(height: 36),
          AuthPrimaryButton(
            onPressed: _isLoading ? null : _submitLogin,
            label: _isLoading ? 'Loading...' : 'Login',
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Find password',
                  style: TextStyle(color: Color(0xFFB4BAC8)),
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(Routes.signup);
                },
                child: const Text(
                  'Sign up',
                  style: TextStyle(color: Color(0xFFB4BAC8)),
                ),
              ),
            ],
          ),
          const Spacer(flex: 4),
        ],
      ),
    );
  }
}
