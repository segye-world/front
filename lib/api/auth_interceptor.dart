import 'package:dio/dio.dart';
import 'token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 로그인/회원가입 요청은 저장된 이전 토큰의 유효 여부와 관계없이
    // 처리되어야 합니다. 만료되었거나 다른 서버에서 발급된 토큰을 함께
    // 보내면 백엔드 인증 필터가 로그인 요청 자체를 거부할 수 있습니다.
    if (_isPublicAuthPath(options.path)) {
      handler.next(options);
      return;
    }

    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  bool _isPublicAuthPath(String path) {
    final requestPath = Uri.parse(path).path;
    return requestPath.endsWith('/auth/login') ||
        requestPath.endsWith('/auth/signup');
  }
}
