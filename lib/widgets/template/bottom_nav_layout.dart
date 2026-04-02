import 'package:flutter/material.dart';

import '../../routes/routes.dart';

enum AppNavItem { cash, home, mypage }

class AppBottomNavBar extends StatelessWidget {
  final AppNavItem currentItem;
  final Color backgroundColor;
  final EdgeInsetsGeometry margin;

  const AppBottomNavBar({
    super.key,
    required this.currentItem,
    this.backgroundColor = const Color(0xFFF7A5A5),
    this.margin = const EdgeInsets.fromLTRB(24, 0, 24, 16),
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        margin: margin,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              _BottomNavItem(
                label: 'CASH',
                isActive: currentItem == AppNavItem.cash,
                onTap: () => _navigate(context, Routes.cashDetail),
              ),
              _BottomNavItem(
                label: 'HOME',
                isActive: currentItem == AppNavItem.home,
                onTap: () => _navigate(context, Routes.main),
              ),
              _BottomNavItem(
                label: 'MYPAGE',
                isActive: currentItem == AppNavItem.mypage,
                onTap: () => _navigate(context, Routes.mypage),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }
}

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
            color: isActive ? const Color(0xFFF7A5A5) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
