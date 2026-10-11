import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/network/api_exception.dart';
import 'package:mss301_mobile/features/auth/application/auth_session.dart';

import 'support/google_auth_test_support.dart';

void main() {
  test(
    'Google login establishes the existing app session and saves app tokens',
    () async {
      final adapter = GoogleAuthHttpAdapter();
      final storage = GoogleAuthTokenStorage();
      final container = await _container(adapter, storage);
      final controller = container.read(authSessionProvider.notifier);

      final result = controller.loginWithGoogle(() async => googleCredential);

      expect(container.read(authSessionProvider).isSubmitting, isTrue);
      expect(await result, isTrue);
      final state = container.read(authSessionProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.isAuthenticated, isTrue);
      expect(state.isSubmitting, isFalse);
      expect(state.message, isNull);
      expect(state.session!.accessToken, 'application-access-token');
      expect(state.session!.refreshToken, 'application-refresh-token');
      expect(state.session!.user.id, 5101);
      expect(state.session!.user.email, 'customer@example.test');
      expect(state.session!.roles, ['CUSTOMER']);
      expect(storage.accessToken, state.session!.accessToken);
      expect(storage.refreshToken, state.session!.refreshToken);
      expect(storage.accessToken, isNot(googleCredential));
      expect(storage.refreshToken, isNot(googleCredential));
      expect(adapter.requests.single.path, '/api/v1/auth/google');
      expect(adapter.requests.single.data, {'credential': googleCredential});
    },
  );

  test(
    'closing the Google picker quietly restores the unauthenticated state',
    () async {
      final adapter = GoogleAuthHttpAdapter();
      final storage = GoogleAuthTokenStorage();
      final container = await _container(adapter, storage);
      final controller = container.read(authSessionProvider.notifier);
      final credential = Completer<String?>();

      final result = controller.loginWithGoogle(() => credential.future);
      expect(container.read(authSessionProvider).isSubmitting, isTrue);
      credential.complete(null);

      expect(await result, isFalse);
      final state = container.read(authSessionProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.session, isNull);
      expect(state.message, isNull);
      expect(state.isSubmitting, isFalse);
      expect(adapter.requests, isEmpty);
      expect(storage.saveCalls, 0);
    },
  );

  test(
    'cancelling a retry clears feedback from the previous Google failure',
    () async {
      final adapter = GoogleAuthHttpAdapter();
      final storage = GoogleAuthTokenStorage();
      final container = await _container(adapter, storage);
      final controller = container.read(authSessionProvider.notifier);
      await controller.loginWithGoogle(
        () async => throw StateError('SDK detail'),
      );
      expect(container.read(authSessionProvider).message, isNotNull);

      expect(await controller.loginWithGoogle(() async => null), isFalse);

      expect(container.read(authSessionProvider).message, isNull);
      expect(container.read(authSessionProvider).isSubmitting, isFalse);
      expect(adapter.requests, isEmpty);
    },
  );

  test(
    'an SDK failure is safe to display and allows another Google attempt',
    () async {
      final adapter = GoogleAuthHttpAdapter();
      final storage = GoogleAuthTokenStorage();
      final container = await _container(adapter, storage);
      final controller = container.read(authSessionProvider.notifier);

      expect(
        await controller.loginWithGoogle(
          () async => throw StateError('RAW_SDK_DETAIL $googleCredential'),
        ),
        isFalse,
      );

      final failed = container.read(authSessionProvider);
      expect(failed.status, AuthStatus.unauthenticated);
      expect(failed.isSubmitting, isFalse);
      _expectSafeVietnamese(failed.message);
      expect(adapter.requests, isEmpty);
      expect(storage.saveCalls, 0);
      expect(
        await controller.loginWithGoogle(() async => googleCredential),
        isTrue,
      );
      expect(container.read(authSessionProvider).isAuthenticated, isTrue);
    },
  );

  for (final type in ApiErrorType.values.where(
    (type) => type != ApiErrorType.cancelled,
  )) {
    test(
      'Google ${type.name} errors show safe feedback and allow retry',
      () async {
        final adapter = GoogleAuthHttpAdapter()
          ..error = ApiException(
            type: type,
            message: 'RAW_BACKEND_DETAIL $googleCredential',
            originalCause: StateError('private-provider-detail'),
          );
        final storage = GoogleAuthTokenStorage();
        final container = await _container(adapter, storage);
        final controller = container.read(authSessionProvider.notifier);

        expect(
          await controller.loginWithGoogle(() async => googleCredential),
          isFalse,
        );

        final state = container.read(authSessionProvider);
        expect(state.status, AuthStatus.unauthenticated);
        expect(state.session, isNull);
        expect(state.isSubmitting, isFalse);
        _expectSafeVietnamese(state.message);
        expect(storage.saveCalls, 0);
        adapter.error = null;
        expect(
          await controller.loginWithGoogle(() async => googleCredential),
          isTrue,
        );
        expect(container.read(authSessionProvider).message, isNull);
      },
    );
  }

  test(
    'a duplicate Google submission does not open another picker or request',
    () async {
      final adapter = GoogleAuthHttpAdapter();
      final storage = GoogleAuthTokenStorage();
      final container = await _container(adapter, storage);
      final controller = container.read(authSessionProvider.notifier);
      final credential = Completer<String?>();
      var pickerCalls = 0;
      final first = controller.loginWithGoogle(() {
        pickerCalls++;
        return credential.future;
      });

      final second = await controller.loginWithGoogle(() async {
        pickerCalls++;
        return googleCredential;
      });

      expect(second, isFalse);
      expect(pickerCalls, 1);
      expect(container.read(authSessionProvider).isSubmitting, isTrue);
      expect(adapter.requests, isEmpty);
      credential.complete(googleCredential);
      expect(await first, isTrue);
      expect(adapter.requests, hasLength(1));
      expect(storage.saveCalls, 2);
    },
  );

  test('Google feedback distinguishes invalid credentials, network failure and rate limiting', () async {
    final adapter = GoogleAuthHttpAdapter();
    final storage = GoogleAuthTokenStorage();
    final container = await _container(adapter, storage);
    final controller = container.read(authSessionProvider.notifier);
    final messages = <String>{};

    for (final type in [
      ApiErrorType.unauthorized,
      ApiErrorType.network,
      ApiErrorType.tooManyRequests,
    ]) {
      adapter.error = ApiException(type: type, message: 'RAW_BACKEND_DETAIL');
      expect(
        await controller.loginWithGoogle(() async => googleCredential),
        isFalse,
      );
      final message = container.read(authSessionProvider).message;
      _expectSafeVietnamese(message);
      messages.add(message!);
    }

    expect(messages, hasLength(3));
    expect(storage.saveCalls, 0);
  });

  test(
    'a cancelled Google exchange leaves no session or raw error feedback',
    () async {
      final adapter = GoogleAuthHttpAdapter()
        ..error = const ApiException(
          type: ApiErrorType.cancelled,
          message: 'RAW_CANCEL_DETAIL',
        );
      final storage = GoogleAuthTokenStorage();
      final container = await _container(adapter, storage);
      final controller = container.read(authSessionProvider.notifier);

      expect(
        await controller.loginWithGoogle(() async => googleCredential),
        isFalse,
      );

      final state = container.read(authSessionProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.session, isNull);
      expect(state.isSubmitting, isFalse);
      if (state.message != null) _expectSafeVietnamese(state.message);
      expect(storage.saveCalls, 0);
      adapter.error = null;
      expect(
        await controller.loginWithGoogle(() async => googleCredential),
        isTrue,
      );
    },
  );

  test('Google cannot start while session bootstrap is initializing', () async {
    final adapter = GoogleAuthHttpAdapter();
    final storage = GoogleAuthTokenStorage();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          googleTestRepository(adapter, storage),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(authSessionProvider.notifier);
    var pickerCalls = 0;

    expect(
      await controller.loginWithGoogle(() async {
        pickerCalls++;
        return googleCredential;
      }),
      isFalse,
    );

    expect(pickerCalls, 0);
    expect(adapter.requests, isEmpty);
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(authSessionProvider).status,
      AuthStatus.unauthenticated,
    );
  });

  test('Google login waits for an active password login to finish', () async {
    final gate = Completer<void>();
    final adapter = GoogleAuthHttpAdapter()..responseGate = gate;
    final storage = GoogleAuthTokenStorage();
    final container = await _container(adapter, storage);
    final controller = container.read(authSessionProvider.notifier);
    final passwordLogin = controller.login(
      username: 'customer@example.test',
      password: 'Password1!',
    );
    await adapter.firstRequest.future;
    var pickerCalls = 0;

    expect(
      await controller.loginWithGoogle(() async {
        pickerCalls++;
        return googleCredential;
      }),
      isFalse,
    );

    expect(pickerCalls, 0);
    expect(adapter.requests.single.path, '/api/v1/auth/login');
    gate.complete();
    expect(await passwordLogin, isTrue);
    expect(container.read(authSessionProvider).isAuthenticated, isTrue);
  });

  test('password login cannot race an active Google picker', () async {
    final adapter = GoogleAuthHttpAdapter();
    final storage = GoogleAuthTokenStorage();
    final container = await _container(adapter, storage);
    final controller = container.read(authSessionProvider.notifier);
    final credential = Completer<String?>();
    final googleLogin = controller.loginWithGoogle(() => credential.future);

    expect(
      await controller.login(
        username: 'customer@example.test',
        password: 'Password1!',
      ),
      isFalse,
    );

    expect(adapter.requests, isEmpty);
    expect(container.read(authSessionProvider).isSubmitting, isTrue);
    credential.complete(googleCredential);
    expect(await googleLogin, isTrue);
    expect(adapter.requests.single.path, '/api/v1/auth/google');
    expect(container.read(authSessionProvider).isAuthenticated, isTrue);
    expect(storage.saveCalls, 2);
  });

  test(
    'an authenticated customer cannot replace the session with Google',
    () async {
      final adapter = GoogleAuthHttpAdapter();
      final storage = GoogleAuthTokenStorage();
      final container = await _container(adapter, storage);
      final controller = container.read(authSessionProvider.notifier);
      await controller.loginWithGoogle(() async => googleCredential);
      final session = container.read(authSessionProvider).session;
      var pickerCalls = 0;

      expect(
        await controller.loginWithGoogle(() async {
          pickerCalls++;
          return 'different-google-credential';
        }),
        isFalse,
      );

      expect(pickerCalls, 0);
      expect(container.read(authSessionProvider).session, same(session));
      expect(adapter.requests, hasLength(1));
    },
  );

  test(
    'signOut revokes Google login before the picker returns a credential',
    () async {
      final adapter = GoogleAuthHttpAdapter();
      final storage = GoogleAuthTokenStorage();
      final container = await _container(adapter, storage);
      final controller = container.read(authSessionProvider.notifier);
      final credential = Completer<String?>();
      final pending = controller.loginWithGoogle(() => credential.future);

      await controller.signOut();
      credential.complete(googleCredential);

      expect(await pending, isFalse);
      final state = container.read(authSessionProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.session, isNull);
      expect(state.isSubmitting, isFalse);
      expect(state.message, isNull);
      expect(adapter.requests, isEmpty);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
    },
  );

  test(
    'a late Google backend response cannot save tokens after signOut',
    () async {
      final gate = Completer<void>();
      final adapter = GoogleAuthHttpAdapter()..responseGate = gate;
      final storage = GoogleAuthTokenStorage();
      final container = await _container(adapter, storage);
      final controller = container.read(authSessionProvider.notifier);
      final pending = controller.loginWithGoogle(() async => googleCredential);
      await adapter.firstRequest.future;

      await controller.signOut();
      gate.complete();

      expect(await pending, isFalse);
      final state = container.read(authSessionProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.session, isNull);
      expect(state.message, isNull);
      expect(state.isSubmitting, isFalse);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(storage.saveCalls, 0);
    },
  );

  test('logout releases abandoned picker and an old result cannot unlock a new attempt', () async {
    final adapter = GoogleAuthHttpAdapter();
    final storage = GoogleAuthTokenStorage();
    final container = await _container(adapter, storage);
    final controller = container.read(authSessionProvider.notifier);
    final oldCredential = Completer<String?>();
    final oldAttempt = controller.loginWithGoogle(() => oldCredential.future);
    await controller.signOut();
    final newCredential = Completer<String?>();
    var newPickerCalls = 0;
    final newAttempt = controller.loginWithGoogle(() {
      newPickerCalls++;
      return newCredential.future;
    });
    expect(newPickerCalls, 1);
    oldCredential.complete(googleCredential);
    expect(await oldAttempt, isFalse);
    expect(
      await controller.login(
        username: 'customer@example.test',
        password: 'password',
      ),
      isFalse,
    );
    expect(adapter.requests, isEmpty);
    newCredential.complete(googleCredential);
    expect(await newAttempt, isTrue);
    expect(adapter.requests, hasLength(1));
  });

  test('disposing the session while the picker is open safely abandons Google login', () async {
    final adapter = GoogleAuthHttpAdapter();
    final storage = GoogleAuthTokenStorage();
    final container = await _container(
      adapter,
      storage,
      disposeAtTearDown: false,
    );
    final controller = container.read(authSessionProvider.notifier);
    final credential = Completer<String?>();
    final pending = controller.loginWithGoogle(() => credential.future);

    container.dispose();
    credential.complete(googleCredential);

    expect(await pending, isFalse);
    expect(adapter.requests, isEmpty);
    expect(storage.saveCalls, 0);
  });
}

Future<ProviderContainer> _container(
  GoogleAuthHttpAdapter adapter,
  GoogleAuthTokenStorage storage, {
  bool disposeAtTearDown = true,
}) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        googleTestRepository(adapter, storage),
      ),
    ],
  );
  if (disposeAtTearDown) addTearDown(container.dispose);
  container.read(authSessionProvider);
  await Future<void>.delayed(Duration.zero);
  expect(
    container.read(authSessionProvider).status,
    AuthStatus.unauthenticated,
  );
  return container;
}

void _expectSafeVietnamese(String? message) {
  expect(message, isNotNull);
  expect(message, isNotEmpty);
  expect(message, matches(RegExp(r'[^\x00-\x7F]')));
  expect(message, isNot(contains('RAW_')));
  expect(message, isNot(contains(googleCredential)));
  expect(message, isNot(contains('ApiException')));
  expect(message, isNot(contains('StateError')));
  expect(message, isNot(contains('private-provider-detail')));
}
