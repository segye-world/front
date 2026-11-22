import 'dart:async';

import 'package:dio/dio.dart';

import 'api_config.dart';
import 'auth_interceptor.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient({required TokenStorage tokenStorage})
    : tokenStorage = tokenStorage,
      dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      ) {
    _authInterceptor = AuthInterceptor(
      dio,
      tokenStorage,
      () => _sessionExpired.add(null),
    );
    dio.interceptors.add(_authInterceptor);
  }

  final Dio dio;
  final TokenStorage tokenStorage;
  late final AuthInterceptor _authInterceptor;
  final _sessionExpired = StreamController<void>.broadcast();

  Stream<void> get sessionExpired => _sessionExpired.stream;

  Future<bool> restoreSession() async {
    final tokens = await tokenStorage.read();
    if (tokens == null) return false;
    return tokens.isAccessTokenValid ||
        await _authInterceptor.refresh(tokens, notify: false) != null;
  }

  static final ApiClient instance = ApiClient(tokenStorage: TokenStorage());
}
