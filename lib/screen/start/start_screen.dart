import 'package:flutter/material.dart';
import '../../widgets/template/base_scaffold.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Start',
      body: const Center(
        child: Text('시작 화면'),
      ),
    );
  }
}
