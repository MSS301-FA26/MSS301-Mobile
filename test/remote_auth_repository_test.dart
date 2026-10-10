import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/auth/token_storage.dart';
import 'package:mss301_mobile/core/config/api_config.dart';
import 'package:mss301_mobile/core/config/app_config.dart';
import 'package:mss301_mobile/core/network/api_exception.dart';
import 'package:mss301_mobile/core/network/dio_client.dart';
import 'package:mss301_mobile/features/auth/data/auth_models.dart';
import 'package:mss301_mobile/features/auth/data/auth_remote_data_source.dart';
import 'package:mss301_mobile/features/auth/data/auth_repository.dart';
import 'package:mss301_mobile/features/auth/data/remote_auth_repository.dart';

void main() {
  test('register forwards seven useful fields unchanged and omits cinema preference through Gateway', () async {
    final adapter = _RegistrationAdapter(_registrationEnvelope());
    final storage = _RecordingTokenStorage();
    final AuthRepository repository = RemoteAuthRepository(
      AuthRemoteDataSource(Dio()..httpClientAdapter = adapter),
      storage,
    );

    await repository.register(
      email: ' Customer@Example.com ',
      password: ' Password@123 ',
      fullName: ' Nguyen Van A ',
      phone: '+84901234567',
      birthYear: 2000,
      username: 'nguyenvana',
      identityNumber: '012345678901',
    );

    expect(adapter.method, 'POST');
    expect(adapter.path, '/api/v1/auth/register');
    expect(adapter.data, {
      'email': ' Customer@Example.com ',
      'password': ' Password@123 ',
      'fullName': ' Nguyen Van A ',
      'phone': '+84901234567',
      'birthYear': 2000,
      'username': 'nguyenvana',
      'identityNumber': '012345678901',
    });
    expect(adapter.data!['birthYear'], isA<int>());
    expect(adapter.data!['identityNumber'], isA<String>());
    expect(
      adapter.data!.keys,
      isNot(
        contains(
          anyOf('preferredCinemaId', 'favoriteCinemaId', 'favoriteCinema'),
        ),
      ),
    );
    expect(
      adapter.headers.keys.map((header) => header.toLowerCase()),
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
  });

  test(
    'register keeps the minimum three fields and nullable optionals',
    () async {
      final adapter = _RegistrationAdapter(_registrationEnvelope());
      final repository = RemoteAuthRepository(
        AuthRemoteDataSource(Dio()..httpClientAdapter = adapter),
        _RecordingTokenStorage(),
      );

      await repository.register(
        email: 'customer@example.com',
        password: 'Password@123',
        fullName: 'Nguyen Van A',
      );

      expect(adapter.data, {
        'email': 'customer@example.com',
        'password': 'Password@123',
        'fullName': 'Nguyen Van A',
        'phone': null,
        'birthYear': null,
        'username': null,
        'identityNumber': null,
      });
      expect(adapter.data!.containsKey('preferredCinemaId'), isFalse);
    },
  );

  test(
    'register preserves supplied optional text without normalization',
    () async {
      final adapter = _RegistrationAdapter(_registrationEnvelope());
      final repository = RemoteAuthRepository(
        AuthRemoteDataSource(Dio()..httpClientAdapter = adapter),
        _RecordingTokenStorage(),
      );

      await repository.register(
        email: 'customer@example.com',
        password: 'Password@123',
        fullName: 'Nguyen Van A',
        phone: '',
        username: ' user name ',
        identityNumber: ' 012345678901 ',
      );

      expect(adapter.data!['phone'], '');
      expect(adapter.data!['username'], ' user name ');
      expect(adapter.data!['identityNumber'], ' 012345678901 ');
    },
  );

  test(
    'register parses a pending profile with null id and 90 second OTP',
    () async {
      final repository = RemoteAuthRepository(
        AuthRemoteDataSource(
          Dio()
            ..httpClientAdapter = _RegistrationAdapter(_registrationEnvelope()),
        ),
        _RecordingTokenStorage(),
      );

      final result = await _registerMinimum(repository);

      expect(result.user, isA<RegistrationProfile>());
      expect(result.user.id, isNull);
      expect(result.user.email, 'customer@example.com');
      expect(result.user.fullName, 'Nguyen Van A');
      expect(result.user.username, 'nguyenvana');
      expect(result.user.birthYear, 2000);
      expect(result.user.preferredCinemaId, isNull);
      expect(result.user.status, 'PENDING_VERIFICATION');
      expect(result.user.emailVerified, isFalse);
      expect(result.user.roles, ['CUSTOMER']);
      expect(result.emailVerificationRequired, isTrue);
      expect(result.emailVerificationExpiresInSeconds, 90);
    },
  );

  test(
    'registration does not create or replace authentication tokens',
    () async {
      for (final signedIn in [false, true]) {
        final storage = _RecordingTokenStorage(
          accessToken: signedIn ? 'existing-access' : null,
          refreshToken: signedIn ? 'existing-refresh' : null,
        );
        final repository = RemoteAuthRepository(
          AuthRemoteDataSource(
            Dio()
              ..httpClientAdapter = _RegistrationAdapter(
                _registrationEnvelope(),
              ),
          ),
          storage,
        );

        final result = await _registerMinimum(repository);

        expect(result, isNot(isA<AuthSession>()));
        expect(storage.saveCalls, 0);
        expect(storage.deleteCalls, 0);
        expect(storage.accessToken, signedIn ? 'existing-access' : isNull);
        expect(storage.refreshToken, signedIn ? 'existing-refresh' : isNull);
      }
    },
  );

  for (final errorCase in [
    (409, ApiErrorType.conflict, 'Identity number already exists'),
    (400, ApiErrorType.badRequest, 'Dữ liệu không hợp lệ'),
  ]) {
    test('registration preserves mapped HTTP ${errorCase.$1} errors', () async {
      final adapter = _RegistrationAdapter({
        'success': false,
        'message': errorCase.$3,
        'path': '/api/v1/auth/register',
        'errors': errorCase.$1 == 400
            ? [
                {
                  'field': 'username',
                  'message': 'Username must not contain whitespace',
                },
              ]
            : [],
      }, statusCode: errorCase.$1);
      final repository = RemoteAuthRepository(
        AuthRemoteDataSource(_mappedDio(adapter)),
        _RecordingTokenStorage(),
      );

      await expectLater(
        _registerMinimum(repository),
        throwsA(
          isA<ApiException>()
              .having((error) => error.type, 'type', errorCase.$2)
              .having((error) => error.statusCode, 'status', errorCase.$1)
              .having((error) => error.message, 'message', errorCase.$3),
        ),
      );
    });
  }

  final invalidBodies = <(String, Object?)>[
    ('non-object body', []),
    ('missing success', {'data': _pendingRegistrationData}),
    ('false success', {'success': false, 'data': _pendingRegistrationData}),
    ('string success', {'success': 'true', 'data': _pendingRegistrationData}),
    ('missing data', {'success': true}),
    ('null data', {'success': true, 'data': null}),
    ('non-object data', {'success': true, 'data': []}),
    (
      'missing user',
      _registrationEnvelope(
        data: {
          'emailVerificationRequired': true,
          'emailVerificationExpiresInSeconds': 90,
        },
      ),
    ),
    (
      'null user',
      _registrationEnvelope(data: {..._pendingRegistrationData, 'user': null}),
    ),
    (
      'non-object user',
      _registrationEnvelope(data: {..._pendingRegistrationData, 'user': []}),
    ),
    (
      'string profile id',
      _registrationEnvelope(
        data: {
          ..._pendingRegistrationData,
          'user': {..._pendingProfile, 'id': '12'},
        },
      ),
    ),
    (
      'null profile email',
      _registrationEnvelope(
        data: {
          ..._pendingRegistrationData,
          'user': {..._pendingProfile, 'email': null},
        },
      ),
    ),
    (
      'non-string profile name',
      _registrationEnvelope(
        data: {
          ..._pendingRegistrationData,
          'user': {..._pendingProfile, 'fullName': 12},
        },
      ),
    ),
    (
      'invalid verification flag',
      _registrationEnvelope(
        data: {
          ..._pendingRegistrationData,
          'emailVerificationRequired': 'true',
        },
      ),
    ),
    (
      'missing verification flag',
      _registrationEnvelope(
        data: {
          'user': _pendingProfile,
          'emailVerificationExpiresInSeconds': 90,
        },
      ),
    ),
    (
      'string expiry',
      _registrationEnvelope(
        data: {
          ..._pendingRegistrationData,
          'emailVerificationExpiresInSeconds': '90',
        },
      ),
    ),
    (
      'fractional expiry',
      _registrationEnvelope(
        data: {
          ..._pendingRegistrationData,
          'emailVerificationExpiresInSeconds': 90.5,
        },
      ),
    ),
    (
      'missing expiry',
      _registrationEnvelope(
        data: {'user': _pendingProfile, 'emailVerificationRequired': true},
      ),
    ),
  ];
  for (final invalidBody in invalidBodies) {
    test('rejects ${invalidBody.$1} as a recoverable API error', () async {
      final adapter = _RegistrationAdapter(invalidBody.$2);
      final storage = _RecordingTokenStorage();
      final repository = RemoteAuthRepository(
        AuthRemoteDataSource(Dio()..httpClientAdapter = adapter),
        storage,
      );

      await expectLater(
        _registerMinimum(repository),
        throwsA(
          isA<ApiException>().having(
            (error) => error.type,
            'type',
            ApiErrorType.unknown,
          ),
        ),
      );
      expect(storage.saveCalls, 0);
      adapter.responseBody = _registrationEnvelope();
      expect((await _registerMinimum(repository)).user.id, isNull);
    });
  }
}

Future<RegistrationResult> _registerMinimum(AuthRepository repository) =>
    repository.register(
      email: 'customer@example.com',
      password: 'Password@123',
      fullName: 'Nguyen Van A',
    );

Dio _mappedDio(HttpClientAdapter adapter) => createDioClient(
  ApiConfig(
    appConfig: AppConfig(
      environment: AppEnvironment.staging,
      apiBaseUrl: 'https://example.test',
    ),
  ),
)..httpClientAdapter = adapter;

Map<String, Object?> _registrationEnvelope({
  Map<String, Object?> data = _pendingRegistrationData,
}) => {'success': true, 'data': data};

const _pendingRegistrationData = {
  'user': _pendingProfile,
  'emailVerificationRequired': true,
  'emailVerificationExpiresInSeconds': 90,
};

const _pendingProfile = {
  'id': null,
  'email': 'customer@example.com',
  'username': 'nguyenvana',
  'fullName': 'Nguyen Van A',
  'phone': '0901234567',
  'avatarUrl': null,
  'birthYear': 2000,
  'preferredCinemaId': null,
  'status': 'PENDING_VERIFICATION',
  'emailVerified': false,
  'phoneVerified': false,
  'roles': ['CUSTOMER'],
  'cinemaId': null,
  'createdAt': '2026-10-10T15:00:00',
  'updatedAt': '2026-10-10T15:00:00',
};

class _RegistrationAdapter implements HttpClientAdapter {
  _RegistrationAdapter(this.responseBody, {this.statusCode = 201});

  Object? responseBody;
  final int statusCode;
  String? method;
  String? path;
  Map<String, Object?>? data;
  Map<String, dynamic> headers = {};

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    method = options.method;
    path = options.path;
    data = options.data is Map
        ? Map<String, Object?>.from(options.data as Map)
        : null;
    headers = Map<String, dynamic>.from(options.headers);
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
