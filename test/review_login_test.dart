import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segye_world/api/api_client.dart';
import 'package:segye_world/api/auth_api.dart';
import 'package:segye_world/api/token_storage.dart';
import 'package:segye_world/routes/app_router.dart';
import 'package:segye_world/routes/routes.dart';
import 'package:segye_world/screen/auth/login_screen.dart';
import 'package:segye_world/screen/auth/review_login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TokenStorage storage;
  late ApiClient client;
  late AuthApi authApi;
  final requests = <RequestOptions>[];

  void respondWith(int status, Map<String, dynamic> body) {
    client.dio.httpClientAdapter = _Adapter((request) async {
      requests.add(request);
      return _json(status, body);
    });
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = TokenStorage(useSecureStorage: false);
    client = ApiClient(tokenStorage: storage);
    authApi = AuthApi(client: client);
    requests.clear();
  });

  tearDown(() => client.dio.close(force: true));

  group('AuthApi.loginForReview', () {
    test('아이디·비밀번호를 보내고 세션과 심사자 닉네임을 저장한다', () async {
      await storage.saveSession(SessionTokens('stale-access', 'stale-refresh'));
      respondWith(200, {
        'success': true,
        'data': {'accessToken': 'access', 'refreshToken': 'refresh', 'isNewMember': true},
      });

      final isNew = await authApi.loginForReview(loginId: 'reviewer', password: 'pw');

      expect(isNew, isTrue);
      expect(requests.single.path, endsWith('/auth/review-login'));
      expect(requests.single.data, {'loginId': 'reviewer', 'password': 'pw'});
      // 남아 있던 세션의 토큰이 로그인 요청에 실리지 않는다.
      expect(requests.single.headers['Authorization'], isNull);
      final saved = await storage.read();
      expect(saved?.accessToken, 'access');
      expect(saved?.refreshToken, 'refresh');
      expect(await storage.readNickname(), AuthApi.reviewerNickname);
    });

    test('다시 로그인하면 isNewMember 가 false 다', () async {
      respondWith(200, {
        'success': true,
        'data': {'accessToken': 'a', 'refreshToken': 'r', 'isNewMember': false},
      });

      expect(await authApi.loginForReview(loginId: 'reviewer', password: 'pw'), isFalse);
    });

    test('틀리면 예외가 나고 세션을 저장하지 않는다', () async {
      respondWith(401, _error('UNAUTHORIZED', '아이디 또는 비밀번호가 올바르지 않습니다.'));

      await expectLater(
        authApi.loginForReview(loginId: 'reviewer', password: 'wrong'),
        throwsA(isA<DioException>()),
      );
      expect(await storage.read(), isNull);
    });
  });

  group('ReviewLoginScreen', () {
    Future<void> pumpScreen(WidgetTester tester) => tester.pumpWidget(
          MaterialApp(home: ReviewLoginScreen(authApi: authApi)),
        );

    Future<void> fillAndSubmit(WidgetTester tester, {String password = 'wrong'}) async {
      await tester.enterText(find.byKey(const Key('reviewLoginId')), ' reviewer ');
      await tester.enterText(find.byKey(const Key('reviewPassword')), password);
      // 입력값이 반영돼 버튼이 켜지도록 다시 그린다.
      await tester.pump();
      // Dio 응답 처리는 실제 비동기라 가짜 시간(pump)만으로는 끝나지 않는다.
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(FilledButton, '로그인'));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
    }

    testWidgets('아이디와 비밀번호를 모두 넣어야 로그인 버튼이 눌린다', (tester) async {
      await pumpScreen(tester);
      FilledButton button() => tester.widget(find.widgetWithText(FilledButton, '로그인'));

      expect(button().onPressed, isNull);
      await tester.enterText(find.byKey(const Key('reviewLoginId')), 'reviewer');
      await tester.pump();
      expect(button().onPressed, isNull);
      await tester.enterText(find.byKey(const Key('reviewPassword')), 'pw');
      await tester.pump();
      expect(button().onPressed, isNotNull);
    });

    testWidgets('틀리면 서버 메시지를 보여주고, 아이디 앞뒤 공백은 빼고 보낸다', (tester) async {
      respondWith(401, _error('UNAUTHORIZED', '아이디 또는 비밀번호가 올바르지 않습니다.'));
      await pumpScreen(tester);

      await fillAndSubmit(tester);

      expect(find.text('아이디 또는 비밀번호가 올바르지 않습니다.'), findsOneWidget);
      expect(requests.single.data, {'loginId': 'reviewer', 'password': 'wrong'});
    });

    testWidgets('잠기면 잠시 후 다시 시도하라는 서버 메시지를 보여준다', (tester) async {
      respondWith(429, _error('TOO_MANY_REQUESTS', '로그인 시도가 너무 많습니다. 잠시 후 다시 시도해주세요.'));
      await pumpScreen(tester);

      await fillAndSubmit(tester);

      expect(find.text('로그인 시도가 너무 많습니다. 잠시 후 다시 시도해주세요.'), findsOneWidget);
    });

    testWidgets('서버에서 꺼져 있으면(404) 이 방법을 쓸 수 없다고 안내한다', (tester) async {
      respondWith(404, _error('NOT_FOUND', '요청한 경로를 찾을 수 없습니다.'));
      await pumpScreen(tester);

      await fillAndSubmit(tester);

      expect(find.text('지금은 이 방법으로 로그인할 수 없습니다.'), findsOneWidget);
    });
  });

  testWidgets('로그인 화면의 "다른 방법으로 로그인"을 누르면 심사용 로그인 화면이 열린다', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: LoginScreen(),
      onGenerateRoute: AppRouter.generateRoute,
    ));

    await tester.tap(find.text('다른 방법으로 로그인'));
    await tester.pumpAndSettle();

    expect(find.byType(ReviewLoginScreen), findsOneWidget);
    expect(ModalRoute.of(tester.element(find.byType(ReviewLoginScreen)))?.settings.name,
        Routes.reviewLogin);

    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}

Map<String, dynamic> _error(String code, String message) => {
      'success': false,
      'error': {'code': code, 'message': message},
    };

ResponseBody _json(int status, Map<String, dynamic> body) => ResponseBody.fromString(
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
  ) =>
      respond(options);

  @override
  void close({bool force = false}) {}
}
