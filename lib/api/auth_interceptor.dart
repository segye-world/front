import 'package:dio/dio.dart';

import 'api_config.dart';
import 'token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio, this._storage, this._onSessionExpired);

  static const _sessionKey = 'authSession';
  static const _retriedKey = 'authRetried';
  static const _authPath = '${ApiConfig.apiPrefix}/auth';

  final Dio _dio;
  final TokenStorage _storage;
  final void Function() _onSessionExpired;
  final _refreshing = <Object, Future<SessionTokens?>>{};

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isAuthPath(options.path)) {
      handler.next(options);
      return;
    }

    try {
      final current = await _storage.read();
      final sent = options.extra[_sessionKey] as SessionTokens?;
      if (options.extra[_retriedKey] == true &&
          current?.sessionId != sent?.sessionId) {
        handler.reject(
          DioException(requestOptions: options, type: DioExceptionType.cancel),
        );
        return;
      }
      if (current != null) {
        options.headers['Authorization'] = 'Bearer ${current.accessToken}';
        options.extra[_sessionKey] = current;
      }
      handler.next(options);
    } catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final sent = request.extra[_sessionKey] as SessionTokens?;
    if (err.response?.statusCode != 401 ||
        sent == null ||
        _isAuthPath(request.path)) {
      handler.next(err);
      return;
    }

    try {
      if (request.extra[_retriedKey] == true) {
        await _invalidate(sent, notify: true);
        handler.next(err);
        return;
      }
      final current = await refresh(sent);
      if (current == null) {
        handler.next(err);
        return;
      }
      final response = await _dio.fetch<dynamic>(
        request.copyWith(
          extra: {...request.extra, _sessionKey: current, _retriedKey: true},
        ),
      );
      handler.resolve(response);
    } on DioException catch (nextError) {
      handler.next(nextError);
    } catch (nextError, stackTrace) {
      handler.next(
        DioException(
          requestOptions: request,
          error: nextError,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<SessionTokens?> refresh(
    SessionTokens rejected, {
    bool notify = true,
  }) async {
    final current = await _storage.read();
    if (current == null || current.sessionId != rejected.sessionId) return null;
    if (!identical(current, rejected)) return current;

    final pending = _refreshing.putIfAbsent(
      current.sessionId,
      () => _rotate(current, notify: notify),
    );
    try {
      return await pending;
    } finally {
      if (identical(_refreshing[current.sessionId], pending)) {
        _refreshing.remove(current.sessionId);
      }
    }
  }

  Future<SessionTokens?> _rotate(
    SessionTokens current, {
    required bool notify,
  }) async {
    final refreshToken = current.refreshToken;
    if (refreshToken == null) {
      await _invalidate(current, notify: notify);
      return null;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_authPath/refresh',
        data: {'refreshToken': refreshToken},
      );
      final next = SessionTokens.fromResponse(
        response.data,
        sessionId: current.sessionId,
        requiresRefreshToken: true,
      );
      return await _storage.replaceIfCurrent(current, next) ? next : null;
    } on DioException catch (error) {
      if (error.response?.statusCode != 401) rethrow;
      await _invalidate(current, notify: notify);
      return null;
    }
  }

  Future<void> _invalidate(
    SessionTokens current, {
    required bool notify,
  }) async {
    final removed = await _storage.clearAll(ifCurrent: current);
    if (removed != null && notify && await _storage.read() == null) {
      _onSessionExpired();
    }
  }

  bool _isAuthPath(String path) =>
      Uri.parse(path).path.startsWith('$_authPath/');
}
