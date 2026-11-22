import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/api_error.dart';
import '../../routes/routes.dart';
import '../../services/notification_service.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  String? _failure;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    setState(() => _failure = null);
    try {
      final restored = await ApiClient.instance.restoreSession();
      if (!mounted) return;
      final notifications = NotificationService.instance;
      if (restored) unawaited(notifications.onLogin());
      Navigator.of(context).pushReplacementNamed(
        restored ? Routes.dayDetail : Routes.login,
        arguments: restored ? notifications.takePendingDate() : null,
      );
    } catch (error) {
      if (!mounted) return;
      setState(
        () =>
            _failure = apiErrorMessage(error, fallback: '로그인 상태를 확인하지 못했습니다.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    return Scaffold(
      body: Center(
        child: failure == null
            ? const CircularProgressIndicator(semanticsLabel: '로그인 확인 중')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(failure, textAlign: TextAlign.center),
                  ),
                  TextButton(onPressed: _restore, child: const Text('다시 시도')),
                  TextButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushReplacementNamed(Routes.login),
                    child: const Text('로그인 화면으로'),
                  ),
                ],
              ),
      ),
    );
  }
}
