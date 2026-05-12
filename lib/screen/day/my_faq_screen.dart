import 'package:flutter/material.dart';

import '../../widgets/template/base_scaffold.dart';
import '../../widgets/template/bottom_nav_layout.dart';

class MyFaqScreen extends StatelessWidget {
  final String loginEmail;

  const MyFaqScreen({super.key, this.loginEmail = ''});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'FAQ',
      body: Column(
        children: [
          const Expanded(
            child: Center(
              child: Text('FAQ 페이지'),
            ),
          ),
          // ✅ 모든 페이지 공통 하단 탭 바 유지
          BottomNavLayout(loginEmail: loginEmail, currentTab: BottomNavType.myPage),
        ],
      ),
    );
  }
}
