import 'dart:convert';
import 'api_client.dart';
import '../models/todo_model.dart';

class TodoApi {
  static Future<List<TodoModel>> fetchByDate(String date) async {
    final response = await ApiClient.get('/api/v1/todos?date=$date');
    if (response.statusCode != 200) throw Exception('할 일 조회 실패');
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final List<dynamic> data = body['data'] as List<dynamic>;
    return data
        .map((e) => TodoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<TodoModel> create({
    required String label,
    required String date,
    int? scheduleId,
  }) async {
    final response = await ApiClient.post('/api/v1/todos', {
      'label': label,
      'date': date,
      if (scheduleId != null) 'scheduleId': scheduleId,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('할 일 생성 실패');
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return TodoModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  static Future<TodoModel> update(int id, {String? label, bool? isDone}) async {
    final reqBody = <String, dynamic>{};
    if (label != null) reqBody['label'] = label;
    if (isDone != null) reqBody['isDone'] = isDone;
    final response = await ApiClient.put('/api/v1/todos/$id', reqBody);
    if (response.statusCode != 200) throw Exception('할 일 수정 실패');
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return TodoModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  static Future<void> delete(int id) async {
    final response = await ApiClient.delete('/api/v1/todos/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('할 일 삭제 실패');
    }
  }
}
