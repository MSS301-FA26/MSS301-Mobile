import 'package:dio/dio.dart';

import '../auth/token_storage.dart';
import '../../features/auth/data/auth_remote_data_source.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.storage,
    required this.refreshClient,
    required this.retryClient,
    required this.onRefreshFailure,
  });
  final TokenStorage storage;
  final AuthRemoteDataSource refreshClient;
  final Dio retryClient;
  final Future<void> Function() onRefreshFailure;
  Future<String?>? _refreshing;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401 ||
        err.requestOptions.extra['skipAuthRefresh'] == true) {
      handler.next(err);
      return;
    }
    try {
      _refreshing ??= _refreshAccessToken();
      final token = await _refreshing;
      _refreshing = null;
      if (token == null) throw StateError('Refresh failed');
      final request = err.requestOptions;
      request.extra['skipAuthRefresh'] = true;
      request.headers['Authorization'] = 'Bearer $token';
      final response = await retryClient.fetch(request);
      handler.resolve(response);
    } catch (_) {
      _refreshing = null;
      await onRefreshFailure();
      handler.next(err);
    }
  }

  Future<String?> _refreshAccessToken() async {
    final refresh = await storage.getRefreshToken();
    if (refresh == null) return null;
    final session = await refreshClient.refresh(refresh);
    await storage.saveAccessToken(session.accessToken);
    await storage.saveRefreshToken(session.refreshToken);
    return session.accessToken;
  }
}
