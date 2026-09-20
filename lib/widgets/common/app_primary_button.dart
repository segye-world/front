import 'package:flutter/material.dart';

/// 앱 전체에서 쓰는 주요 액션 버튼(로그인/저장/추가 등).
///
/// 기존에는 화면마다 FilledButton/ElevatedButton을 각자 인라인으로 구현해
/// 배경색·높이·모서리가 제각각이었습니다. 이 위젯 하나로 통일합니다.
/// 배경색과 모서리는 [ThemeData.filledButtonTheme]을 따릅니다.
class AppPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;

  const AppPrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
