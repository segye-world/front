import 'package:flutter/material.dart';

/// 앱 전체에서 쓰는 주요 액션 버튼(로그인/저장/추가 등).
///
/// 기존에는 화면마다 FilledButton/ElevatedButton을 각자 인라인으로 구현해
/// 배경색·높이·모서리가 제각각이었습니다. 이 위젯 하나로 통일합니다.
/// 모서리는 [ThemeData.filledButtonTheme]을 따르고, 배경색도 기본적으로는
/// 테마를 따르되 수입/지출처럼 화면 상태에 따라 달라져야 할 때만
/// [backgroundColor]로 덮어씁니다.
class AppPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final Color? backgroundColor;

  const AppPrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        style: backgroundColor == null
            ? null
            : FilledButton.styleFrom(backgroundColor: backgroundColor),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
