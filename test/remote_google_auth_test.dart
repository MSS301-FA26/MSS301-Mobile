import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/auth/token_storage.dart';
import 'package:mss301_mobile/core/network/api_exception.dart';
import 'package:mss301_mobile/core/network/auth_interceptor.dart';
import 'package:mss301_mobile/features/auth/data/auth_remote_data_source.dart';
import 'package:mss301_mobile/features/auth/data/remote_auth_repository.dart';

void main() {
  test('Google exchange omits an expired app bearer and never refreshes/retries credential rejection', () async {
    final adapter = _Adapter({
      'success': false,
      'message': 'Invalid credential',
    }, status: 401);
    final storage = _Storage()
      ..access = 'expired-access'
      ..refresh = 'old-refresh';
    final dio = Dio()..httpClientAdapter = adapter;
    var refreshFailures = 0;
    dio.interceptors.add(
      AuthInterceptor(
        storage: storage,
        refreshClient: AuthRemoteDataSource(dio),
        retryClient: dio,
        onRefreshFailure: () async => refreshFailures++,
      ),
    );
    await expectLater(
      RemoteAuthRepository(
        AuthRemoteDataSource(dio),
        storage,
      ).loginWithGoogle('invalid-id-token'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.type,
          'type',
          ApiErrorType.unauthorized,
        ),
      ),
    );
    expect(
      adapter.request!.headers.keys.map((e) => e.toLowerCase()),
      isNot(contains('authorization')),
    );
    expect(adapter.calls, 1);
    expect(refreshFailures, 0);
  });

  test('Google ID token is exchanged at Gateway and app tokens use existing storage', () async {
    final adapter = _Adapter(_envelope());
    final storage = _Storage();
    final repository = RemoteAuthRepository(
      AuthRemoteDataSource(
        Dio(BaseOptions(baseUrl: 'https://gateway.example.test'))
          ..httpClientAdapter = adapter,
      ),
      storage,
    );
    final session = await repository.loginWithGoogle('google-id-token');
    expect(
      adapter.request!.uri.toString(),
      'https://gateway.example.test/api/v1/auth/google',
    );
    expect(adapter.request!.method, 'POST');
    expect(adapter.request!.data, {'credential': 'google-id-token'});
    expect(adapter.request!.extra['skipAuthRefresh'], isTrue);
    expect(
      adapter.request!.headers.keys.map((e) => e.toLowerCase()),
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
    expect(session.accessToken, 'app-access');
    expect(session.refreshToken, 'app-refresh');
    expect(session.user.id, 42);
    expect(session.roles, ['CUSTOMER']);
    expect(storage.access, 'app-access');
    expect(storage.refresh, 'app-refresh');
  });

  test(
    'Google login preserves server roles instead of granting CUSTOMER locally',
    () async {
      final data = _envelope();
      (data['data'] as Map)['roles'] = ['STAFF'];
      ((data['data'] as Map)['user'] as Map)['roles'] = ['STAFF'];
      final repository = RemoteAuthRepository(
        AuthRemoteDataSource(Dio()..httpClientAdapter = _Adapter(data)),
        _Storage(),
      );
      expect((await repository.loginWithGoogle('id-token')).roles, ['STAFF']);
    },
  );

  for (final pair in [
    (400, ApiErrorType.badRequest),
    (401, ApiErrorType.unauthorized),
    (409, ApiErrorType.conflict),
    (500, ApiErrorType.server),
  ]) {
    test(
      'Google Backend ${pair.$1} is mapped and does not save tokens',
      () async {
        final storage = _Storage();
        final repository = RemoteAuthRepository(
          AuthRemoteDataSource(
            Dio()
              ..httpClientAdapter = _Adapter({
                'success': false,
                'message': 'Rejected',
              }, status: pair.$1),
          ),
          storage,
        );
        await expectLater(
          repository.loginWithGoogle('id-token'),
          throwsA(isA<ApiException>().having((e) => e.type, 'type', pair.$2)),
        );
        expect(storage.access, isNull);
        expect(storage.refresh, isNull);
      },
    );
  }

  for (final body in [
    null,
    'invalid',
    {'success': false},
    {'success': true, 'data': {}},
    {
      'success': true,
      'data': {...(_envelope()['data'] as Map), 'accessToken': ''},
    },
    {
      'success': true,
      'data': {...(_envelope()['data'] as Map), 'refreshToken': null},
    },
    {
      'success': true,
      'data': {...(_envelope()['data'] as Map), 'user': null},
    },
    {
      'success': true,
      'data': {
        ...(_envelope()['data'] as Map),
        'roles': [12],
      },
    },
  ]) {
    test(
      'malformed Google envelope never persists a partial session: $body',
      () async {
        final storage = _Storage();
        final repository = RemoteAuthRepository(
          AuthRemoteDataSource(Dio()..httpClientAdapter = _Adapter(body)),
          storage,
        );
        await expectLater(
          repository.loginWithGoogle('id-token'),
          throwsA(isA<ApiException>()),
        );
        expect(storage.access, isNull);
        expect(storage.refresh, isNull);
      },
    );
  }

  test('blank credential is rejected before HTTP', () async {
    final adapter = _Adapter(_envelope());
    final repository = RemoteAuthRepository(
      AuthRemoteDataSource(Dio()..httpClientAdapter = adapter),
      _Storage(),
    );
    await expectLater(
      repository.loginWithGoogle(' '),
      throwsA(isA<ApiException>()),
    );
    expect(adapter.request, isNull);
  });

  test('logout waits for failed Google token cleanup before allowing a new session', () async {
    final storage = _Storage()
      ..failRefreshWrite = true
      ..clearGate = Completer<void>();
    final repository = RemoteAuthRepository(
      AuthRemoteDataSource(Dio()..httpClientAdapter = _Adapter(_envelope())),
      storage,
    );
    final failedLogin = expectLater(
      repository.loginWithGoogle('id-token'),
      throwsA(isA<StateError>()),
    );
    await storage.clearStarted.future;
    var loggedOut = false;
    final logout = repository.logout().then((_) => loggedOut = true);
    await Future<void>.delayed(Duration.zero);
    expect(loggedOut, isFalse);
    storage.clearGate!.complete();
    await failedLogin;
    await logout;
    storage.failRefreshWrite = false;
    await repository.loginWithGoogle('new-id-token');
    expect(storage.access, 'app-access');
    expect(storage.refresh, 'app-refresh');
  });

  test('failed second token write clears partial Google session', () async {
    final storage = _Storage()..failRefreshWrite = true;
    final repository = RemoteAuthRepository(
      AuthRemoteDataSource(Dio()..httpClientAdapter = _Adapter(_envelope())),
      storage,
    );
    await expectLater(
      repository.loginWithGoogle('id-token'),
      throwsA(isA<StateError>()),
    );
    expect(storage.access, isNull);
    expect(storage.refresh, isNull);
  });
}

Map<String, dynamic> _envelope() => {
  'success': true,
  'data': {
    'accessToken': 'app-access',
    'refreshToken': 'app-refresh',
    'tokenType': 'Bearer',
    'expiresInMs': 3600000,
    'user': {
      'id': 42,
      'email': 'customer@example.test',
      'fullName': 'Customer',
      'roles': ['CUSTOMER'],
      'emailVerified': true,
    },
    'roles': ['CUSTOMER'],
  },
};

class _Adapter implements HttpClientAdapter {
  _Adapter(this.body, {this.status = 200});
  final Object? body;
  final int status;
  RequestOptions? request;
  int calls = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    calls++;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Storage implements TokenStorage {
  String? access;
  String? refresh;
  bool failRefreshWrite = false;
  Completer<void>? clearGate;
  final clearStarted = Completer<void>();
  int clearCalls = 0;
  @override
  Future<void> saveAccessToken(String token) async => access = token;
  @override
  Future<void> saveRefreshToken(String token) async {
    if (failRefreshWrite) throw StateError('Storage unavailable');
    refresh = token;
  }

  @override
  Future<String?> getAccessToken() async => access;
  @override
  Future<String?> getRefreshToken() async => refresh;
  @override
  Future<void> deleteAccessToken() async => access = null;
  @override
  Future<void> deleteRefreshToken() async => refresh = null;
  @override
  Future<void> clear() async {
    if (!clearStarted.isCompleted) clearStarted.complete();
    if (clearCalls++ == 0) await clearGate?.future;
    access = null;
    refresh = null;
  }
}
