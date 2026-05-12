import 'package:flutter/material.dart';

import '../../routes/routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ERD의 Member(email, password) 구조를 반영한 입력 컨트롤러입니다.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        // ✅ 요구사항 반영: 카드 박스가 아닌 "화면 전체"를 쓰는 로그인 레이아웃
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ 요구사항 반영: 로그인 페이지 상단 뒤로가기 버튼 제거
              const SizedBox(height: 56),
              const Center(child: _AuthSymbol()),
              const SizedBox(height: 42),
              const Text(
                '아이디',
                style: TextStyle(
                  color: Color(0xFF7886A8),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _AuthInput(
                controller: _emailController,
                hintText: '이메일을 입력해 주세요.',
              ),
              const SizedBox(height: 18),
              const Text(
                '비밀번호',
                style: TextStyle(
                  color: Color(0xFF7886A8),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _AuthInput(
                controller: _passwordController,
                hintText: '비밀번호를 입력해 주세요.',
                obscureText: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3A3A4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // ✅ 로그인 시 입력한 email을 Main/MyPage로 전달합니다.
                    Navigator.of(context).pushReplacementNamed(
                      Routes.main,
                      arguments: {'loginEmail': _emailController.text.trim()},
                    );
                  },
                  child: const Text(
                    '로그인',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      '비밀번호 찾기',
                      style: TextStyle(color: Color(0xFFB4BAC8)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(Routes.signup);
                    },
                    child: const Text(
                      '회원가입',
                      style: TextStyle(color: Color(0xFFB4BAC8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;

  const _AuthInput({
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
        hintStyle: const TextStyle(color: Color(0xFFB4BAC8)),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD2D7E2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD2D7E2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFF3A3A4), width: 1.2),
        ),
      ),
    );
  }
}

class _AuthSymbol extends StatelessWidget {
  const _AuthSymbol();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFE0A7FF), Color(0xFFF9E89A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Icon(
        Icons.calendar_month_outlined,
        size: 50,
        color: Color(0xFF2F4B7C),
      ),
    );
  }
}
