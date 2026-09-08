import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_config.dart';

class AuthApi {
  AuthApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<void> signUp({required String email, required String password}) async {
    await _client.dio.post(
      '${ApiConfig.apiPrefix}/auth/signup',
      data: {
        'email': email,
        'password': password,
      },
    );
  }

  Future<String> login({required String email, required String password}) async {
    // 새 로그인에는 기존 세션이 필요하지 않습니다. 오래되었거나 유효하지
    // 않은 토큰이 인터셉터를 통해 로그인 요청에 실리는 것을 방지합니다.
    await _client.tokenStorage.clearAll();

    final response = await _client.dio.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final token = _extractToken(response.data);
    await _client.tokenStorage.saveAccessToken(token);
    await _client.tokenStorage.saveEmail(email);
    return token;
  }

  Future<void> logout() {
    return _client.tokenStorage.clearAll();
  }

  Future<void> deleteAccount() async {
    await _client.dio.delete('${ApiConfig.apiPrefix}/members/me');
    await _client.tokenStorage.clearAll();
  }

  String _extractToken(Map<String, dynamic>? payload) {
    final requestOptions = RequestOptions(path: '${ApiConfig.apiPrefix}/auth/login');

    if (payload == null) {
      throw DioException.badResponse(
        statusCode: 500,
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 500,
          data: const {'message': 'Empty login response payload'},
        ),
      );
    }

    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      final token = data['accessToken'];
      if (token is String && token.isNotEmpty) {
        return token;
      }
    }

    throw DioException.badResponse(
      statusCode: 500,
      requestOptions: requestOptions,
      response: Response(
        requestOptions: requestOptions,
        statusCode: 500,
        data: payload,
      ),
    );
  }
}
