import 'dart:convert';
import 'api_client.dart';
import '../models/schedule_model.dart';
import 'notification_service.dart';

class ScheduleApi {
  /// 서버가 한 번에 허용하는 최대 조회 일수 (양끝 포함). segye-world/back#25
  static const int maxRangeDays = 31;

  static Future<List<ScheduleModel>> fetchByDate(String date) =>
      _fetch('/api/v1/schedules?date=$date');

  /// [from]~[to] (yyyy-MM-dd, 양끝 포함) 일정을 날짜·시작 시각 순으로 불러옵니다.
  /// 구간은 최대 [maxRangeDays]일입니다.
  static Future<List<ScheduleModel>> fetchRange(String from, String to) =>
      _fetch('/api/v1/schedules?from=$from&to=$to');

  static Future<List<ScheduleModel>> _fetch(String path) async {
    final response = await ApiClient.get(path);
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
    required int startMinute,
    required int endMinute,
    required String colorHex,
  }) async {
    final response = await ApiClient.post('/api/v1/schedules', {
      'title': title,
      'date': date,
      'startMinute': startMinute,
      'endMinute': endMinute,
      'colorHex': colorHex,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('일정 생성 실패');
    }
    NotificationService.instance.requestSync();
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return ScheduleModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  static Future<ScheduleModel> update({
    required int id,
    required String title,
    required int startMinute,
    required int endMinute,
    required String colorHex,
  }) async {
    final response = await ApiClient.put('/api/v1/schedules/$id', {
      'title': title,
      'startMinute': startMinute,
      'endMinute': endMinute,
      'colorHex': colorHex,
    });
    if (response.statusCode != 200) throw Exception('일정 수정 실패');
    NotificationService.instance.requestSync();
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return ScheduleModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  static Future<void> delete(int id) async {
    final response = await ApiClient.delete('/api/v1/schedules/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('일정 삭제 실패');
    }
    NotificationService.instance.requestSync();
  }
}
