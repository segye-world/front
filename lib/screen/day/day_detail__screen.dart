import 'package:flutter/material.dart';
import '../../widgets/template/base_scaffold.dart';

class DayDetailScreen extends StatelessWidget {
  const DayDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Day Detail',
      body: const Center(
        child: Text('일정 상세 페이지'),
      ),
    );
  }
}
