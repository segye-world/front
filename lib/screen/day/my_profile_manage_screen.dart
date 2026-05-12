import 'package:flutter/material.dart';

import '../../widgets/template/base_scaffold.dart';
import '../../widgets/template/bottom_nav_layout.dart';

class MyProfileManageScreen extends StatelessWidget {
  final String loginEmail;

  const MyProfileManageScreen({super.key, this.loginEmail = ''});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: '내 정보 관리',
      body: Column(
        children: [
          const Expanded(
            child: Center(
              child: Text('내 정보 관리 페이지'),
            ),
          ),
          // ✅ 모든 페이지 공통 하단 탭 바 유지
          BottomNavLayout(loginEmail: loginEmail, currentTab: BottomNavType.myPage),
        ],
      ),
    );
  }
}
