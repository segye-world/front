import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

import '../api/api_client.dart' as authenticated;

class ApiClient {
  static Future<http.Response> get(String path) => _request('GET', path);

  static Future<http.Response> post(String path, Map<String, dynamic> body) =>
      _request('POST', path, body);

  static Future<http.Response> put(String path, Map<String, dynamic> body) =>
      _request('PUT', path, body);

  static Future<http.Response> delete(String path) => _request('DELETE', path);

  static Future<http.Response> _request(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final dio = authenticated.ApiClient.instance.dio;
    Response<dynamic> response;
    try {
      response = await dio.request<List<int>>(
        path,
        data: body,
        options: Options(method: method, responseType: ResponseType.bytes),
      );
    } on DioException catch (error) {
      // 기존 서비스 호출부에는 원래 요청의 HTTP 응답 형식을 유지한다.
      final failed = error.response;
      if (failed == null || failed.data is! List<int>) rethrow;
      response = failed;
    }
    return http.Response.bytes(
      response.data as List<int>? ?? const [],
      response.statusCode!,
      headers: response.headers.map.map(
        (name, values) => MapEntry(name, values.join(',')),
      ),
    );
  }
}
