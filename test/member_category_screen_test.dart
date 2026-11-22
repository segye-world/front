import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segye_world/api/api_client.dart';
import 'package:segye_world/screen/day/my_expense_category_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final dio = ApiClient.instance.dio;
  late HttpClientAdapter originalAdapter;
  late _CategoryAdapter adapter;

  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'member-token'});
    originalAdapter = dio.httpClientAdapter;
    adapter = _CategoryAdapter();
    dio.httpClientAdapter = adapter;
  });

  tearDown(() => dio.httpClientAdapter = originalAdapter);

  Future<void> openCategories(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyExpenseCategoryScreen()));
    await tester.pumpAndSettle();
  }

  Future<void> confirmDelete(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
  }

  testWidgets('기본 수입원을 삭제한 뒤 화면을 다시 열어도 생성하지 않는다', (tester) async {
    await openCategories(tester);
    expect(find.text('월급'), findsOneWidget);

    await confirmDelete(tester);
    expect(find.text('월급'), findsNothing);
    expect(find.text('수입원 항목을 추가해 주세요.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await openCategories(tester);
    expect(find.text('월급'), findsNothing);
    expect(adapter.methods, ['GET', 'DELETE', 'GET', 'GET']);
    expect(adapter.authorization, everyElement('Bearer member-token'));
  });

  testWidgets('삭제가 거절되면 서버 메시지를 보여주고 항목은 유지한다', (tester) async {
    adapter.rejectDelete = true;
    await openCategories(tester);
    await confirmDelete(tester);

    expect(find.text(_CategoryAdapter.inUseMessage), findsOneWidget);
    expect(find.text('월급'), findsOneWidget);
    expect(adapter.methods, ['GET', 'DELETE']);
  });
}

class _CategoryAdapter implements HttpClientAdapter {
  static const inUseMessage = '수입·지출 기록에서 사용 중인 카테고리는 삭제할 수 없습니다.';

  final methods = <String>[];
  final authorization = <Object?>[];
  bool rejectDelete = false;
  bool _hasCategory = true;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    methods.add(options.method);
    authorization.add(options.headers['Authorization']);

    if (options.method == 'GET' && options.path == '/api/v1/categories') {
      return _response(200, {
        'data': [
          if (_hasCategory) {'id': 1, 'name': '월급', 'type': 'INCOME'},
        ],
      });
    }
    if (options.method == 'DELETE' && options.path == '/api/v1/categories/1') {
      if (rejectDelete) {
        return _response(400, {
          'error': {'message': inUseMessage},
        });
      }
      _hasCategory = false;
      return _response(200, {'success': true});
    }
    throw StateError('Unexpected request: ${options.method} ${options.path}');
  }

  ResponseBody _response(int status, Map<String, Object?> payload) {
    return ResponseBody.fromString(
      jsonEncode(payload),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
