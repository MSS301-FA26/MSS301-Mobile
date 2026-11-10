import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_storage.dart';
import '../config/api_config.dart';
import '../config/app_config.dart';
import '../../features/auth/data/auth_remote_data_source.dart';
import 'auth_interceptor.dart';
import 'dio_client.dart';

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromDartDefines(),
);

final apiConfigProvider = Provider<ApiConfig>(
  (ref) => ApiConfig(appConfig: ref.watch(appConfigProvider)),
);

final secureTokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(),
);

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(apiConfigProvider);
  final dio = createDioClient(config);
  final refreshDio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.connectTimeout,
      sendTimeout: config.sendTimeout,
      receiveTimeout: config.receiveTimeout,
      headers: config.defaultHeaders,
    ),
  );
  final storage = ref.watch(secureTokenStorageProvider);
  dio.interceptors.add(
    AuthInterceptor(
      storage: storage,
      refreshClient: AuthRemoteDataSource(refreshDio),
      retryClient: dio,
      onRefreshFailure: storage.clear,
    ),
  );
  return dio;
});
