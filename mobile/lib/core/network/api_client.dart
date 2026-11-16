import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/token_store.dart';
import 'api_exception.dart';

/// Thin REST client: unwraps the `{ success, data }` envelope, attaches the
/// bearer token and language, and rotates the refresh token once on 401.
class ApiClient {
  ApiClient({required this._dio, required this.tokens, required this.localeCode, this.onSessionExpired}) {
    _dio.interceptors.add(InterceptorsWrapper(onRequest: _onRequest));
  }

  final Dio _dio;
  final TokenStore tokens;
  final String Function() localeCode;
  final void Function()? onSessionExpired;
  Completer<bool>? _refreshing;

  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    options.headers['accept-language'] = localeCode();
    final current = await tokens.read();
    if (current != null && options.extra['auth'] != false) {
      options.headers['authorization'] = 'Bearer ${current.accessToken}';
    }
    handler.next(options);
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _send<T>(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<T> post<T>(String path, {Object? body, Map<String, String>? headers, bool auth = true}) => _send<T>(
    () => _dio.post<dynamic>(
      path,
      data: body ?? {},
      options: Options(headers: headers, extra: {'auth': auth}),
    ),
  );

  Future<T> patch<T>(String path, {Object? body}) => _send<T>(() => _dio.patch<dynamic>(path, data: body));

  Future<T> delete<T>(String path) => _send<T>(() => _dio.delete<dynamic>(path));

  /// Downloads raw bytes (reports, exports).
  Future<List<int>> download(String path) async {
    try {
      final res = await _withRefresh(
        () => _dio.get<List<int>>(path, options: Options(responseType: ResponseType.bytes)),
      );
      return res.data ?? const [];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<T> _send<T>(Future<Response<dynamic>> Function() call) async {
    try {
      final res = await _withRefresh(call);
      final body = res.data;
      return (body is Map ? body['data'] : body) as T;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Response<R>> _withRefresh<R>(Future<Response<R>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final isAuthCall = e.requestOptions.path.startsWith('/auth/');
      if (e.response?.statusCode != 401 || isAuthCall) rethrow;
      if (!await _refresh()) rethrow;
      return call();
    }
  }

  /// Single-flight refresh: concurrent 401s wait for the same rotation.
  Future<bool> _refresh() async {
    if (_refreshing != null) return _refreshing!.future;
    final completer = _refreshing = Completer<bool>();
    try {
      final current = await tokens.read();
      if (current == null) throw StateError('no session');
      final res = await _dio.post<dynamic>(
        '/auth/refresh',
        data: {'refreshToken': current.refreshToken},
        options: Options(extra: {'auth': false}),
      );
      await tokens.write(Tokens.fromJson((res.data as Map)['data'] as Map<String, dynamic>));
      completer.complete(true);
    } catch (e) {
      final networkFailure = e is DioException && e.response == null;
      // Only a definitive rejection ends the session; offline keeps it (and pending data).
      if (!networkFailure) {
        await tokens.clear();
        onSessionExpired?.call();
      }
      completer.complete(false);
    } finally {
      _refreshing = null;
    }
    return completer.future;
  }
}
