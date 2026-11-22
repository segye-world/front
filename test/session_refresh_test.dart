import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segye_world/api/api_client.dart';
import 'package:segye_world/api/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TokenStorage storage;
  late ApiClient client;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = TokenStorage(useSecureStorage: false);
    client = ApiClient(tokenStorage: storage);
  });

  tearDown(() => client.dio.close(force: true));

  test('동시에 만료된 두 요청은 토큰을 한 번 갱신하고 각각 한 번 재시도한다', () async {
    await storage.saveSession(SessionTokens('access-old', 'refresh-old'));
    final oldRequests = Completer<void>();
    var rejects = 0;
    var refreshes = 0;
    var retries = 0;
    client.dio.httpClientAdapter = _Adapter((request) async {
      if (request.path.endsWith('/auth/refresh')) {
        refreshes++;
        expect(request.headers['Authorization'], isNull);
        expect(request.data, {'refreshToken': 'refresh-old'});
        await oldRequests.future;
        return _tokens('access-new', 'refresh-new');
      }
      if (request.headers['Authorization'] == 'Bearer access-old') {
        if (++rejects == 2) oldRequests.complete();
        return _json(401, {});
      }
      expect(request.headers['Authorization'], 'Bearer access-new');
      retries++;
      return _json(200, {});
    });

    await Future.wait([
      client.dio.get<dynamic>('/api/v1/schedules'),
      client.dio.post<dynamic>('/api/v1/todos', data: {'title': '할 일'}),
    ]);

    expect(refreshes, 1);
    expect(retries, 2);
    expect((await storage.read())?.refreshToken, 'refresh-new');
  });

  test('갱신이 401로 거절되면 세션을 정리하고 만료 이벤트를 보낸다', () async {
    await storage.saveSession(SessionTokens('access-old', 'refresh-invalid'));
    client.dio.httpClientAdapter = _Adapter((_) async => _json(401, {}));
    final expired = client.sessionExpired.first;

    await expectLater(
      client.dio.get<dynamic>('/api/v1/schedules'),
      throwsA(isA<DioException>()),
    );
    await expired;
    expect(await storage.read(), isNull);
  });

  test('로그아웃 후 도착한 갱신 응답은 세션을 되살리지 않는다', () async {
    await storage.saveSession(SessionTokens('access-old', 'refresh-old'));
    final started = Completer<void>();
    final reply = Completer<ResponseBody>();
    client.dio.httpClientAdapter = _Adapter((request) async {
      if (request.path.endsWith('/auth/refresh')) {
        started.complete();
        return reply.future;
      }
      expect(request.headers['Authorization'], 'Bearer access-old');
      return _json(401, {});
    });

    final request = expectLater(
      client.dio.get<dynamic>('/api/v1/schedules'),
      throwsA(isA<DioException>()),
    );
    await started.future;
    await storage.clearAll();
    reply.complete(_tokens('access-new', 'refresh-new'));
    await request;
    expect(await storage.read(), isNull);
  });

  test('시작할 때 유효한 토큰을 재사용하고 만료된 토큰은 갱신한다', () async {
    String accessToken(DateTime expiresAt) {
      final payload = base64Url.encode(
        utf8.encode(
          jsonEncode({'exp': expiresAt.millisecondsSinceEpoch ~/ 1000}),
        ),
      );
      return 'header.$payload.signature';
    }

    final now = DateTime.now();
    final validToken = accessToken(now.add(const Duration(hours: 1)));
    var refreshes = 0;
    client.dio.httpClientAdapter = _Adapter((request) async {
      expect(request.path, '/api/v1/auth/refresh');
      refreshes++;
      return _tokens(validToken, 'refresh-new');
    });
    await storage.saveSession(SessionTokens(validToken, 'refresh-old'));
    expect(await client.restoreSession(), isTrue);
    expect(refreshes, 0);

    await storage.saveSession(
      SessionTokens(
        accessToken(now.subtract(const Duration(hours: 1))),
        'refresh-old',
      ),
    );
    expect(await client.restoreSession(), isTrue);
    expect(refreshes, 1);
    expect((await storage.read())?.refreshToken, 'refresh-new');
  });

  test('모바일 보안 저장소에서 토큰 쌍을 복원하고 로그아웃 시 지운다', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('com.onharu.app/auth_session');
    String? stored;
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'read':
          return stored;
        case 'write':
          stored = call.arguments as String;
          return null;
        case 'delete':
          stored = null;
          return null;
      }
      throw StateError('Unexpected storage operation: ${call.method}');
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    await TokenStorage(
      useSecureStorage: true,
    ).saveSession(SessionTokens('access', 'refresh'));
    final restarted = TokenStorage(useSecureStorage: true);
    expect((await restarted.read())?.refreshToken, 'refresh');
    expect(
      (await SharedPreferences.getInstance()).getString('auth_token'),
      isNull,
    );

    await restarted.clearAll();
    expect(await TokenStorage(useSecureStorage: true).read(), isNull);
  });
}

ResponseBody _tokens(String accessToken, String refreshToken) => _json(200, {
  'data': {'accessToken': accessToken, 'refreshToken': refreshToken},
});

ResponseBody _json(int status, Map<String, dynamic> body) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);

  final Future<ResponseBody> Function(RequestOptions) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => respond(options);

  @override
  void close({bool force = false}) {}
}
