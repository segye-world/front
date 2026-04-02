import 'package:flutter/material.dart';
import 'routes/app_router.dart';
import 'routes/routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cash Diary',
      initialRoute: Routes.login,
      onGenerateRoute: AppRouter.generateRoute,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF7A5A5),
        ),
      ),
    );
  }
}
