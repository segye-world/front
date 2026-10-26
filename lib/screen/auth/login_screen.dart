import 'dart:async';

import 'package:flutter/material.dart';

import '../../routes/routes.dart';
import '../../api/auth_api.dart';
import '../../api/api_error.dart';
import '../../services/notification_service.dart';
import '../../widgets/common/kakao_login_button.dart';
import '../../widgets/template/auth_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthApi _authApi = AuthApi();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _loginWithKakao() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authApi.loginWithKakao();
      // 권한 요청 다이얼로그가 다음 화면 위에 뜨도록 기다리지 않습니다.
      unawaited(NotificationService.instance.onLogin());
      if (!mounted) return;
      // 로그인 후 홈은 오늘 날짜의 일정 상세 화면입니다. 로그인 전에 누른 알림이 있으면 그 날짜로 엽니다.
      Navigator.of(context).pushReplacementNamed(
        Routes.dayDetail,
        arguments: NotificationService.instance.takePendingDate() ?? DateTime.now(),
      );
    } on KakaoLoginCanceled {
      // 사용자가 직접 닫은 것이므로 아무 메시지도 띄우지 않는다.
    } on KakaoLoginFailed catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage =
          apiErrorMessage(e, fallback: '로그인에 실패했습니다.'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 3),
          const Center(child: AuthSymbol()),
          const Spacer(flex: 3),
          KakaoLoginButton(
            onPressed: _loginWithKakao,
            isLoading: _isLoading,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
