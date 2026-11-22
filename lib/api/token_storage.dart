import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionTokens {
  SessionTokens(this.accessToken, this.refreshToken, {Object? sessionId})
    : sessionId = sessionId ?? Object();

  factory SessionTokens.fromResponse(
    Map<String, dynamic>? response, {
    Object? sessionId,
    bool requiresRefreshToken = false,
  }) {
    final data = response?['data'];
    final accessToken = data is Map ? data['accessToken'] : null;
    final refreshToken = data is Map ? data['refreshToken'] : null;
    if (accessToken is! String ||
        accessToken.isEmpty ||
        (requiresRefreshToken &&
            (refreshToken is! String || refreshToken.isEmpty))) {
      throw const FormatException('인증 응답에 필요한 토큰이 없습니다.');
    }
    return SessionTokens(
      accessToken,
      refreshToken is String && refreshToken.isNotEmpty ? refreshToken : null,
      sessionId: sessionId,
    );
  }

  final String accessToken;
  final String? refreshToken;

  // 토큰 교체는 같은 로그인에 속한다. 새 로그인·로그아웃 후에는 이전 요청을 재시도하지 않는다.
  final Object sessionId;

  bool get isAccessTokenValid {
    try {
      final parts = accessToken.split('.');
      if (parts.length != 3) return false;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final expiry = payload is Map ? payload['exp'] : null;
      return expiry is num &&
          DateTime.now().millisecondsSinceEpoch < expiry * 1000;
    } on FormatException {
      return false;
    }
  }
}

class TokenStorage {
  TokenStorage({bool? useSecureStorage})
    : _useSecureStorage =
          useSecureStorage ??
          (!kIsWeb && (Platform.isAndroid || Platform.isIOS));

  static const _legacyTokenKey = 'auth_token';
  static const _nicknameKey = 'auth_nickname';
  static const _secureStorage = MethodChannel('com.onharu.app/auth_session');

  final bool _useSecureStorage;
  Future<SessionTokens?>? _loaded;
  Future<void> _writes = Future.value();

  Future<SessionTokens?> read() async {
    final pending = _loaded ??= _load();
    try {
      return await pending;
    } catch (_) {
      if (identical(_loaded, pending)) _loaded = null;
      rethrow;
    }
  }

  Future<SessionTokens?> _load() async {
    if (_useSecureStorage) {
      final stored = await _secureStorage.invokeMethod<String>('read');
      if (stored != null) {
        return SessionTokens.fromResponse({'data': jsonDecode(stored)});
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_legacyTokenKey);
    return legacy == null || legacy.isEmpty
        ? null
        : SessionTokens(legacy, null);
  }

  Future<void> saveSession(SessionTokens tokens) =>
      _write(() => _store(tokens));

  Future<bool> replaceIfCurrent(SessionTokens previous, SessionTokens tokens) =>
      _write(() async {
        if (!identical(await read(), previous)) return false;
        await _store(tokens);
        return true;
      });

  Future<void> _store(SessionTokens tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyTokenKey);
    if (_useSecureStorage) {
      await _secureStorage.invokeMethod<void>(
        'write',
        jsonEncode({
          'accessToken': tokens.accessToken,
          'refreshToken': tokens.refreshToken,
        }),
      );
    }
    _loaded = Future.value(tokens);
  }

  Future<void> saveNickname(String nickname, Object sessionId) =>
      _write(() async {
        if ((await read())?.sessionId != sessionId) return;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_nicknameKey, nickname);
      });

  Future<String?> readNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nicknameKey);
  }

  Future<SessionTokens?> clearAll({SessionTokens? ifCurrent}) => _write(
    () async {
      final current = await read();
      if (ifCurrent != null && !identical(ifCurrent, current)) return null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_legacyTokenKey);
      if (_useSecureStorage) await _secureStorage.invokeMethod<void>('delete');
      _loaded = Future.value(null);
      await prefs.remove(_nicknameKey);
      return current;
    },
  );

  Future<T> _write<T>(Future<T> Function() operation) {
    final next = _writes.then((_) => operation());
    _writes = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }
}
