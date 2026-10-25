import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../api/api_error.dart';

/// 화면 전체에서 반복되던 `ScaffoldMessenger.of(context).showSnackBar(...)` 호출을
/// 한곳으로 모은 공용 헬퍼. 평범한 안내 메시지는 [showAppSnackBar]를,
/// API 호출 실패처럼 에러 객체가 있는 경우는 [showErrorSnackBar]를 사용합니다.
void showAppSnackBar(BuildContext context, String message, {SnackBarAction? action}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), action: action),
  );
}

/// API 에러를 사용자에게 스낵바로 보여주고, 디버그 모드에서는 콘솔에도 남깁니다.
/// catch (_) {} 로 조용히 삼키던 에러를 대체하기 위한 헬퍼입니다.
void showErrorSnackBar(
  BuildContext context,
  Object error, {
  String fallback = '요청을 처리하지 못했습니다.',
  StackTrace? stackTrace,
}) {
  if (kDebugMode) {
    debugPrint('[API Error] $error');
    if (stackTrace != null) debugPrint('$stackTrace');
  }
  showAppSnackBar(context, apiErrorMessage(error, fallback: fallback));
}
