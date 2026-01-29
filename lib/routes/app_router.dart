import 'package:flutter/material.dart';
import 'routes.dart';
import '../screen/main_screen.dart';

// TODO: 화면들 만들면 여기 import 추가
// import '../screens/start/start_screen.dart';
// import '../screens/auth/login_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.start:
        return MaterialPageRoute(
          builder: (_) => const _PlaceholderScreen(title: 'START'),
          settings: settings,
        );
      case Routes.main:
        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
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
