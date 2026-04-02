import 'package:flutter/material.dart';

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

    if (password != passwordConfirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signup completed. Please log in.')),
    );

    Navigator.of(context).pushReplacementNamed(Routes.login);
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
            onPressed: _submitSignup,
            label: 'Create account',
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
