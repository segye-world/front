import 'package:flutter/material.dart';
import '../../widgets/template/base_scaffold.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'My Page',
      body: const Center(
        child: Text('마이페이지'),
      ),
    );
  }
}
