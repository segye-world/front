import 'package:flutter/material.dart';

import '../../routes/routes.dart';

/// 앱 전역에서 재사용하는 하단 탭 바입니다.
class BottomNavLayout extends StatelessWidget {
  final String loginEmail;
  final BottomNavType currentTab;

  const BottomNavLayout({
    super.key,
    required this.loginEmail,
    required this.currentTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7A5A5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _BottomNavItem(
            label: 'CASH',
            isActive: currentTab == BottomNavType.cash,
            onTap: () => Navigator.of(context).pushNamed(
              Routes.cashDetail,
              arguments: {'loginEmail': loginEmail},
            ),
          ),
          _BottomNavItem(
            label: 'HOME',
            isActive: currentTab == BottomNavType.home,
            onTap: () => Navigator.of(context).pushNamed(
              Routes.main,
              arguments: {'loginEmail': loginEmail},
            ),
          ),
          _BottomNavItem(
            label: 'MYPAGE',
            isActive: currentTab == BottomNavType.myPage,
            onTap: () => Navigator.of(context).pushNamed(
              Routes.mypage,
              arguments: {'loginEmail': loginEmail},
            ),
          ),
        ],
      ),
    );
  }
}

/// 현재 페이지가 어떤 탭에 속하는지 표시하기 위한 타입입니다.
enum BottomNavType { cash, home, myPage }

class _BottomNavItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFF19999) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
