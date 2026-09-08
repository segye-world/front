import 'package:flutter/material.dart';
import 'routes.dart';
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

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.start:
        return MaterialPageRoute(
          builder: (_) => const StartScreen(),
          settings: settings,
        );
      case Routes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case Routes.signup:
        return MaterialPageRoute(
          builder: (_) => const SignupScreen(),
          settings: settings,
        );
      case Routes.main:
        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
          settings: settings,
        );
      case Routes.dayDetail:
        // 홈 진입 시 arguments 없이 들어오는 경로도 있어 타입 검사로 방어합니다.
        final args = settings.arguments;
        final selectedDate = args is DateTime ? args : DateTime.now();
        return MaterialPageRoute(
          builder: (_) => DayDetailScreen(selectedDate: selectedDate),
          settings: settings,
        );
      case Routes.cashDetail:
        return MaterialPageRoute(
          builder: (_) => const CashDetailScreen(),
          settings: settings,
        );
      case Routes.cashRecords:
        return MaterialPageRoute(
          builder: (_) => const CashRecordsScreen(),
          settings: settings,
        );
      case Routes.mypage:
        return MaterialPageRoute(
          builder: (_) => const MyPageScreen(),
          settings: settings,
        );
      case Routes.myExpenseCategory:
        return MaterialPageRoute(
          builder: (_) => const MyExpenseCategoryScreen(),
          settings: settings,
        );
      case Routes.myProfile:
        return MaterialPageRoute(
          builder: (_) => const MyProfileManageScreen(),
          settings: settings,
        );
      case Routes.myNotification:
        return MaterialPageRoute(
          builder: (_) => const MyNotificationSettingScreen(),
          settings: settings,
        );
      case Routes.myFaq:
        return MaterialPageRoute(
          builder: (_) => const MyFaqScreen(),
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
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Route: $title')),
    );
  }
}
