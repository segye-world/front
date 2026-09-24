import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_icon_sizes.dart';
import '../../theme/app_text_styles.dart';

/// 앱 전체에서 공통으로 쓰는 상단바.
///
/// 배경은 흰색, 높이는 모든 페이지에서 [kToolbarHeight]로 동일합니다.
/// 하단에는 본문과 구분되도록 얇은 실선만 둡니다.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// 제목 글자색. 기존 화면들에서 쓰던 네이비 톤으로 통일합니다.
  static const Color _titleColor = AppColors.navyDark;

  /// 아이콘(뒤로가기 등) 색. 앱 포인트 컬러와 맞춥니다.
  static const Color _iconColor = AppColors.primaryPink;

  static const Color _dividerColor = AppColors.cardBorder;

  final String title;

  /// 좌측에 놓을 위젯. 지정하면 [showBack]은 무시됩니다.
  final Widget? leading;

  /// 우측 액션들.
  final List<Widget>? actions;

  /// 이전 화면이 있으면 뒤로가기 버튼을 자동으로 표시할지 여부.
  final bool showBack;

  const AppTopBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.showBack = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final resolvedLeading = leading ??
        (showBack && canPop
            ? IconButton(
                icon: const Icon(Icons.chevron_left, size: AppIconSize.action, color: _iconColor),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null);

    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      foregroundColor: _titleColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: resolvedLeading,
      title: Text(
        title,
        style: AppTextStyles.title.copyWith(color: _titleColor),
      ),
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: _dividerColor),
      ),
    );
  }
}
