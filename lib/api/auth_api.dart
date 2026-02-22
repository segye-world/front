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
    final response = await _client.dio.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final token = _extractToken(response.data);
    await _client.tokenStorage.saveAccessToken(token);
    return token;
  }

  Future<void> logout() {
    return _client.tokenStorage.clearAccessToken();
  }

  String _extractToken(Map<String, dynamic>? payload) {
    if (payload == null) {
      throw DioException.badResponse(
        statusCode: 500,
        requestOptions: RequestOptions(path: '${ApiConfig.apiPrefix}/auth/login'),
        response: null,
      );
    }

    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      final token = data['token'];
      if (token is String && token.isNotEmpty) {
        return token;
      }
    }

    throw DioException.badResponse(
      statusCode: 500,
      requestOptions: RequestOptions(path: '${ApiConfig.apiPrefix}/auth/login'),
      response: Response(
        requestOptions: RequestOptions(path: '${ApiConfig.apiPrefix}/auth/login'),
        statusCode: 500,
        data: payload,
      ),
    );
  }
}
