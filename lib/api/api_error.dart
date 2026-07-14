import 'package:dio/dio.dart';

/// 백엔드 공통 응답 {success, data, error:{code, message}} 에서
/// 사용자에게 보여줄 에러 메시지를 추출한다.
String apiErrorMessage(
  Object error, {
  String fallback = '요청을 처리하지 못했습니다.',
}) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final err = data['error'];
      if (err is Map && err['message'] is String && (err['message'] as String).isNotEmpty) {
        return err['message'] as String;
      }
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return '서버에 연결할 수 없습니다. 네트워크 상태를 확인해주세요.';
      default:
        break;
    }
  }
  return fallback;
}
