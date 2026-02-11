import 'package:flutter/material.dart';
import '../../widgets/template/base_scaffold.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Login',
      body: const Center(
        child: Text('로그인 화면'),
      ),
    );
  }
}
