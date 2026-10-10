import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/auth/token_storage.dart';
import 'package:mss301_mobile/core/config/api_config.dart';
import 'package:mss301_mobile/core/config/app_config.dart';
import 'package:mss301_mobile/core/network/api_exception.dart';
import 'package:mss301_mobile/core/network/dio_client.dart';
import 'package:mss301_mobile/features/auth/data/auth_remote_data_source.dart';
import 'package:mss301_mobile/features/auth/data/auth_repository.dart';
import 'package:mss301_mobile/features/auth/data/remote_auth_repository.dart';

void main() {
  for (final operation in _Operation.values) {
    test('${operation.name} sends only its verified Gateway request', () async {
      final adapter = _VerificationAdapter({'success': true});
      final storage = _RecordingTokenStorage();
      final repository = _repository(adapter, storage, mappedClient: true);

      await operation.invoke(repository);

      expect(adapter.requests, hasLength(1));
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, operation.path);
      expect(request.uri.host, 'example.test');
      expect(request.data, operation.body);
      expect(
        (request.data as Map).keys,
        isNot(
          contains(
            anyOf(
              'password',
              'newPassword',
              'confirmPassword',
              'userId',
              'customerId',
              'serviceSecret',
              'authorization',
            ),
          ),
        ),
      );
      expect(
        request.headers.keys.map((key) => key.toLowerCase()),
        isNot(
          contains(
            anyOf(
              'authorization',
              'x-gateway-secret',
              'x-internal-service-secret',
            ),
          ),
        ),
      );
      _expectUnchangedTokens(storage);
      expect(await repository.restoreSession(), isNull);
    });

    for (final envelope in <(String, Map<String, Object?>)>[
      ('omitted data', {'success': true}),
      ('null data', {'success': true, 'data': null}),
    ]) {
      test('${operation.name} accepts success with ${envelope.$1}', () async {
        final storage = _RecordingTokenStorage();
        final repository = _repository(
          _VerificationAdapter(envelope.$2),
          storage,
        );

        await operation.invoke(repository);

        _expectUnchangedTokens(storage);
        expect(await repository.restoreSession(), isNull);
      });
    }

    for (final invalidEnvelope in <(String, Object?)>[
      ('null body', null),
      ('non-object body', []),
      ('malformed object', {'unexpected': true}),
      ('missing success', {'data': null}),
      ('false success', {'success': false}),
      ('non-boolean success', {'success': 'true'}),
    ]) {
      test(
        '${operation.name} rejects ${invalidEnvelope.$1} as recoverable error',
        () async {
          final adapter = _VerificationAdapter(invalidEnvelope.$2);
          final storage = _RecordingTokenStorage();
          final repository = _repository(adapter, storage);

          await expectLater(
            operation.invoke(repository),
            throwsA(
              isA<ApiException>().having(
                (error) => error.type,
                'type',
                ApiErrorType.unknown,
              ),
            ),
          );
          _expectUnchangedTokens(storage);

          adapter.responseBody = {'success': true};
          await operation.invoke(repository);
          _expectUnchangedTokens(storage);
        },
      );
    }

    for (final signedIn in [false, true]) {
      test(
        '${operation.name} does not write or clear ${signedIn ? 'existing' : 'absent'} tokens',
        () async {
          final storage = _RecordingTokenStorage(
            accessToken: signedIn ? 'existing-access' : null,
            refreshToken: signedIn ? 'existing-refresh' : null,
          );
          final repository = _repository(
            _VerificationAdapter({'success': true}),
            storage,
          );

          await operation.invoke(repository);

          _expectUnchangedTokens(storage, signedIn: signedIn);
        },
      );
    }

    test(
      '${operation.name} maps network failure without session mutation',
      () async {
        final storage = _RecordingTokenStorage();
        final repository = _repository(
          _VerificationAdapter(
            null,
            transportErrorType: DioExceptionType.connectionError,
          ),
          storage,
        );

        await expectLater(
          operation.invoke(repository),
          throwsA(
            isA<ApiException>().having(
              (error) => error.type,
              'type',
              ApiErrorType.network,
            ),
          ),
        );
        _expectUnchangedTokens(storage);
      },
    );

    test(
      '${operation.name} preserves an already mapped Dio API error',
      () async {
        const mapped = ApiException(
          type: ApiErrorType.tooManyRequests,
          statusCode: 429,
          backendCode: 'VERIFICATION_LIMIT',
          message: 'Please try again later.',
        );
        final storage = _RecordingTokenStorage();
        final repository = _repository(
          _VerificationAdapter(null, mappedError: mapped),
          storage,
        );

        await expectLater(operation.invoke(repository), throwsA(same(mapped)));
        _expectUnchangedTokens(storage);
      },
    );
  }

  for (final errorCase in <(_Operation, int, ApiErrorType, String)>[
    (_Operation.verify, 400, ApiErrorType.badRequest, 'Invalid OTP'),
    (_Operation.verify, 400, ApiErrorType.badRequest, 'OTP has expired'),
    (_Operation.verify, 409, ApiErrorType.conflict, 'Email already verified'),
    (_Operation.resend, 404, ApiErrorType.notFound, 'Email not found'),
    (_Operation.resend, 429, ApiErrorType.tooManyRequests, 'Too many requests'),
  ]) {
    test(
      '${errorCase.$1.name} preserves HTTP ${errorCase.$2}: ${errorCase.$4}',
      () async {
        final adapter = _VerificationAdapter({
          'success': false,
          'message': errorCase.$4,
          'code': 'VERIFICATION_ERROR',
        }, statusCode: errorCase.$2);
        final storage = _RecordingTokenStorage();
        final repository = _repository(adapter, storage, mappedClient: true);

        await expectLater(
          errorCase.$1.invoke(repository),
          throwsA(
            isA<ApiException>()
                .having((error) => error.type, 'type', errorCase.$3)
                .having((error) => error.statusCode, 'status', errorCase.$2)
                .having((error) => error.message, 'message', errorCase.$4)
                .having(
                  (error) => error.backendCode,
                  'backend code',
                  'VERIFICATION_ERROR',
                ),
          ),
        );
        _expectUnchangedTokens(storage);
      },
    );
  }
}

enum _Operation {
  verify,
  resend;

  String get path => switch (this) {
    verify => '/api/v1/auth/verify-email',
    resend => '/api/v1/auth/verify-email/request',
  };

  Map<String, Object?> get body => switch (this) {
    verify => {'email': 'Customer@Example.com', 'otp': '001234'},
    resend => {'email': 'Customer@Example.com'},
  };

  Future<void> invoke(AuthRepository repository) => switch (this) {
    verify => repository.verifyEmail(
      email: 'Customer@Example.com',
      otp: '001234',
    ),
    resend => repository.resendVerification('Customer@Example.com'),
  };
}

RemoteAuthRepository _repository(
  _VerificationAdapter adapter,
  _RecordingTokenStorage storage, {
  bool mappedClient = false,
}) {
  final dio = mappedClient
      ? createDioClient(
          ApiConfig(
            appConfig: AppConfig(
              environment: AppEnvironment.staging,
              apiBaseUrl: 'https://example.test',
            ),
          ),
        )
      : Dio();
  dio.httpClientAdapter = adapter;
  addTearDown(() => dio.close(force: true));
  return RemoteAuthRepository(AuthRemoteDataSource(dio), storage);
}

void _expectUnchangedTokens(
  _RecordingTokenStorage storage, {
  bool signedIn = false,
}) {
  expect(storage.saveCalls, 0);
  expect(storage.deleteCalls, 0);
  expect(storage.accessToken, signedIn ? 'existing-access' : isNull);
  expect(storage.refreshToken, signedIn ? 'existing-refresh' : isNull);
}

class _VerificationAdapter implements HttpClientAdapter {
  _VerificationAdapter(
    this.responseBody, {
    this.statusCode = 200,
    this.transportErrorType,
    this.mappedError,
  });

  Object? responseBody;
  final int statusCode;
  final DioExceptionType? transportErrorType;
  final ApiException? mappedError;
  final requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (transportErrorType != null || mappedError != null) {
      throw DioException(
        requestOptions: options,
        type: transportErrorType ?? DioExceptionType.unknown,
        error: mappedError,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(responseBody),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _RecordingTokenStorage implements TokenStorage {
  _RecordingTokenStorage({this.accessToken, this.refreshToken});

  String? accessToken;
  String? refreshToken;
  int saveCalls = 0;
  int deleteCalls = 0;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> saveAccessToken(String token) async {
    saveCalls++;
    accessToken = token;
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    saveCalls++;
    refreshToken = token;
  }

  @override
  Future<void> deleteAccessToken() async {
    deleteCalls++;
    accessToken = null;
  }

  @override
  Future<void> deleteRefreshToken() async {
    deleteCalls++;
    refreshToken = null;
  }

  @override
  Future<void> clear() async {
    deleteCalls++;
    accessToken = null;
    refreshToken = null;
  }
}
