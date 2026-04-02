import 'package:flutter/material.dart';

import '../../routes/routes.dart';
import '../../widgets/template/auth_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
          const SizedBox(height: 36),
          AuthPrimaryButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed(Routes.main);
            },
            label: 'Login',
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
