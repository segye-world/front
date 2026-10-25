import 'package:shared_preferences/shared_preferences.dart';

// api/token_storage.dart 와 같은 키를 쓴다. 두 클래스를 하나로 합치는 것은 호출 방식 통일(P2)에서 다룬다.
class TokenStorage {
  static const _key = 'auth_token';
  static const _nicknameKey = 'auth_nickname';

  static Future<void> save(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_nicknameKey);
  }

  static Future<String?> loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nicknameKey);
  }
}
