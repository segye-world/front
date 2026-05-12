import 'package:flutter/material.dart';

import '../screen/auth/login_screen.dart';
import '../screen/auth/sighup_screen.dart';
import '../screen/cash/cash_detail__screen.dart';
import '../screen/cash/cash_records_screen.dart';
import '../screen/day/day_detail__screen.dart';
import '../screen/day/my_expense_category_screen.dart';
import '../screen/day/my_faq_screen.dart';
import '../screen/day/my_notification_setting_screen.dart';
import '../screen/day/my_profile_manage_screen.dart';
import '../screen/main_screen.dart';
import '../screen/my/mypage_screen.dart';
import '../screen/start/start_screen.dart';
import 'routes.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // ✅ 로그인 이메일 전달을 위해 라우트 arguments를 공통 파싱
    final args = settings.arguments;
    final loginEmail = args is Map<String, dynamic> ? (args['loginEmail'] as String? ?? '') : '';
    // ✅ 홈에서 선택한 날짜를 상세 화면으로 전달해 같은 날짜의 CRUD 데이터를 보여줍니다.
    final selectedDate = args is Map<String, dynamic> ? args['selectedDate'] as DateTime? : null;

    switch (settings.name) {
      case Routes.start:
        return MaterialPageRoute(builder: (_) => const StartScreen(), settings: settings);
      case Routes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen(), settings: settings);
      case Routes.signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen(), settings: settings);
      case Routes.main:
        return MaterialPageRoute(
          builder: (_) => MainScreen(loginEmail: loginEmail),
          settings: settings,
        );
      case Routes.dayDetail:
        return MaterialPageRoute(
          builder: (_) => DayDetailScreen(loginEmail: loginEmail, selectedDate: selectedDate),
          settings: settings,
        );
      case Routes.cashDetail:
        return MaterialPageRoute(
          builder: (_) => CashDetailScreen(loginEmail: loginEmail),
          settings: settings,
        );
      case Routes.cashRecords:
        return MaterialPageRoute(
          builder: (_) => CashRecordsScreen(loginEmail: loginEmail),
          settings: settings,
        );
      case Routes.mypage:
        return MaterialPageRoute(
          builder: (_) => MyPageScreen(loginEmail: loginEmail),
          settings: settings,
        );

      // ✅ 마이페이지 메뉴별 상세 화면 라우트
      case Routes.myExpenseCategory:
        return MaterialPageRoute(
          builder: (_) => MyExpenseCategoryScreen(loginEmail: loginEmail),
          settings: settings,
        );
      case Routes.myProfile:
        return MaterialPageRoute(
          builder: (_) => MyProfileManageScreen(loginEmail: loginEmail),
          settings: settings,
        );
      case Routes.myNotification:
        return MaterialPageRoute(
          builder: (_) => MyNotificationSettingScreen(loginEmail: loginEmail),
          settings: settings,
        );
      case Routes.myFaq:
        return MaterialPageRoute(
          builder: (_) => MyFaqScreen(loginEmail: loginEmail),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const _PlaceholderScreen(title: 'NOT FOUND'),
          settings: settings,
        );
    }
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(title)), body: Center(child: Text('Route: $title')));
  }
}
