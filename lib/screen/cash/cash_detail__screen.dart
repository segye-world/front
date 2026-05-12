import 'package:flutter/material.dart';

import '../../widgets/template/base_scaffold.dart';
import '../../widgets/template/bottom_nav_layout.dart';

class CashDetailScreen extends StatelessWidget {
  final String loginEmail;

  const CashDetailScreen({super.key, this.loginEmail = ''});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Cash Detail',
      body: Column(
        children: [
          const Expanded(
            child: Center(
              child: Text('가계부 페이지'),
            ),
          ),
          // ✅ 모든 화면에서 하단 탭을 공통으로 유지
          BottomNavLayout(loginEmail: loginEmail, currentTab: BottomNavType.cash),
        ],
      ),
    );
  }
}
