import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/auth/token_storage.dart';
import 'package:mss301_mobile/core/config/api_config.dart';
import 'package:mss301_mobile/core/config/app_config.dart';
import 'package:mss301_mobile/core/network/dio_client.dart';
import 'package:mss301_mobile/features/auth/application/auth_session.dart';
import 'package:mss301_mobile/features/auth/data/auth_models.dart';
import 'package:mss301_mobile/features/auth/data/auth_remote_data_source.dart';
import 'package:mss301_mobile/features/auth/data/remote_auth_repository.dart';

import 'support/fake_auth_session.dart';

void main() {
  test(
    'register returns the typed 90-second receipt without creating a session',
    () async {
      final fixture = _SessionFixture();
      fixture.adapter.responseBody = {
        'success': true,
        'data': {
          'user': {
            'id': null,
            'email': _email,
            'fullName': 'Nguyen Van A',
            'status': 'PENDING_VERIFICATION',
            'roles': ['CUSTOMER'],
          },
          'emailVerificationRequired': true,
          'emailVerificationExpiresInSeconds': 90,
        },
      };

      final result = await fixture.controller.register(
        email: _email,
        password: ' Password@123 ',
        fullName: ' Nguyen Van A ',
        phone: '0901234567',
        birthYear: 2000,
        username: 'nguyenvana',
        identityNumber: '012345678901',
      );

      expect(result, isA<RegistrationResult>());
      expect(result!.user.id, isNull);
      expect(result.user.email, _email);
      expect(result.emailVerificationRequired, isTrue);
      expect(result.emailVerificationExpiresInSeconds, 90);
      expect(fixture.adapter.requests, hasLength(1));
      final request = fixture.adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/api/v1/auth/register');
      expect(request.data, {
        'email': _email,
        'password': ' Password@123 ',
        'fullName': ' Nguyen Van A ',
        'phone': '0901234567',
        'birthYear': 2000,
        'username': 'nguyenvana',
        'identityNumber': '012345678901',
      });
      fixture.expectUnauthenticated();
      fixture.expectTokensUnchanged();
    },
  );

  test(
    'registration failure returns null and exposes a recoverable error',
    () async {
      final fixture = _SessionFixture();
      fixture.adapter.fail(409, 'Email already exists');

      final result = await fixture.controller.register(
        email: _email,
        password: 'Password@123',
        fullName: 'Nguyen Van A',
      );

      expect(result, isNull);
      expect(fixture.state.message, contains('Email already exists'));
      fixture.expectUnauthenticated();
      fixture.expectTokensUnchanged();
    },
  );

  test('invalid verification exposes only the Backend message without authentication', () async {
    final fixture = _SessionFixture();
    fixture.adapter.fail(400, 'Mã OTP không hợp lệ.');

    final verified = await fixture.verify();

    expect(verified, isFalse);
    expect(fixture.state.message, 'Mã OTP không hợp lệ.');
    expect(fixture.state.message, isNot(contains('ApiException')));
    expect(fixture.adapter.requests.single.path, '/api/v1/auth/verify-email');
    fixture.expectUnauthenticated();
    fixture.expectTokensUnchanged();
  });

  test(
    'verify retry clears the stale error before the pending request completes',
    () async {
      final fixture = _SessionFixture();
      fixture.adapter.fail(400, 'OTP has expired');
      expect(await fixture.verify(), isFalse);
      expect(fixture.state.message, 'OTP has expired');
      fixture.adapter.succeed();
      final pending = Completer<void>();
      fixture.adapter.pendingResponse = pending.future;

      final retry = fixture.verify();

      expect(fixture.state.message, isNull);
      fixture.expectUnauthenticated();
      pending.complete();
      expect(await retry, isTrue);
      expect(fixture.adapter.requests, hasLength(2));
      expect(fixture.state.message, isNull);
      fixture.expectUnauthenticated();
      fixture.expectTokensUnchanged();
    },
  );

  test(
    'successful resend clears a previous verify error and keeps the same email',
    () async {
      final fixture = _SessionFixture();
      fixture.adapter.fail(400, 'Invalid OTP');
      expect(await fixture.verify(), isFalse);
      expect(fixture.state.message, 'Invalid OTP');
      fixture.adapter.succeed();

      final resent = await fixture.controller.resendVerification(_email);

      expect(resent, isTrue);
      expect(fixture.state.message, isNull);
      expect(fixture.adapter.requests, hasLength(2));
      expect(fixture.adapter.requests.first.data, {
        'email': _email,
        'otp': '001234',
      });
      expect(
        fixture.adapter.requests.last.path,
        '/api/v1/auth/verify-email/request',
      );
      expect(fixture.adapter.requests.last.data, {'email': _email});
      fixture.expectUnauthenticated();
      fixture.expectTokensUnchanged();
    },
  );

  for (final failure in [
    (404, 'Email not found'),
    (429, 'Too many verification requests'),
  ]) {
    test(
      'resend HTTP ${failure.$1} is recoverable and does not mutate session',
      () async {
        final fixture = _SessionFixture();
        fixture.adapter.fail(failure.$1, failure.$2);

        expect(await fixture.controller.resendVerification(_email), isFalse);
        expect(fixture.state.message, failure.$2);
        fixture.expectUnauthenticated();
        fixture.expectTokensUnchanged();

        fixture.adapter.succeed();
        expect(await fixture.controller.resendVerification(_email), isTrue);
        expect(fixture.state.message, isNull);
        expect(fixture.adapter.requests, hasLength(2));
        fixture.expectUnauthenticated();
        fixture.expectTokensUnchanged();
      },
    );
  }

  for (final operation in _Operation.values) {
    test(
      '${operation.name} accepts void success without auto-login or token writes',
      () async {
        final fixture = _SessionFixture();

        expect(await operation.invoke(fixture.controller), isTrue);

        expect(fixture.adapter.requests, hasLength(1));
        expect(fixture.state.message, isNull);
        expect(
          fixture.adapter.requests.single.path,
          isNot('/api/v1/auth/login'),
        );
        fixture.expectUnauthenticated();
        fixture.expectTokensUnchanged();
      },
    );

    for (final successful in [true, false]) {
      test(
        '${operation.name} ${successful ? 'success' : 'failure'} preserves an existing authenticated state',
        () async {
          final initialState = authenticatedCustomerState();
          final fixture = _SessionFixture(initialState: initialState);
          if (!successful) fixture.adapter.fail(400, 'Verification failed');

          expect(await operation.invoke(fixture.controller), successful);

          expect(fixture.state.status, AuthStatus.authenticated);
          expect(fixture.state.session, same(initialState.session));
          expect(fixture.state.isAuthenticated, isTrue);
          expect(
            fixture.state.message,
            successful ? isNull : 'Verification failed',
          );
          expect(fixture.adapter.requests, hasLength(1));
          fixture.expectTokensUnchanged();
        },
      );
    }
  }

  for (final signedIn in [false, true]) {
    test(
      'clearVerificationMessage preserves ${signedIn ? 'authenticated' : 'unauthenticated'} state',
      () async {
        final initialState = signedIn
            ? authenticatedCustomerState()
            : unauthenticatedState;
        final fixture = _SessionFixture(initialState: initialState);
        fixture.adapter.fail(400, 'Expired OTP');
        expect(await fixture.verify(), isFalse);
        expect(fixture.state.message, 'Expired OTP');

        fixture.controller.clearVerificationMessage();

        expect(fixture.state.message, isNull);
        expect(fixture.state.status, initialState.status);
        expect(fixture.state.session, same(initialState.session));
        expect(fixture.adapter.requests, hasLength(1));
        fixture.expectTokensUnchanged();
      },
    );
  }
}

const _email = 'Customer@Example.com';

enum _Operation {
  verify,
  resend;

  Future<bool> invoke(AuthSessionController controller) => switch (this) {
    verify => controller.verifyEmail(email: _email, otp: '001234'),
    resend => controller.resendVerification(_email),
  };
}

class _SessionFixture {
  _SessionFixture({this.initialState = unauthenticatedState}) {
    storage = _RecordingTokenStorage(
      accessToken: initialState.session?.accessToken,
      refreshToken: initialState.session?.refreshToken,
    );
    final dio = createDioClient(
      ApiConfig(
        appConfig: AppConfig(
          environment: AppEnvironment.staging,
          apiBaseUrl: 'https://example.test',
        ),
      ),
    )..httpClientAdapter = adapter;
    final repository = RemoteAuthRepository(AuthRemoteDataSource(dio), storage);
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        authSessionProvider.overrideWith(
          () => FakeAuthSessionController(initialState),
        ),
      ],
    );
    controller = container.read(authSessionProvider.notifier);
    addTearDown(() {
      container.dispose();
      dio.close(force: true);
    });
  }

  final AuthState initialState;
  final adapter = _SessionAdapter();
  late final _RecordingTokenStorage storage;
  late final ProviderContainer container;
  late final AuthSessionController controller;

  AuthState get state => container.read(authSessionProvider);

  Future<bool> verify() => controller.verifyEmail(email: _email, otp: '001234');

  void expectUnauthenticated() {
    expect(state.status, AuthStatus.unauthenticated);
    expect(state.session, isNull);
    expect(state.isAuthenticated, isFalse);
  }

  void expectTokensUnchanged() {
    expect(storage.saveCalls, 0);
    expect(storage.deleteCalls, 0);
    expect(storage.accessToken, initialState.session?.accessToken);
    expect(storage.refreshToken, initialState.session?.refreshToken);
  }
}

class _SessionAdapter implements HttpClientAdapter {
  Object? responseBody = {'success': true};
  int statusCode = 200;
  Future<void>? pendingResponse;
  final requests = <RequestOptions>[];

  void fail(int status, String message) {
    statusCode = status;
    responseBody = {'success': false, 'message': message};
  }

  void succeed() {
    statusCode = 200;
    responseBody = {'success': true};
  }

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    await pendingResponse;
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
