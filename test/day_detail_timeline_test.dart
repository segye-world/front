import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segye_world/screen/day/day_detail__screen.dart';

/// 화면 좌표 기준 '할 일' 탭의 x 위치. 패널이 얼마나 밀렸는지 확인하는 데 씁니다.
double todoTabLeft(WidgetTester tester) =>
    tester.getTopLeft(find.text('할 일')).dx;

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    // 상세 패널의 ListTile이 배경색 있는 DecoratedBox 안에 있어 디버그 경고가 뜹니다.
    // 이 테스트의 관심사가 아니므로 해당 경고만 걸러내고, 다른 예외는 그대로 실패시킵니다.
    // (테스트 바인딩이 테스트 본문 진입 시 핸들러를 세팅하므로 setUp이 아니라 여기서 감쌉니다.)
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details
          .exceptionAsString()
          .contains('ListTile background color or ink splashes')) {
        return;
      }
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(
      MaterialApp(home: DayDetailScreen(selectedDate: DateTime(2026, 8, 27))),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('접힌 상태에서는 상세 패널이 보이고 화살표 버튼은 없다', (tester) async {
    await pumpScreen(tester);

    expect(find.text('할 일'), findsOneWidget);
    expect(find.text('수입 · 지출'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsNothing);
  });

  testWidgets('타임라인을 아래로 내리면 다음 일자로 이어진다', (tester) async {
    await pumpScreen(tester);

    // 8/27(목)로 시작하므로 첫 화면에는 다음 날 머리글이 아직 없습니다.
    expect(find.text('08월 27일 (목)'), findsOneWidget);
    expect(find.text('08월 28일 (금)'), findsNothing);

    // 타임라인을 펼치고 아래로 내립니다.
    await tester.dragFrom(const Offset(20, 300), const Offset(600, 0));
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(200, 300), const Offset(0, -700));
    await tester.pumpAndSettle();

    // 23시에서 끊기지 않고 다음 일자가 이어집니다.
    expect(find.text('08월 28일 (금)'), findsOneWidget);
    expect(find.text('23:00'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);

    // 더 내리면 그 다음 일자까지 계속 이어집니다.
    await tester.dragFrom(const Offset(200, 300), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('08월 29일 (토)'), findsOneWidget);
  });

  testWidgets('타임라인을 오른쪽으로 밀면 패널이 밀려나고 화살표 버튼이 생긴다', (tester) async {
    await pumpScreen(tester);
    final collapsedLeft = todoTabLeft(tester);

    // 좌측 타임라인 레일을 잡아 오른쪽으로 끕니다.
    // 좌측 레일(폭 44) 위에서 오른쪽으로 크게 끌어 펼칩니다.
    await tester.dragFrom(const Offset(20, 300), const Offset(600, 0));
    await tester.pumpAndSettle();

    // 패널이 화면 오른쪽으로 밀려났고,
    expect(todoTabLeft(tester), greaterThan(collapsedLeft));
    // 우측 끝에 되돌리기용 화살표 버튼이 생겼습니다.
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
  });

  testWidgets('화살표 버튼을 누르면 패널이 제자리로 돌아온다', (tester) async {
    await pumpScreen(tester);
    final collapsedLeft = todoTabLeft(tester);

    // 좌측 레일(폭 44) 위에서 오른쪽으로 크게 끌어 펼칩니다.
    await tester.dragFrom(const Offset(20, 300), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(todoTabLeft(tester), collapsedLeft);
    expect(find.byIcon(Icons.chevron_left), findsNothing);
  });
}
