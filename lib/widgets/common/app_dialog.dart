import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';

/// 앱 전체에서 쓰는 확인/취소형 다이얼로그.
///
/// 기존에는 AlertDialog.actions(자연 크기, 우측 정렬)와 커스텀 50:50 Row가
/// 섞여 있어 화면마다 버튼 배치가 달랐습니다. 이 위젯 하나로 통일해
/// 취소·확인 버튼을 항상 50:50 너비, 높이 48로 나란히 놓습니다.
/// 다이얼로그의 배경색/모서리는 [ThemeData.dialogTheme]을 따릅니다.
class AppDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback? onConfirm;

  /// 확인 버튼 배경색. 지정하지 않으면 테마 기본(핑크)을 따르고,
  /// 삭제/탈퇴처럼 위험한 동작일 때만 강조색으로 덮어씁니다.
  final Color? confirmColor;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.cancelLabel = '취소',
    required this.confirmLabel,
    required this.onConfirm,
    this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.title),
            const SizedBox(height: 16),
            content,
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(cancelLabel),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      style: confirmColor == null
                          ? null
                          : FilledButton.styleFrom(backgroundColor: confirmColor),
                      onPressed: onConfirm,
                      child: Text(confirmLabel),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
