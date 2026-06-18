import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_storage.dart';

class ApiClient {
  // 실기기(USB): PC에서 `adb reverse tcp:8080 tcp:8080` 실행 후 127.0.0.1 사용
  // 에뮬레이터: adb reverse 없이 쓰려면 10.0.2.2 로 변경
  static const _baseUrl = 'http://127.0.0.1:8080';

  static Future<http.Response> get(String path) async {
    return http.get(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(),
    );
  }

  static Future<http.Response> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    return http.post(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    return http.put(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> delete(String path) async {
    return http.delete(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(),
    );
  }

  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.load();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
