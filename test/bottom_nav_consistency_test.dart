import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segye_world/screen/cash/cash_detail__screen.dart';
import 'package:segye_world/screen/cash/cash_records_screen.dart';
import 'package:segye_world/screen/day/day_detail__screen.dart';
import 'package:segye_world/screen/day/my_expense_category_screen.dart';
import 'package:segye_world/screen/day/my_faq_screen.dart';
import 'package:segye_world/screen/day/my_notification_setting_screen.dart';
import 'package:segye_world/screen/day/my_profile_manage_screen.dart';
import 'package:segye_world/screen/main_screen.dart';
import 'package:segye_world/screen/my/mypage_screen.dart';
import 'package:segye_world/theme/app_colors.dart';
import 'package:segye_world/theme/app_glass.dart';
import 'package:segye_world/widgets/template/bottom_nav_layout.dart';

/// 하단 바를 가진 화면과, 각 화면에서 선택돼 있어야 하는 탭.
final screens = <String, (Widget, AppNavItem)>{
  '일정 상세': (DayDetailScreen(selectedDate: DateTime(2026, 8, 27)), AppNavItem.home),
  '메인': (const MainScreen(), AppNavItem.home),
  '캐시 상세': (const CashDetailScreen(), AppNavItem.cash),
  '캐시 내역': (const CashRecordsScreen(), AppNavItem.cash),
  '마이페이지': (const MyPageScreen(), AppNavItem.mypage),
  '소비 카테고리': (const MyExpenseCategoryScreen(), AppNavItem.mypage),
  '프로필 관리': (const MyProfileManageScreen(), AppNavItem.mypage),
  '알림 설정': (const MyNotificationSettingScreen(), AppNavItem.mypage),
  'FAQ': (const MyFaqScreen(), AppNavItem.mypage),
};

void main() {
  for (final entry in screens.entries) {
    final (screen, expectedItem) = entry.value;

    testWidgets('${entry.key} 화면의 하단 바가 공용 바로 통일돼 있다', (tester) async {
      // 화면별로 무관한 디버그 경고가 있어 이 테스트의 관심사만 남깁니다.
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final message = details.exceptionAsString();
        if (message.contains('ListTile background color or ink splashes') ||
            message.contains('A RenderFlex overflowed')) {
          return;
        }
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(MaterialApp(home: screen));
      // 일부 화면은 로딩 인디케이터가 계속 돌아 pumpAndSettle이 끝나지 않으므로,
      // 하단 바가 그려질 만큼만 프레임을 진행합니다.
      await tester.pump(const Duration(milliseconds: 300));

      // 공용 바가 정확히 하나 있고,
      final barFinder = find.byType(AppBottomNavBar);
      expect(barFinder, findsOneWidget);
      expect(
        tester.widget<AppBottomNavBar>(barFinder).currentItem,
        expectedItem,
      );

      // 유리(Liquid Glass) 형태로 그려지고,
      expect(
        find.descendant(of: barFinder, matching: find.byType(BackdropFilter)),
        AppGlass.useBlur ? findsOneWidget : findsNothing,
      );

      // 세 탭이 같은 구성(아이콘 + 라벨)이며,
      // (라벨은 굵기 변화로 글자가 움직이지 않도록 자리 잡기용 사본이 하나 더 있습니다.)
      for (final label in ['CASH', 'HOME', 'MYPAGE']) {
        expect(
          find.descendant(of: barFinder, matching: find.text(label)),
          findsWidgets,
        );
      }

      // 현재 화면에 맞는 탭만 브랜드 색으로 선택돼 있습니다.
      const icons = {
        AppNavItem.cash: Icons.wallet,
        AppNavItem.home: Icons.home,
        AppNavItem.mypage: Icons.person,
      };
      for (final MapEntry(key: item, value: icon) in icons.entries) {
        final iconWidget = tester.widget<Icon>(
          find.descendant(of: barFinder, matching: find.byIcon(icon)),
        );
        expect(
          iconWidget.color,
          item == expectedItem ? AppColors.primary : AppColors.textSecondary,
        );
      }
    });
  }
}
