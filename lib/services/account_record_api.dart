import 'dart:convert';
import 'api_client.dart';
import '../models/account_record_model.dart';

class AccountRecordApi {
  // 친구 백엔드: GET /api/v1/account-records?from=YYYY-MM-DD&to=YYYY-MM-DD
  static Future<List<AccountRecordModel>> fetchByDate(String date) async {
    final response = await ApiClient.get(
      '/api/v1/account-records?from=$date&to=$date',
    );
    if (response.statusCode != 200) throw Exception('가계부 조회 실패');
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final List<dynamic> data = body['data'] as List<dynamic>;
    return data
        .map((e) => AccountRecordModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // 친구 백엔드 요청 형식: { categoryId, amount, transactionTime, scheduleId }
  // amount: 항상 양수 전송 (categoryType으로 수입/지출 구분)
  static Future<AccountRecordModel> create({
    required int amount,
    required int categoryId,
    int? scheduleId,
    required String date, // YYYY-MM-DD
  }) async {
    final response = await ApiClient.post('/api/v1/account-records', {
      'categoryId': categoryId,
      'amount': amount,
      'transactionTime': '${date}T00:00:00',
      if (scheduleId != null) 'scheduleId': scheduleId,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('가계부 기록 생성 실패');
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return AccountRecordModel.fromJson(body['data'] as Map<String, dynamic>);
  }
}
