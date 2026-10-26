class KakaoConfig {
  /// Kakao Developers > [앱] > [플랫폼 키] > [네이티브 앱 키].
  ///
  /// `flutter run --dart-define-from-file=dart_defines.json` 으로 주입한다.
  /// android/app/build.gradle.kts 도 같은 값을 읽어 로그인 리다이렉트 스킴을 만든다.
  static const nativeAppKey = String.fromEnvironment('KAKAO_NATIVE_APP_KEY');

  static bool get isConfigured => nativeAppKey.isNotEmpty;
}
