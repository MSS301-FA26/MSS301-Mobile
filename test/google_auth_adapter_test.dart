import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:mss301_mobile/features/auth/data/google_auth_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _GooglePlatform platform;
  late GoogleSignInPlatform previousPlatform;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    previousPlatform = GoogleSignInPlatform.instance;
    platform = _GooglePlatform();
    GoogleSignInPlatform.instance = platform;
  });
  tearDown(() {
    GoogleSignInPlatform.instance = previousPlatform;
    debugDefaultTargetPlatformOverride = null;
  });
  GoogleSignInAuthAdapter adapter() => GoogleSignInAuthAdapter(
    const GoogleOAuthConfig(
      serverClientId: 'server.apps.googleusercontent.com',
      iosClientId: 'ios.apps.googleusercontent.com',
    ),
  );

  test('Android uses Backend audience and returns ID token only', () async {
    final google = adapter();
    expect(await google.authenticate(), 'google-id-token');
    expect(
      platform.parameters!.serverClientId,
      'server.apps.googleusercontent.com',
    );
    expect(platform.parameters!.clientId, isNull);
    expect(platform.steps, ['initialize', 'signOut', 'authenticate']);
    expect(platform.scopeHint, isEmpty);
    await google.authenticate();
    expect(platform.initializeCount, 1);
    expect(
      platform.steps.lastIndexOf('signOut'),
      lessThan(platform.steps.lastIndexOf('authenticate')),
    );
  });

  test('iOS uses its own native client and same Backend audience', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await adapter().authenticate();
    expect(platform.parameters!.clientId, 'ios.apps.googleusercontent.com');
    expect(
      platform.parameters!.serverClientId,
      'server.apps.googleusercontent.com',
    );
  });

  test('SDK cancellation is quiet null', () async {
    platform.failure = const GoogleSignInException(
      code: GoogleSignInExceptionCode.canceled,
    );
    expect(await adapter().authenticate(), isNull);
  });

  test(
    'unresolved native picker cannot start a second SDK authentication',
    () async {
      final google = adapter();
      platform.authenticationGate = Completer<void>();
      final first = google.authenticate();
      await platform.authenticationStarted.future;
      await expectLater(
        google.authenticate(),
        throwsA(isA<GoogleAuthException>()),
      );
      expect(
        platform.steps.where((step) => step == 'authenticate'),
        hasLength(1),
      );
      platform.authenticationGate!.complete();
      expect(await first, 'google-id-token');
    },
  );

  test(
    'SDK initialize is attempted once even after initialization fails',
    () async {
      final google = adapter();
      platform.failInitialize = true;
      await expectLater(
        google.initialize(),
        throwsA(isA<GoogleAuthException>()),
      );
      await expectLater(
        google.initialize(),
        throwsA(isA<GoogleAuthException>()),
      );
      expect(platform.initializeCount, 1);
    },
  );

  for (final token in [null, '', ' ']) {
    test('missing ID token is an error, not cancellation: $token', () async {
      platform.idToken = token;
      await expectLater(
        adapter().authenticate(),
        throwsA(isA<GoogleAuthException>()),
      );
    });
  }

  test('SDK details are not exposed to customer', () async {
    platform.failure = const GoogleSignInException(
      code: GoogleSignInExceptionCode.clientConfigurationError,
      description: 'private SDK detail',
    );
    await expectLater(
      adapter().authenticate(),
      throwsA(
        isA<GoogleAuthException>().having(
          (e) => e.message,
          'safe message',
          isNot(contains('private SDK detail')),
        ),
      ),
    );
  });

  test('absent config never invokes SDK', () async {
    final google = GoogleSignInAuthAdapter(
      const GoogleOAuthConfig(serverClientId: ''),
    );
    await expectLater(
      google.authenticate(),
      throwsA(isA<GoogleAuthException>()),
    );
    expect(platform.steps, isEmpty);
  });

  test('iOS missing native client never invokes SDK', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final google = GoogleSignInAuthAdapter(
      const GoogleOAuthConfig(serverClientId: 'server'),
    );
    await expectLater(
      google.authenticate(),
      throwsA(isA<GoogleAuthException>()),
    );
    expect(platform.steps, isEmpty);
  });
}

class _GooglePlatform extends GoogleSignInPlatform {
  InitParameters? parameters;
  String? idToken = 'google-id-token';
  GoogleSignInException? failure;
  int initializeCount = 0;
  bool failInitialize = false;
  Completer<void>? authenticationGate;
  final authenticationStarted = Completer<void>();
  final steps = <String>[];
  List<String>? scopeHint;
  @override
  Future<void> init(InitParameters params) async {
    initializeCount++;
    parameters = params;
    steps.add('initialize');
    if (failInitialize) throw StateError('SDK failed');
  }

  @override
  bool supportsAuthenticate() => true;
  @override
  Future<AuthenticationResults> authenticate(
    AuthenticateParameters params,
  ) async {
    scopeHint = params.scopeHint;
    steps.add('authenticate');
    if (!authenticationStarted.isCompleted) authenticationStarted.complete();
    await authenticationGate?.future;
    if (failure case final error?) throw error;
    return AuthenticationResults(
      user: const GoogleSignInUserData(
        email: 'customer@example.test',
        id: 'google-sub',
      ),
      authenticationTokens: AuthenticationTokenData(idToken: idToken),
    );
  }

  @override
  Future<void> signOut(SignOutParams params) async => steps.add('signOut');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
