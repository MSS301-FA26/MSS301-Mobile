import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/config/app_config.dart';
import 'package:mss301_mobile/core/network/api_exception.dart';
import 'package:mss301_mobile/core/network/error_mapper.dart';
import 'package:mss301_mobile/core/network/network_providers.dart';
import 'package:mss301_mobile/core/network/network_logger.dart';

void main() {
  group('AppConfig', () {
    test('reads and validates dart-define values', () {
      final config = AppConfig(
        environment: AppEnvironment.staging,
        apiBaseUrl: 'https://staging.example.test',
      );

      expect(config.isStaging, isTrue);
      expect(config.isDevelopment, isFalse);
      expect(config.apiBaseUrl, 'https://staging.example.test');
    });

    test('rejects unsupported or empty API URLs', () {
      expect(
        () =>
            AppConfig(environment: AppEnvironment.development, apiBaseUrl: ''),
        throwsArgumentError,
      );
      expect(
        () => AppConfig(
          environment: AppEnvironment.development,
          apiBaseUrl: 'ftp://example.test',
        ),
        throwsArgumentError,
      );
    });
  });

  group('ApiErrorMapper', () {
    final mapper = ApiErrorMapper();

    test('maps HTTP status classes', () {
      expect(mapper.fromResponse(_response(400)).type, ApiErrorType.badRequest);
      expect(
        mapper.fromResponse(_response(401)).type,
        ApiErrorType.unauthorized,
      );
      expect(mapper.fromResponse(_response(403)).type, ApiErrorType.forbidden);
      expect(mapper.fromResponse(_response(404)).type, ApiErrorType.notFound);
      expect(mapper.fromResponse(_response(409)).type, ApiErrorType.conflict);
      expect(mapper.fromResponse(_response(422)).type, ApiErrorType.validation);
      expect(
        mapper.fromResponse(_response(429)).type,
        ApiErrorType.tooManyRequests,
      );
      expect(mapper.fromResponse(_response(503)).type, ApiErrorType.server);
    });

    test('maps Dio transport failures', () {
      expect(
        mapper
            .fromDioException(_dioError(DioExceptionType.connectionTimeout))
            .type,
        ApiErrorType.timeout,
      );
      expect(
        mapper
            .fromDioException(_dioError(DioExceptionType.receiveTimeout))
            .type,
        ApiErrorType.timeout,
      );
      expect(
        mapper
            .fromDioException(_dioError(DioExceptionType.connectionError))
            .type,
        ApiErrorType.network,
      );
      expect(
        mapper.fromDioException(_dioError(DioExceptionType.cancel)).type,
        ApiErrorType.cancelled,
      );
    });

    test('parses backend error fields without requiring a fixed envelope', () {
      final exception = mapper.fromResponse(
        _response(
          422,
          data: {
            'code': 'VALIDATION_ERROR',
            'message': 'Invalid request',
            'errors': {
              'email': ['Email is invalid'],
            },
          },
        ),
      );

      expect(exception.backendCode, 'VALIDATION_ERROR');
      expect(exception.message, 'Invalid request');
      expect(
        exception.validationErrors,
        containsPair('email', ['Email is invalid']),
      );
    });
  });

  test(
    'network providers compose AppConfig → ApiConfig → Dio and are overridable',
    () {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig(
              environment: AppEnvironment.development,
              apiBaseUrl: 'http://10.0.2.2:8080',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final apiConfig = container.read(apiConfigProvider);
      final dio = container.read(dioProvider);

      expect(apiConfig.baseUrl, 'http://10.0.2.2:8080');
      expect(dio.options.baseUrl, apiConfig.baseUrl);
      expect(dio.options.connectTimeout, apiConfig.connectTimeout);
      expect(dio.options.receiveTimeout, apiConfig.receiveTimeout);
    },
  );

  test('redacts sensitive nested fields', () {
    final redacted = RedactedNetworkLogger.redact({
      'Authorization': 'Bearer secret-token',
      'nested': {'password': 'secret', 'safe': 'visible'},
      'items': [
        {'refreshToken': 'refresh-secret'},
      ],
    });

    expect(redacted['Authorization'], '[REDACTED]');
    expect(redacted['nested']['password'], '[REDACTED]');
    expect(redacted['nested']['safe'], 'visible');
    expect(redacted['items'][0]['refreshToken'], '[REDACTED]');
  });
}

Response<dynamic> _response(int status, {Object? data}) => Response<dynamic>(
  requestOptions: RequestOptions(path: '/test'),
  statusCode: status,
  data: data,
);

DioException _dioError(DioExceptionType type) => DioException(
  requestOptions: RequestOptions(path: '/test'),
  type: type,
);
