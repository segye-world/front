import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../routes/routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_icon_sizes.dart';
import '../../theme/app_text_styles.dart';

/// 하단 탭. 선언 순서가 곧 탭 인덱스입니다.
enum AppNavItem { cash, home, mypage }

/// 앱 전체에서 쓰는 하단 내비게이션 바.
///
/// 화면 아래에 떠 있는 반투명 유리(Liquid Glass) 형태입니다. 유리 강도(블러·불투명도)는
/// [AppGlass] 토큰을 따르고, 선택된 탭은 [AppColors.primaryTint] 배경 위에
/// [AppColors.primary] 글자로 표시합니다.
///
/// 바가 떠 있도록 이 바를 쓰는 Scaffold 는 `extendBody: true` 로 두고, 본문은
/// SafeArea 로 감싸 바 높이만큼 자동으로 비켜 가게 합니다.
///
/// 탭을 누를 때마다 화면을 새로 띄우므로(바도 함께 다시 만들어짐) 캡슐이 옆 탭으로
/// 미끄러지는 이동 애니메이션은 넣지 않고, 선택 상태 표시만 바꿉니다.
class AppBottomNavBar extends StatelessWidget {
  /// 바 바깥 여백. 좌우·아래로 띄워 화면 위에 떠 있는 것처럼 보이게 합니다.
  static const EdgeInsets _outerMargin = EdgeInsets.fromLTRB(16, 0, 16, 10);
  static const double _barRadius = 24;
  static const double _tabRadius = 18;
  static const Duration _transition = Duration(milliseconds: 180);

  static const Color _selectedColor = AppColors.primary;
  static const Color _selectedBackground = AppColors.primaryTint;

  /// 선택되지 않은 탭의 아이콘·글자색. 흰 유리 위에서 대비 4.5:1 이상을 지킵니다.
  static const Color _unselectedColor = AppColors.textSecondary;

  static const _items = [
    (item: AppNavItem.cash, icon: Icons.wallet, label: 'CASH'),
    (item: AppNavItem.home, icon: Icons.home, label: 'HOME'),
    (item: AppNavItem.mypage, icon: Icons.person, label: 'MYPAGE'),
  ];

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
    // 키보드가 올라와 있으면 입력 영역을 가리지 않도록 바를 숨깁니다.
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final transition = reduceMotion ? Duration.zero : _transition;

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: AppGlass.opacity),
        borderRadius: BorderRadius.circular(_barRadius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            for (final entry in _items)
              Expanded(
                child: _NavTab(
                  icon: entry.icon,
                  label: entry.label,
                  selected: entry.item == currentItem,
                  transition: transition,
                  onTap: () => _handleTap(context, entry.item),
                ),
              ),
          ],
        ),
      ),
    );

    if (AppGlass.useBlur) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppGlass.blurSigma, sigmaY: AppGlass.blurSigma),
        child: surface,
      );
    }

    // 제스처·3버튼 내비게이션 어느 쪽이든 시스템 영역과 겹치지 않도록 SafeArea 안에 둡니다.
    return SafeArea(
      top: false,
      child: Padding(
        padding: _outerMargin,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_barRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_barRadius),
            child: surface,
          ),
        ),
      ),
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

/// 하단 바의 탭 하나.
///
/// 탭 너비는 바를 3등분한 고정 폭이고, 선택될 때 글자가 굵어져도 위치가 흔들리지
/// 않도록 굵은 글자 기준으로 자리를 먼저 잡아 둡니다.
class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Duration transition;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.transition,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppBottomNavBar._selectedColor : AppBottomNavBar._unselectedColor;
    final baseStyle = AppTextStyles.small.copyWith(letterSpacing: 0.2);
    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.w700);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppBottomNavBar._tabRadius),
          child: AnimatedContainer(
            duration: transition,
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? AppBottomNavBar._selectedBackground : Colors.transparent,
              borderRadius: BorderRadius.circular(AppBottomNavBar._tabRadius),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: AppIconSize.action, color: color),
                const SizedBox(height: 2),
                // 글자 크기를 키워도(130%·200%) 탭 이름이 한 줄을 유지하도록,
                // 폭이 모자라면 줄바꿈 대신 살짝 줄여서 맞춥니다.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 굵은 글자 폭으로 자리를 잡아 두는 보이지 않는 텍스트.
                      Opacity(
                        opacity: 0,
                        child: Text(label, maxLines: 1, style: boldStyle),
                      ),
                      AnimatedDefaultTextStyle(
                        duration: transition,
                        style: (selected ? boldStyle : baseStyle).copyWith(color: color),
                        child: Text(label, maxLines: 1, softWrap: false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
