import 'package:flutter/material.dart';
import '../../widgets/template/base_scaffold.dart';

class CashDetailScreen extends StatelessWidget {
  const CashDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Cash Detail',
      body: const Center(
        child: Text('가계부 페이지'),
      ),
    );
  }
}
