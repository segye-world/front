import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'api/kakao_config.dart';
import 'app.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 키 없이 실행해도 앱은 뜨고, 로그인 시도 시 설정 안내를 보여줍니다.
  if (KakaoConfig.isConfigured) {
    KakaoSdk.init(nativeAppKey: KakaoConfig.nativeAppKey);
  }
  await NotificationService.instance.init();
  runApp(const MyApp());
}
