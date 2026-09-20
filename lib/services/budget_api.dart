import 'dart:convert';

import '../models/budget_model.dart';
import 'api_client.dart';

/// 로그인한 사용자의 월별 지출 목표(한도)를 다루는 API입니다.
class BudgetApi {
  static const _path = '/api/v1/budgets';

  static Future<BudgetModel?> fetch({required int year, required int month}) async {
    final response = await ApiClient.get('$_path?year=$year&month=$month');
    if (response.statusCode != 200) throw Exception('지출 목표 조회 실패');
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) return null;
    return BudgetModel.fromJson(data);
  }

  static Future<BudgetModel> upsert({
    required int year,
    required int month,
    required int limitAmount,
  }) async {
    final response = await ApiClient.post(_path, {
      'year': year,
      'month': month,
      'limitAmount': limitAmount,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('지출 목표 저장 실패');
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return BudgetModel.fromJson(body['data'] as Map<String, dynamic>);
  }
}
