import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_gateway_config.dart';

class ApiGatewayUnauthorizedException implements Exception {
  const ApiGatewayUnauthorizedException();

  @override
  String toString() => 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
}

final apiGatewayDioProvider = Provider<Dio>((ref) {
  final config = ref.watch(apiGatewayConfigProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      responseType: ResponseType.json,
      headers: const {
        Headers.acceptHeader: 'application/json',
        Headers.contentTypeHeader: 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: DioExceptionType.badResponse,
              error: const ApiGatewayUnauthorizedException(),
            ),
          );
          return;
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});
