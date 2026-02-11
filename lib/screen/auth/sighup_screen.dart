import 'package:flutter/material.dart';
import '../../widgets/template/base_scaffold.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Signup',
      body: const Center(
        child: Text('회원가입 화면'),
      ),
    );
  }
}
