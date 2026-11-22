import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models/account_record_model.dart';

class CategoryApi {
  static const _path = '${ApiConfig.apiPrefix}/categories';
  static final _dio = ApiClient.instance.dio;

  static Future<List<CategoryModel>> fetchAll() async {
    final response = await _dio.get<Map<String, dynamic>>(_path);
    final data = response.data!['data'] as List<dynamic>;
    return data
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<CategoryModel> create({
    required String name,
    required String type,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _path,
      data: {'name': name, 'type': type},
    );
    return CategoryModel.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  static Future<CategoryModel> update({
    required int id,
    required String name,
    required String type,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_path/$id',
      data: {'name': name, 'type': type},
    );
    return CategoryModel.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  static Future<void> delete({required int id}) async {
    await _dio.delete<void>('$_path/$id');
  }
}
