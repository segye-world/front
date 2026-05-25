import 'dart:convert';
import 'api_client.dart';
import '../models/schedule_model.dart';

class ScheduleApi {
  static Future<List<ScheduleModel>> fetchByDate(String date) async {
    final response = await ApiClient.get('/api/v1/schedules?date=$date');
    if (response.statusCode != 200) throw Exception('일정 조회 실패');
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final List<dynamic> data = body['data'] as List<dynamic>;
    return data
        .map((e) => ScheduleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<ScheduleModel> create({
    required String title,
    required String date,
    required int startHour,
    required int endHour,
    required String colorHex,
  }) async {
    final response = await ApiClient.post('/api/v1/schedules', {
      'title': title,
      'date': date,
      'startHour': startHour,
      'endHour': endHour,
      'colorHex': colorHex,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('일정 생성 실패');
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return ScheduleModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  static Future<void> delete(int id) async {
    final response = await ApiClient.delete('/api/v1/schedules/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('일정 삭제 실패');
    }
  }
}
