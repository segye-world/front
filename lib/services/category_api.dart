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
}
