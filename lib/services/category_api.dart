import 'dart:convert';
import 'api_client.dart';
import '../models/account_record_model.dart';

class CategoryApi {
  static Future<List<CategoryModel>> fetchAll() async {
    final response = await ApiClient.get('/api/v1/categories');
    if (response.statusCode != 200) throw Exception('카테고리 조회 실패');
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final List<dynamic> data = body['data'] as List<dynamic>;
    return data
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<CategoryModel> create({
    required String name,
    required String type,
  }) async {
    final response = await ApiClient.post('/api/v1/categories', {
      'name': name,
      'type': type,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('카테고리 추가 실패');
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return CategoryModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  static Future<CategoryModel> update({
    required int id,
    required String name,
    required String type,
  }) async {
    final response = await ApiClient.put('/api/v1/categories/$id', {
      'name': name,
      'type': type,
    });
    if (response.statusCode != 200) throw Exception('카테고리 수정 실패');
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return CategoryModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  static Future<void> delete({required int id}) async {
    final response = await ApiClient.delete('/api/v1/categories/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('카테고리 삭제 실패');
    }
  }
}
