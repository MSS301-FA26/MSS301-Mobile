import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/core/theme/app_theme.dart';
import 'package:mss301_mobile/features/auth/application/auth_session.dart';
import 'package:mss301_mobile/features/auth/application/google_auth_provider.dart';
import 'package:mss301_mobile/features/auth/data/google_auth_adapter.dart';
import 'package:mss301_mobile/features/auth/presentation/pages/auth_page.dart';

import 'support/google_auth_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('Google button signs in without requiring password form values', (
    tester,
  ) async {
    final google = _GoogleAdapter();
    final harness = await _pumpLogin(tester, google);
    expect(_googleButton(tester).onPressed, isNotNull);
    expect(find.byKey(const ValueKey('auth-google-unavailable')), findsNothing);

    await _tapGoogle(tester);
    await tester.pumpAndSettle();

    expect(google.authenticateCalls, 1);
    expect(harness.http.requests.single.path, '/api/v1/auth/google');
    expect(harness.http.requests.single.data, {'credential': googleCredential});
    expect(harness.container.read(authSessionProvider).isAuthenticated, isTrue);
    expect(harness.storage.accessToken, 'application-access-token');
    expect(harness.storage.refreshToken, 'application-refresh-token');
    expect(
      harness.router.routeInformationProvider.value.uri.path,
      AppRoutes.home,
    );
    expect(find.text('Email không hợp lệ'), findsNothing);
    expect(find.text('Mật khẩu tối thiểu 6 ký tự'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cancelling Google leaves login usable without feedback or API calls',
    (tester) async {
      final google = _GoogleAdapter()..credential = null;
      final harness = await _pumpLogin(tester, google);

      await _tapGoogle(tester);
      await tester.pumpAndSettle();

      expect(google.authenticateCalls, 1);
      expect(harness.http.requests, isEmpty);
      expect(harness.storage.saveCalls, 0);
      expect(
        harness.router.routeInformationProvider.value.uri.path,
        AppRoutes.login,
      );
      expect(find.byKey(const ValueKey('auth-message')), findsNothing);
      expect(_googleButton(tester).onPressed, isNotNull);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(harness.container.read(authSessionProvider).isSubmitting, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('SDK errors show safe feedback and a Google retry succeeds', (
    tester,
  ) async {
    final google = _GoogleAdapter()
      ..error = StateError('RAW_SDK_DETAIL $googleCredential');
    final harness = await _pumpLogin(tester, google);

    await _tapGoogle(tester);
    await tester.pumpAndSettle();

    _expectSafeFeedback(tester);
    expect(harness.http.requests, isEmpty);
    expect(
      harness.router.routeInformationProvider.value.uri.path,
      AppRoutes.login,
    );
    expect(_googleButton(tester).onPressed, isNotNull);
    google.error = null;
    await _tapGoogle(tester);
    await tester.pumpAndSettle();

    expect(google.authenticateCalls, 2);
    expect(harness.container.read(authSessionProvider).isAuthenticated, isTrue);
    expect(
      harness.router.routeInformationProvider.value.uri.path,
      AppRoutes.home,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'rejected Google credentials show safe backend feedback and allow retry',
    (tester) async {
      final google = _GoogleAdapter();
      final http = GoogleAuthHttpAdapter()
        ..statusCode = 401
        ..responseBody = {
          'success': false,
          'message': 'RAW_BACKEND_DETAIL $googleCredential',
        };
      final harness = await _pumpLogin(tester, google, http: http);

      await _tapGoogle(tester);
      await tester.pumpAndSettle();

      _expectSafeFeedback(tester);
      expect(
        harness.container.read(authSessionProvider).isAuthenticated,
        isFalse,
      );
      expect(harness.storage.saveCalls, 0);
      expect(
        harness.router.routeInformationProvider.value.uri.path,
        AppRoutes.login,
      );
      expect(_googleButton(tester).onPressed, isNotNull);
      http.statusCode = 200;
      http.responseBody = googleSessionEnvelope();
      await _tapGoogle(tester);
      await tester.pumpAndSettle();

      expect(google.authenticateCalls, 2);
      expect(http.requests, hasLength(2));
      expect(
        harness.router.routeInformationProvider.value.uri.path,
        AppRoutes.home,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Google login honors the existing local continue destination', (
    tester,
  ) async {
    final harness = await _pumpLogin(
      tester,
      _GoogleAdapter(),
      location: '${AppRoutes.login}?continue=%2Forders',
    );

    await _tapGoogle(tester);
    await tester.pumpAndSettle();

    expect(
      harness.router.routeInformationProvider.value.uri.path,
      AppRoutes.orders,
    );
    expect(find.text('Destination ${AppRoutes.orders}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final unsafe in ['//external.test', 'https://external.test']) {
    testWidgets('Google login sends unsafe continue "$unsafe" to home', (
      tester,
    ) async {
      final harness = await _pumpLogin(
        tester,
        _GoogleAdapter(),
        location:
            '${AppRoutes.login}?continue=${Uri.encodeQueryComponent(unsafe)}',
      );

      await _tapGoogle(tester);
      await tester.pumpAndSettle();

      expect(
        harness.router.routeInformationProvider.value.uri.path,
        AppRoutes.home,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'pending Google login disables both submissions and ignores repeated taps',
    (tester) async {
      final credential = Completer<String?>();
      final google = _GoogleAdapter()..pendingCredential = credential;
      final harness = await _pumpLogin(tester, google);

      await _tapGoogle(tester);

      expect(google.authenticateCalls, 1);
      expect(_googleButton(tester).onPressed, isNull);
      expect(tester.widget<FilledButton>(_passwordButton).onPressed, isNull);
      expect(
        find.descendant(
          of: _googleButtonFinder,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      await tester.tap(_googleButtonFinder);
      await tester.pump();
      expect(google.authenticateCalls, 1);
      expect(harness.http.requests, isEmpty);
      credential.complete(googleCredential);
      await tester.pumpAndSettle();

      expect(harness.http.requests, hasLength(1));
      expect(
        harness.router.routeInformationProvider.value.uri.path,
        AppRoutes.home,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'disposing login while Google picker is open causes no late request or exception',
    (tester) async {
      final credential = Completer<String?>();
      final google = _GoogleAdapter()..pendingCredential = credential;
      final harness = await _pumpLogin(tester, google);
      await _tapGoogle(tester);
      expect(google.authenticateCalls, 1);

      await tester.pumpWidget(const SizedBox.shrink());
      credential.complete(googleCredential);
      await tester.pumpAndSettle();

      expect(harness.http.requests, isEmpty);
      expect(harness.storage.saveCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'password login still trims email and sends the original password',
    (tester) async {
      final google = _GoogleAdapter();
      final harness = await _pumpLogin(
        tester,
        google,
        location: '${AppRoutes.login}?continue=%2Forders',
      );
      await tester.enterText(
        find.byKey(const ValueKey('auth-email')),
        ' customer@example.test ',
      );
      await tester.enterText(
        find.byKey(const ValueKey('auth-password')),
        ' password with spaces ',
      );
      await tester.ensureVisible(_passwordButton);
      await tester.pumpAndSettle();

      await tester.tap(_passwordButton);
      await tester.pumpAndSettle();

      expect(google.authenticateCalls, 0);
      expect(harness.http.requests.single.path, '/api/v1/auth/login');
      expect(harness.http.requests.single.data, {
        'username': 'customer@example.test',
        'password': ' password with spaces ',
      });
      expect(
        harness.router.routeInformationProvider.value.uri.path,
        AppRoutes.orders,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 430.0, 768.0]) {
    testWidgets('Google action remains usable at width $width and 200% text', (
      tester,
    ) async {
      final google = _GoogleAdapter()..credential = null;
      await _pumpLogin(tester, google, width: width, textScale: 2);
      await tester.ensureVisible(_googleButtonFinder);
      await tester.pumpAndSettle();

      final bounds = tester.getRect(_googleButtonFinder);
      expect(bounds.height, greaterThanOrEqualTo(48));
      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(width));
      expect(bounds.bottom, lessThanOrEqualTo(900));
      expect(_googleButton(tester).onPressed, isNotNull);
      await tester.tap(_googleButtonFinder);
      await tester.pumpAndSettle();

      expect(google.authenticateCalls, 1);
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [320.0, 430.0, 768.0]) {
    testWidgets('CinePremier Google login composition at $width', (
      tester,
    ) async {
      await _pumpLogin(tester, _GoogleAdapter(), width: width);
      expect(find.text('CINEPREMIER'), findsOneWidget);
      expect(find.text('ĐĂNG NHẬP BẰNG GOOGLE'), findsOneWidget);
      expect(find.text('AN TOÀN'), findsOneWidget);
      expect(find.text('CINEPREMIER CLUB'), findsOneWidget);
      expect(_googleButton(tester).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('CAPTURE_GOOGLE_LOGIN')) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('google-login-capture')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/google-login/login-${width.toInt()}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}

final _googleButtonFinder = find.byKey(const ValueKey('auth-google-login'));
final _passwordButton = find.byKey(const ValueKey('auth-submit'));

ButtonStyleButton _googleButton(WidgetTester tester) =>
    tester.widget<ButtonStyleButton>(_googleButtonFinder);

Future<void> _tapGoogle(WidgetTester tester) async {
  await tester.ensureVisible(_googleButtonFinder);
  await tester.pumpAndSettle();
  await tester.tap(_googleButtonFinder);
  await tester.pump();
}

void _expectSafeFeedback(WidgetTester tester) {
  final finder = find.byKey(const ValueKey('auth-message'));
  expect(finder, findsOneWidget);
  final message = tester.widget<Text>(finder).data!;
  expect(message, isNotEmpty);
  expect(message, matches(RegExp(r'[^\x00-\x7F]')));
  expect(message, isNot(contains('RAW_')));
  expect(message, isNot(contains(googleCredential)));
  expect(message, isNot(contains('ApiException')));
  expect(message, isNot(contains('StateError')));
}

Future<_LoginHarness> _pumpLogin(
  WidgetTester tester,
  _GoogleAdapter google, {
  GoogleAuthHttpAdapter? http,
  String location = AppRoutes.login,
  double width = 430,
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final adapter = http ?? GoogleAuthHttpAdapter();
  final storage = GoogleAuthTokenStorage();
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const AuthPage(mode: AuthPageMode.login),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const AuthPage(mode: AuthPageMode.register),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const AuthPage(mode: AuthPageMode.forgotPassword),
      ),
      for (final path in [AppRoutes.home, AppRoutes.account, AppRoutes.orders])
        GoRoute(
          path: path,
          builder: (_, _) => Scaffold(body: Text('Destination $path')),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          googleTestRepository(adapter, storage),
        ),
        googleAuthAdapterProvider.overrideWithValue(google),
      ],
      child: RepaintBoundary(
        key: const ValueKey('google-login-capture'),
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark.copyWith(
            textTheme: AppTheme.dark.textTheme.apply(fontFamily: 'Inter'),
          ),
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(AuthPage)),
  );
  expect(
    container.read(authSessionProvider).status,
    AuthStatus.unauthenticated,
  );
  return _LoginHarness(router, container, adapter, storage);
}

class _LoginHarness {
  const _LoginHarness(this.router, this.container, this.http, this.storage);

  final GoRouter router;
  final ProviderContainer container;
  final GoogleAuthHttpAdapter http;
  final GoogleAuthTokenStorage storage;
}

class _GoogleAdapter implements GoogleAuthAdapter {
  String? credential = googleCredential;
  Object? error;
  Completer<String?>? pendingCredential;
  int authenticateCalls = 0;

  @override
  Stream<String?> get credentials => const Stream<String?>.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> authenticate() async {
    authenticateCalls++;
    final failure = error;
    if (failure != null) throw failure;
    final pending = pendingCredential;
    if (pending != null) return await pending.future;
    return credential;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
