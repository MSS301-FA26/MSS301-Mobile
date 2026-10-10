import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mss301_mobile/core/auth/token_storage.dart';
import 'package:mss301_mobile/core/network/network_providers.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/core/theme/app_theme.dart';
import 'package:mss301_mobile/core/time/app_clock.dart';
import 'package:mss301_mobile/features/auth/application/auth_session.dart';
import 'package:mss301_mobile/features/auth/presentation/pages/auth_page.dart';
import 'package:mss301_mobile/features/movie/data/repositories/catalog_providers.dart';

void main() {
  testWidgets('Register has no favorite cinema UI or catalog dependency', (
    tester,
  ) async {
    final harness = await _pump(tester);
    expect(find.byKey(const ValueKey('auth-preferred-cinema')), findsNothing);
    expect(find.text('RẠP YÊU THÍCH'), findsNothing);
    expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    expect(harness.adapter.requests, isEmpty);
  });

  testWidgets(
    'full Register reaches real repositories with exact seven-property JSON and no cinema dependency then existing OTP',
    (tester) async {
      final harness = await _pump(tester);
      expect(harness.adapter.requests, isEmpty);
      await _fill(tester);
      await _submit(tester);
      expect(harness.adapter.requests.single.path, '/api/v1/auth/register');
      expect(harness.adapter.requests.single.method, 'POST');
      expect(harness.adapter.registration, {
        'fullName': 'Customer',
        'email': 'Customer@Example.test',
        'password': ' Password1! ',
        'birthYear': 2000,
        'phone': '0901234567',
        'username': 'customer_name',
        'identityNumber': '001234567890',
      });
      expect(
        harness.adapter.registration!.keys,
        isNot(
          contains(
            anyOf('preferredCinemaId', 'favoriteCinemaId', 'favoriteCinema'),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('auth-otp')), findsOneWidget);
      expect(find.byKey(const ValueKey('auth-identity-number')), findsNothing);
      expect(harness.storage.writes, 0);
      await _enter(tester, 'auth-otp', '012345');
      await _submit(tester);
      final verify = harness.adapter.requests.last;
      expect(verify.method, 'POST');
      expect(verify.path, '/api/v1/auth/verify-email');
      expect(verify.data, {'email': 'Customer@Example.test', 'otp': '012345'});
      expect(harness.adapter.requests, hasLength(2));
      expect(
        harness.router.routeInformationProvider.value.uri.path,
        AppRoutes.account,
      );
      expect(harness.storage.writes, 0);
    },
  );

  testWidgets(
    'date displays day/month/year but serializes only Backend birthYear',
    (tester) async {
      final harness = await _pump(tester);
      await _fill(tester);
      final birth = tester.widget<TextFormField>(
        find.byKey(const ValueKey('auth-birth-date')),
      );
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const ValueKey('auth-birth-date')),
                matching: find.byType(TextField),
              ),
            )
            .readOnly,
        isTrue,
      );
      expect(birth.controller!.text, '01/01/2000');
      await _submit(tester);
      expect(harness.adapter.registration!['birthYear'], 2000);
      expect(harness.adapter.registration!.containsKey('dateOfBirth'), isFalse);
      expect(harness.adapter.registration!.containsKey('birthDate'), isFalse);
      expect(
        harness.adapter.registration!.containsKey('preferredCinemaId'),
        isFalse,
      );
    },
  );

  testWidgets(
    'date picker bounds follow Web 1900 through current UTC date and cancel does not invent a birthday',
    (tester) async {
      await _pump(tester);
      final birth = find.byKey(const ValueKey('auth-birth-date'));
      await tester.tap(birth);
      await tester.pumpAndSettle();
      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(picker.firstDate, DateTime(1900));
      expect(picker.lastDate, DateTime(2026, 10, 10));
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(birth).controller!.text, isEmpty);
      await _submit(tester);
      expect(tester.state<FormFieldState>(birth).hasError, isTrue);
    },
  );

  for (final key in [
    'auth-name',
    'auth-birth-date',
    'auth-phone',
    'auth-username',
    'auth-identity-number',
    'auth-email',
    'auth-password',
    'auth-confirm-password',
  ]) {
    testWidgets(
      '$key is required on Web-mapped Register without changing API nullable contract',
      (tester) async {
        final harness = await _pump(tester);
        await _fill(tester, omit: key);
        await _submit(tester);
        expect(harness.adapter.registration, isNull);
        expect(
          tester.state<FormFieldState>(find.byKey(ValueKey(key))).hasError,
          isTrue,
        );
        expect(find.byKey(const ValueKey('auth-otp')), findsNothing);
      },
    );
  }

  for (final invalid in [
    ('auth-phone', '0712345678'),
    ('auth-username', 'customer name'),
    ('auth-identity-number', '0012345678'),
    ('auth-email', 'customer@@test'),
    ('auth-password', 'password1!'),
    ('auth-confirm-password', 'Password1!'),
  ]) {
    testWidgets('${invalid.$1} invalid input blocks registration', (
      tester,
    ) async {
      final harness = await _pump(tester);
      await _fill(tester);
      await _enter(tester, invalid.$1, invalid.$2);
      await _submit(tester);
      expect(harness.adapter.registration, isNull);
      expect(
        tester.state<FormFieldState>(find.byKey(ValueKey(invalid.$1))).hasError,
        isTrue,
      );
    });
  }

  testWidgets(
    'consent is required and privacy disclosure is readable, never API payload',
    (tester) async {
      final harness = await _pump(tester);
      await _fill(tester, consent: false);
      await _submit(tester);
      expect(harness.adapter.registration, isNull);
      expect(
        tester
            .state<FormFieldState>(find.byKey(const ValueKey('auth-consent')))
            .hasError,
        isTrue,
      );
      final policy = find.byKey(const ValueKey('auth-privacy-policy'));
      await tester.ensureVisible(policy);
      await tester.pumpAndSettle();
      await tester.tap(policy);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('CinePremier thu thập thông tin đăng ký'),
        findsOneWidget,
      );
      await _agree(tester);
      await _submit(tester);
      expect(
        harness.adapter.registration!.keys,
        isNot(
          contains(anyOf('confirmPassword', 'privacyConsent', 'agreeTerms')),
        ),
      );
    },
  );

  testWidgets(
    'mapped API conflict keeps full inputs and exposes recoverable error without OTP',
    (tester) async {
      final harness = await _pump(tester);
      harness.adapter.failRegister = true;
      await _fill(tester);
      await _submit(tester);
      expect(find.byKey(const ValueKey('auth-otp')), findsNothing);
      expect(
        find.textContaining('Identity number already exists'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('auth-identity-number')),
            )
            .controller!
            .text,
        '001234567890',
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('auth-submit')))
            .onPressed,
        isNotNull,
      );
      harness.adapter.failRegister = false;
      await _submit(tester);
      expect(find.byKey(const ValueKey('auth-otp')), findsOneWidget);
    },
  );
  for (final width in [320.0, 430.0, 768.0]) {
    testWidgets(
      'all useful Register controls are reachable at $width and 200%',
      (tester) async {
        final harness = await _pump(tester, width: width, scale: 2);
        expect(find.byType(TextFormField), findsNWidgets(8));
        expect(
          find.byKey(const ValueKey('auth-preferred-cinema')),
          findsNothing,
        );
        for (final key in [
          'auth-name',
          'auth-birth-date',
          'auth-phone',
          'auth-username',
          'auth-identity-number',
          'auth-email',
          'auth-password',
          'auth-confirm-password',
          'auth-consent',
          'auth-submit',
          'auth-trust-footer',
        ]) {
          final control = find.byKey(ValueKey(key));
          await tester.ensureVisible(control);
          await tester.pumpAndSettle();
          final bounds = tester.getRect(control);
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(bounds.right, lessThanOrEqualTo(width));
          expect(bounds.top, greaterThanOrEqualTo(0));
          expect(bounds.bottom, lessThanOrEqualTo(900));
        }
        expect(harness.adapter.requests, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<({GoRouter router, _Adapter adapter, _Storage storage})> _pump(
  WidgetTester tester, {
  double width = 430,
  double scale = 1,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final adapter = _Adapter();
  final storage = _Storage();
  final router = GoRouter(
    initialLocation: AppRoutes.register,
    routes: [
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const AuthPage(mode: AuthPageMode.register),
      ),
      GoRoute(
        path: AppRoutes.account,
        builder: (_, _) => const Scaffold(body: Text('Account')),
      ),
    ],
  );
  addTearDown(router.dispose);
  final dio = Dio(BaseOptions(baseUrl: 'https://gateway.example.test'))
    ..httpClientAdapter = adapter;
  addTearDown(dio.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dioProvider.overrideWithValue(dio),
        tokenStorageProvider.overrideWithValue(storage),
        appClockProvider.overrideWithValue(
          FakeAppClock(DateTime.utc(2026, 10, 10)),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.dark,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (router: router, adapter: adapter, storage: storage);
}

Future<void> _enter(WidgetTester tester, String key, String value) async {
  await tester.pumpAndSettle();
  final field = find.byKey(ValueKey(key));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, value);
}

Future<void> _fill(
  WidgetTester tester, {
  String? omit,
  bool consent = true,
}) async {
  if (omit != 'auth-birth-date') {
    final birth = find.byKey(const ValueKey('auth-birth-date'));
    await tester.ensureVisible(birth);
    await tester.pumpAndSettle();
    await tester.tap(birth);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }
  for (final input in {
    'auth-name': ' Customer ',
    'auth-phone': '0901234567',
    'auth-username': ' customer_name ',
    'auth-identity-number': '001234567890',
    'auth-email': ' Customer@Example.test ',
    'auth-password': ' Password1! ',
    'auth-confirm-password': ' Password1! ',
  }.entries) {
    if (input.key != omit) await _enter(tester, input.key, input.value);
  }
  if (consent) await _agree(tester);
}

Future<void> _agree(WidgetTester tester) async {
  await tester.pumpAndSettle();
  final checkbox = find.byType(Checkbox);
  await tester.ensureVisible(checkbox);
  await tester.pumpAndSettle();
  if (tester.widget<Checkbox>(checkbox).value != true) {
    await tester.tap(checkbox);
  }
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester) async {
  await tester.pumpAndSettle();
  final submit = find.byKey(const ValueKey('auth-submit'));
  await tester.ensureVisible(submit);
  await tester.pumpAndSettle();
  await tester.tap(submit);
  await tester.pumpAndSettle();
}

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  Map<String, Object?>? registration;
  bool failRegister = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    Object? data;
    var status = 200;
    if (options.path == '/api/v1/auth/register') {
      registration = Map<String, Object?>.from(options.data as Map);
      status = failRegister ? 409 : 201;
      data = {
        'user': {
          'id': null,
          'fullName': registration!['fullName'],
          'email': registration!['email'],
          'roles': ['CUSTOMER'],
        },
        'emailVerificationRequired': true,
        'emailVerificationExpiresInSeconds': 90,
      };
    } else if (options.path != '/api/v1/auth/verify-email') {
      throw StateError('Unexpected request ${options.method} ${options.path}');
    }
    return ResponseBody.fromString(
      jsonEncode({
        'success': status < 400,
        'data': data,
        if (status == 409) 'message': 'Identity number already exists',
      }),
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
  int writes = 0;
  @override
  Future<String?> getAccessToken() async => null;
  @override
  Future<String?> getRefreshToken() async => null;
  @override
  Future<void> saveAccessToken(String token) async {
    writes++;
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    writes++;
  }

  @override
  Future<void> deleteAccessToken() async {
    writes++;
  }

  @override
  Future<void> deleteRefreshToken() async {
    writes++;
  }

  @override
  Future<void> clear() async {
    writes++;
  }
}
