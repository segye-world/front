import 'package:flutter/material.dart';

import '../../routes/routes.dart';

/// 하단 탭. 선언 순서가 곧 탭 인덱스입니다.
enum AppNavItem { cash, home, mypage }

/// 앱 전체에서 쓰는 하단 내비게이션 바.
/// 일정 상세 화면의 바를 기준으로 통일했습니다.
class AppBottomNavBar extends StatelessWidget {
  static const Color barColor = Color(0xFFF7A5A5);

  final AppNavItem currentItem;

  /// 이미 선택된 탭을 다시 눌렀을 때의 동작.
  /// 지정하지 않으면 해당 탭으로 다시 이동합니다.
  final VoidCallback? onReselected;

  const AppBottomNavBar({
    super.key,
    required this.currentItem,
    this.onReselected,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentItem.index,
      onTap: (index) => _handleTap(context, AppNavItem.values[index]),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white,
      backgroundColor: barColor,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'CASH'),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'MYPAGE'),
      ],
    );
  }

  void _handleTap(BuildContext context, AppNavItem target) {
    if (target == currentItem && onReselected != null) {
      onReselected!();
      return;
    }

    switch (target) {
      case AppNavItem.cash:
        _navigate(context, Routes.cashDetail);
      case AppNavItem.home:
        // 홈은 오늘 날짜의 일정 상세 화면입니다.
        _navigate(context, Routes.dayDetail, arguments: DateTime.now());
      case AppNavItem.mypage:
        _navigate(context, Routes.mypage);
    }
  }

  void _navigate(BuildContext context, String routeName, {Object? arguments}) {
    // 탭 전환 시 스택을 비우고 이동해 화면이 쌓이는 것을 방지합니다.
    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }
}
