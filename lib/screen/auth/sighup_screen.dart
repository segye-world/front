import 'package:flutter/material.dart';

import '../../data/mock_erd_repository.dart';
import '../../routes/routes.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // ERD의 Member 테이블 스키마(email, password)에 맞춰 가입 폼을 구성합니다.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  void _submitSignup() {
    final password = _passwordController.text;
    final passwordConfirm = _passwordConfirmController.text;

    // 비밀번호 확인이 일치하지 않으면 가입 요청 대신 안내 메시지를 보여줍니다.
    if (password != passwordConfirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    // ✅ 가입한 회원도 즉시 고유 id를 발급해 이후 항목이 회원별로 분리되도록 합니다.
    MockErdRepository.instance.registerMember(_emailController.text.trim(), password);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('회원가입이 완료되었습니다. 로그인해 주세요.')),
    );

    Navigator.of(context).pushReplacementNamed(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        title: const Text('회원가입'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('이메일'),
            const SizedBox(height: 8),
            _SignupInput(controller: _emailController, hintText: 'example@cashdiary.com'),
            const SizedBox(height: 16),
            const Text('비밀번호'),
            const SizedBox(height: 8),
            _SignupInput(
              controller: _passwordController,
              hintText: '비밀번호를 입력해 주세요.',
              obscureText: true,
            ),
            const SizedBox(height: 16),
            const Text('비밀번호 확인'),
            const SizedBox(height: 8),
            _SignupInput(
              controller: _passwordConfirmController,
              hintText: '비밀번호를 다시 입력해 주세요.',
              obscureText: true,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitSignup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF3A3A4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text('회원가입 완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignupInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;

  const _SignupInput({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
