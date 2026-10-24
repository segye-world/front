import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segye_world/screen/day/my_notification_setting_screen.dart';
import 'package:segye_world/services/notification_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  FilledButton saveButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, '저장'));

  Switch switchOf(WidgetTester tester, String title) => tester.widget<Switch>(
        find.descendant(
          of: find.ancestor(of: find.text(title), matching: find.byType(Row)).last,
          matching: find.byType(Switch),
        ),
      );

  testWidgets('바꾼 게 없으면 저장 버튼이 꺼져 있고, 바꾸면 켜지고, 저장하면 다시 꺼진다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyNotificationSettingScreen()));
    await tester.pumpAndSettle();

    expect(saveButton(tester).onPressed, isNull);

    await tester.tap(find.byType(Switch).at(1));
    await tester.pumpAndSettle();
    expect(saveButton(tester).onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pumpAndSettle();

    expect(saveButton(tester).onPressed, isNull);
    expect(find.text('알림 설정을 저장했어요.'), findsOneWidget);
    final saved = await NotificationSettings.load();
    expect(saved, const NotificationSettings(scheduleEnd: false));
  });

  testWidgets('저장하지 않은 변경은 저장소에 쓰지 않는다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyNotificationSettingScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(await NotificationSettings.load(), const NotificationSettings());
  });

  testWidgets('알림 권한이 없으면 스위치를 켜지 않고 설정 앱으로 안내한다', (tester) async {
    // 테스트 환경은 알림 권한을 받을 수 없어 거절된 경우와 같습니다.
    SharedPreferences.setMockInitialValues({'notif_schedule_end': false});
    await tester.pumpWidget(const MaterialApp(home: MyNotificationSettingScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).at(1));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch).at(1)).value, isFalse);
    expect(find.text('기기 설정에서 알림을 허용해 주세요.'), findsOneWidget);
    expect(find.text('설정 열기'), findsWidgets);
    expect(saveButton(tester).onPressed, isNull);
  });

  testWidgets('주간 리포트는 준비 중 배지와 함께 꺼진 채 비활성이다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyNotificationSettingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('준비 중'), findsOneWidget);
    final weekly = switchOf(tester, '주간 소비 리포트');
    expect(weekly.value, isFalse);
    expect(weekly.onChanged, isNull);
  });
}
