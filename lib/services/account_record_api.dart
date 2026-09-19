import 'dart:convert';
import 'api_client.dart';
import '../models/account_record_model.dart';

class AccountRecordApi {
  // 친구 백엔드: GET /api/v1/account-records?from=YYYY-MM-DD&to=YYYY-MM-DD
  static Future<List<AccountRecordModel>> fetchByDate(String date) =>
      fetchByDateRange(date, date);

  static Future<List<AccountRecordModel>> fetchByDateRange(
      String from, String to) async {
    final response = await ApiClient.get(
      '/api/v1/account-records?from=$from&to=$to',
    );
    if (response.statusCode != 200) throw Exception('가계부 조회 실패');
    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final List<dynamic> data = body['data'] as List<dynamic>;
    return data
        .map((e) => AccountRecordModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // 요청 형식: { categoryId, sourceCategoryId, amount, transactionTime, scheduleId }
  // amount: 항상 양수 전송 (categoryType으로 수입/지출 구분)
  // sourceCategoryId: 지출이 빠져나간 수입원(=지출 수단) 카테고리 id. 지출에만 필요하다.
  static Future<AccountRecordModel> create({
    required int amount,
    required int categoryId,
    int? scheduleId,
    int? sourceCategoryId,
    required DateTime transactionTime,
  }) async {
    final response = await ApiClient.post('/api/v1/account-records', {
      'categoryId': categoryId,
      'amount': amount,
      if (sourceCategoryId != null) 'sourceCategoryId': sourceCategoryId,
      'transactionTime': _isoLocal(transactionTime),
      if (scheduleId != null) 'scheduleId': scheduleId,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('가계부 기록 생성 실패');
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return AccountRecordModel.fromJson(body['data'] as Map<String, dynamic>);
  }
}

/// 백엔드 LocalDateTime 형식(yyyy-MM-ddTHH:mm:ss)에 맞춰 타임존 없이 직렬화합니다.
String _isoLocal(DateTime dt) {
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${pad(dt.month)}-${pad(dt.day)}'
      'T${pad(dt.hour)}:${pad(dt.minute)}:${pad(dt.second)}';
}
