import 'dart:convert';

import '../models/payment_method_model.dart';
import 'api_client.dart';

/// 로그인한 사용자의 지출 수단만 다루는 API입니다.
///
/// 사용자 식별은 인증 토큰으로 처리하므로 다른 사용자의 수단과 섞이지 않습니다.
class PaymentMethodApi {
  static const _path = '/api/v1/payment-methods';

  static Future<List<PaymentMethodModel>> fetchAll() async {
    final response = await ApiClient.get(_path);
    if (response.statusCode != 200) throw Exception('지출 수단 조회 실패');
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;
    return data
        .map((item) => PaymentMethodModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<PaymentMethodModel> create({required String name}) async {
    final response = await ApiClient.post(_path, {'name': name});
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('지출 수단 추가 실패');
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return PaymentMethodModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  static Future<PaymentMethodModel> update({
    required int id,
    required String name,
  }) async {
    final response = await ApiClient.put('$_path/$id', {'name': name});
    if (response.statusCode != 200) throw Exception('지출 수단 수정 실패');
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return PaymentMethodModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  static Future<void> delete({required int id}) async {
    final response = await ApiClient.delete('$_path/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('지출 수단 삭제 실패');
    }
  }
}
