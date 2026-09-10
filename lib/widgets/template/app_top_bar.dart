import 'package:flutter/material.dart';

/// 앱 전체에서 공통으로 쓰는 상단바.
///
/// 배경은 흰색, 높이는 모든 페이지에서 [kToolbarHeight]로 동일합니다.
/// 하단에는 본문과 구분되도록 얇은 실선만 둡니다.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// 제목 글자색. 기존 화면들에서 쓰던 네이비 톤으로 통일합니다.
  static const Color _titleColor = Color(0xFF4F5E82);

  /// 아이콘(뒤로가기 등) 색. 앱 포인트 컬러와 맞춥니다.
  static const Color _iconColor = Color(0xFFF7A5A5);

  static const Color _dividerColor = Color(0xFFEEEEEE);

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
                icon: const Icon(Icons.chevron_left, color: _iconColor),
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
        style: const TextStyle(
          color: _titleColor,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: _dividerColor),
      ),
    );
  }
}
