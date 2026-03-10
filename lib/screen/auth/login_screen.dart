import 'package:flutter/material.dart';

import '../../routes/routes.dart';
import '../../widgets/template/auth_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, size: 28),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              const SizedBox(height: 56),
              const _AuthSymbol(),
              const SizedBox(height: 54),
              const _FieldLabel('아이디'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('이메일을 입력해 주세요.'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '이메일을 입력해 주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              const _FieldLabel('비밀번호'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: _inputDecoration('비밀번호를 입력해 주세요.'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '비밀번호를 입력해 주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 34),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEFA1A1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.of(context).pushReplacementNamed(Routes.main);
                    }
                  },
                  child: const Text('로그인'),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text('비밀번호 찾기'),
                  ),
                  const SizedBox(width: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(Routes.signup);
                    },
                    child: const Text('회원가입'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB1B8C7), fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD2D8E2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFA8B1C0), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF6A7392),
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
    );
  }
}

class _AuthSymbol extends StatelessWidget {
  const _AuthSymbol();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 110,
        height: 110,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFF9BDD4), Color(0xFFF5EFB2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Icon(Icons.calendar_month_rounded,
            size: 56, color: Color(0xFF2A4769)),
      ),
    );
  }
}
