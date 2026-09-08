import 'package:flutter/foundation.dart';

class ApiConfig {
  static const _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// 개발 기본값. 다른 호스트를 쓸 때는
  /// `flutter run --dart-define=API_BASE_URL=http://<host>:8080` 으로 덮어쓴다.
  ///
  /// - 에뮬레이터: 10.0.2.2 가 호스트 PC를 가리킨다(에뮬레이터 안에서 127.0.0.1은 자기 자신).
  /// - 실기기(USB): PC에서 `adb reverse tcp:8080 tcp:8080` 을 실행하면 127.0.0.1 로 붙으므로
  ///   `--dart-define=API_BASE_URL=http://127.0.0.1:8080` 을 넘긴다.
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://127.0.0.1:8080';
  }

  // Dio 기반 API 클라이언트에서 공통으로 사용하는 백엔드 API 경로입니다.
  static const apiPrefix = '/api/v1';
}
