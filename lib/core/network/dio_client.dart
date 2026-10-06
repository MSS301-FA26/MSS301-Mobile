import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'error_mapper.dart';
import 'network_logger.dart';

Dio createDioClient(ApiConfig config, {ApiErrorMapper? errorMapper}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.connectTimeout,
      sendTimeout: config.sendTimeout,
      receiveTimeout: config.receiveTimeout,
      headers: config.defaultHeaders,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );
  if (config.networkLoggingEnabled) {
    dio.interceptors.add(RedactedNetworkLogger());
  }
  dio.interceptors.add(
    _ErrorMappingInterceptor(errorMapper ?? ApiErrorMapper()),
  );
  return dio;
}

class _ErrorMappingInterceptor extends Interceptor {
  _ErrorMappingInterceptor(this.mapper);
  final ApiErrorMapper mapper;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: mapper.fromDioException(err),
        message: mapper.fromDioException(err).message,
      ),
    );
  }
}
