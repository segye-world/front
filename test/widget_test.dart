import 'package:flutter_test/flutter_test.dart';
import 'package:segye_world/app.dart';

void main() {
  testWidgets('홈 화면에 ERD 기반 목데이터가 표시된다', (WidgetTester tester) async {
    // 메인 라우트로 시작해 회원/일정 목데이터가 홈에 노출되는지 확인합니다.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('segye'), findsOneWidget);
    expect(find.text('아침 운동'), findsOneWidget);
    expect(find.text('친구 약속'), findsOneWidget);
  });
}
