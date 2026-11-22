import 'dart:async';

import 'package:flutter/material.dart';
import 'api/api_client.dart';
import 'routes/app_router.dart';
import 'routes/routes.dart';
import 'services/notification_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_radius.dart';
import 'theme/app_text_styles.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final StreamSubscription<void> _sessionSubscription;

  @override
  void initState() {
    super.initState();
    _sessionSubscription = ApiClient.instance.sessionExpired.listen((_) async {
      if (!mounted || await ApiClient.instance.tokenStorage.read() != null) {
        return;
      }
      final notifications = NotificationService.instance;
      try {
        await notifications.clear();
      } finally {
        if (mounted && await ApiClient.instance.tokenStorage.read() == null) {
          notifications.navigatorKey.currentState?.pushNamedAndRemoveUntil(
            Routes.login,
            (_) => false,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _sessionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationService.instance.navigatorKey,
      title: '온하루',
      initialRoute: Routes.session,
      onGenerateInitialRoutes: (route) => [
        AppRouter.generateRoute(RouteSettings(name: route)),
      ],
      onGenerateRoute: AppRouter.generateRoute,
      theme: _buildTheme(),
    );
  }

  ThemeData _buildTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryPink,
      primary: AppColors.primaryPink,
      onPrimary: Colors.white,
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: const TextTheme(
        titleLarge: AppTextStyles.title,
        titleMedium: AppTextStyles.subtitle,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.caption,
        labelLarge: AppTextStyles.label,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryPink,
          foregroundColor: Colors.white,
          shape: buttonShape,
          textStyle: AppTextStyles.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navyDark,
          side: const BorderSide(color: AppColors.cardBorder),
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.navyDark),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        titleTextStyle: AppTextStyles.title,
        contentTextStyle: AppTextStyles.body,
      ),
    );
  }
}
