import 'package:dio/dio.dart';

import 'api_config.dart';
import 'auth_interceptor.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient._({required TokenStorage tokenStorage})
      : tokenStorage = tokenStorage,
        dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            contentType: Headers.jsonContentType,
            responseType: ResponseType.json,
          ),
        ) {
    dio.interceptors.add(AuthInterceptor(tokenStorage));
  }

  final Dio dio;
  final TokenStorage tokenStorage;

  static final ApiClient instance = ApiClient._(tokenStorage: TokenStorage());
}
