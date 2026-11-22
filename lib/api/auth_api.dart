import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'api_client.dart';
import 'api_config.dart';
import 'kakao_config.dart';
import 'token_storage.dart';

/// 사용자가 카카오 로그인 화면에서 직접 취소한 경우. 에러 메시지를 띄우지 않는다.
class KakaoLoginCanceled implements Exception {}

/// 카카오 SDK 단계에서 실패한 경우(앱 키 미설정, 키 해시 불일치 등).
class KakaoLoginFailed implements Exception {
  KakaoLoginFailed(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthApi {
  AuthApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  /// 카카오로 로그인하고 서버 JWT 를 저장한다. 처음 가입한 회원이면 true 를 돌려준다.
  Future<bool> loginWithKakao() async {
    final kakaoToken = await _loginWithKakaoSdk();

    // 새 로그인에는 기존 세션이 필요하지 않습니다. 오래되었거나 유효하지
    // 않은 토큰이 인터셉터를 통해 로그인 요청에 실리는 것을 방지합니다.
    await _client.tokenStorage.clearAll();

    final response = await _client.dio.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/auth/kakao',
      data: {'accessToken': kakaoToken.accessToken},
    );

    final tokens = SessionTokens.fromResponse(response.data);
    await _client.tokenStorage.saveSession(tokens);
    await _saveNickname(tokens.sessionId);
    final data = response.data?['data'];
    return data is Map && data['isNewMember'] == true;
  }

  /// 스토어 심사용 아이디·비밀번호로 로그인하고 서버 JWT 를 저장한다(back #18 review-login).
  /// 처음 로그인이면 true 를 돌려준다. 서버에서 꺼져 있으면 404, 틀리면 401, 잠기면 429 다.
  Future<bool> loginForReview({
    required String loginId,
    required String password,
  }) async {
    await _client.tokenStorage.clearAll();

    final response = await _client.dio.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/auth/review-login',
      data: {'loginId': loginId, 'password': password},
    );

    final tokens = SessionTokens.fromResponse(response.data);
    await _client.tokenStorage.saveSession(tokens);
    // 카카오 계정이 없으므로 서버가 만든 심사용 회원의 닉네임을 그대로 쓴다.
    await _client.tokenStorage.saveNickname(reviewerNickname, tokens.sessionId);
    final data = response.data?['data'];
    return data is Map && data['isNewMember'] == true;
  }

  static const reviewerNickname = '심사자';

  Future<OAuthToken> _loginWithKakaoSdk() async {
    if (!KakaoConfig.isConfigured) {
      throw KakaoLoginFailed(
        '카카오 앱 키가 설정되지 않았습니다. --dart-define-from-file=dart_defines.json 으로 실행해주세요.',
      );
    }

    try {
      if (await isKakaoTalkInstalled()) {
        try {
          return await UserApi.instance.loginWithKakaoTalk();
        } catch (e) {
          // 카카오톡 동의 화면에서 취소했으면 계정 로그인으로 넘기지 않는다.
          if (_isCanceled(e)) rethrow;
          // 카카오톡에 로그인돼 있지 않은 경우 등은 카카오계정 로그인으로 대신한다.
        }
      }
      return await UserApi.instance.loginWithKakaoAccount();
    } catch (e) {
      if (_isCanceled(e)) throw KakaoLoginCanceled();
      debugPrint('카카오 SDK 로그인 실패: $e');
      throw KakaoLoginFailed('카카오 로그인에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  // 로그인 창을 닫으면 CANCELED, 카카오 동의 화면에서 [취소]를 누르면 access_denied 가 온다.
  bool _isCanceled(Object e) {
    if (e is PlatformException) {
      return e.code == 'CANCELED' || e.code == 'access_denied';
    }
    return e is KakaoAuthException && e.error == AuthErrorCause.accessDenied;
  }

  /// 마이페이지 표시용 닉네임. 서버의 내 정보 조회(back #20)가 생기기 전까지 카카오에서 직접 받는다.
  Future<void> _saveNickname(Object sessionId) async {
    try {
      final user = await UserApi.instance.me();
      final nickname = user.kakaoAccount?.profile?.nickname;
      if (nickname != null && nickname.isNotEmpty) {
        await _client.tokenStorage.saveNickname(nickname, sessionId);
      }
    } catch (e) {
      // 닉네임은 표시용이라 실패해도 로그인은 계속한다.
      debugPrint('카카오 닉네임 조회 실패: $e');
    }
  }

  Future<void> logout() async {
    final tokens = await _client.tokenStorage.clearAll();
    final refreshToken = tokens?.refreshToken;
    try {
      if (refreshToken != null) {
        await _client.dio.post<void>(
          '${ApiConfig.apiPrefix}/auth/logout',
          data: {'refreshToken': refreshToken},
        );
      }
    } on DioException {
      // 네트워크 오류가 있어도 이 기기에서는 로그아웃을 마친다.
    } finally {
      await _clearKakaoToken();
    }
  }

  /// 서버가 회원 데이터를 지우고 카카오 연결도 끊는다. 앱은 남은 토큰만 정리한다.
  Future<void> deleteAccount() async {
    await _client.dio.delete('${ApiConfig.apiPrefix}/members/me');
    await _client.tokenStorage.clearAll();
    await _clearKakaoToken();
  }

  Future<void> _clearKakaoToken() async {
    if (!KakaoConfig.isConfigured) return;
    try {
      // 서버 연결 끊기 뒤에는 API 호출이 실패하지만, SDK 는 실패해도 저장된 토큰을 지운다.
      await UserApi.instance.logout();
    } catch (_) {}
  }
}
