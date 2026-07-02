import 'api_client.dart';
import 'api_config.dart';

/// PUT  /api/v1/members/me/password — 비밀번호 변경
/// DELETE /api/v1/members/me       — 회원 탈퇴
class MemberApi {
  MemberApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.dio.put(
      '${ApiConfig.apiPrefix}/members/me/password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> deleteAccount() async {
    await _client.dio.delete('${ApiConfig.apiPrefix}/members/me');
    await _client.tokenStorage.clearAll();
  }
}
