class ApiConfig {
  const ApiConfig._();

  /// `--dart-define=API_BASE_URL=http://10.0.2.2:8080` 형태로 덮어쓸 수 있습니다.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const String apiPrefix = '/api/v1/auth/login';
}
