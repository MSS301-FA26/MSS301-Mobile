import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/core/theme/app_theme.dart';
import 'package:mss301_mobile/core/time/app_clock.dart';
import 'package:mss301_mobile/features/auth/application/auth_session.dart';
import 'package:mss301_mobile/features/auth/data/auth_models.dart';
import 'package:mss301_mobile/features/auth/presentation/pages/auth_page.dart';
import 'package:mss301_mobile/features/movie/data/repositories/catalog_providers.dart';
import 'package:mss301_mobile/shared/widgets/app_shell.dart';
import 'package:mss301_mobile/shared/widgets/cinema_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
    await font.load();
  });

  testWidgets('verification maps Web information hierarchy and real email', (
    tester,
  ) async {
    final fixture = await _pumpVerification(tester);
    expect(fixture.auth.registrationEmail, 'customer@example.test');
    expect(
      find.byKey(const ValueKey('auth-verification-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-verification-email')),
      findsOneWidget,
    );
    expect(find.text('customer@example.test'), findsOneWidget);
    expect(find.text('XÁC THỰC EMAIL'), findsNWidgets(2));
    expect(find.text('MÃ OTP EMAIL'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(_key('auth-password'), findsNothing);
    expect(find.text('MẬT KHẨU'), findsNothing);
    expect(find.text('0/6'), findsNothing);
    expect(find.text('6/6'), findsNothing);
    expect(find.text('Đã có tài khoản?'), findsNothing);
    expect(find.text('Về đăng nhập'), findsNothing);
    expect(
      find.text('Nhập mã đã được gửi đến email để xác thực tài khoản.'),
      findsNothing,
    );
    expect(find.byType(AppShell), findsNothing);
    expect(find.byType(CinemaHeader), findsNothing);
    expect(_key('auth-brand-header'), findsOneWidget);
    expect(_key('auth-trust-footer'), findsOneWidget);
    expect(find.text('CINEPREMIER'), findsOneWidget);
    expect(find.text('AN TOÀN'), findsOneWidget);
    expect(find.text('CINEPREMIER CLUB'), findsOneWidget);
    expect(_isSelected(tester, 'auth-register-tab'), isTrue);
    expect(_isSelected(tester, 'auth-login-tab'), isFalse);
    expect(
      tester.getRect(_key('auth-verification-panel')).bottom,
      lessThan(tester.getRect(_otp).top),
    );
    expect(_countdown(tester), contains('1:30'));
  });

  testWidgets('OTP input is numeric, mail-prefixed, sharp and has no counter', (
    tester,
  ) async {
    await _pumpVerification(tester);
    final field = tester.widget<TextField>(
      find.descendant(of: _otp, matching: find.byType(TextField)),
    );
    expect(field.keyboardType, TextInputType.number);
    expect(field.decoration?.hintText, 'Nhập mã OTP');
    expect(field.decoration?.counterText, '');
    expect(
      (field.decoration?.prefixIcon as Icon).icon,
      anyOf(Icons.mail_outline, Icons.mail_outline_rounded),
    );
    final border = field.decoration!.enabledBorder! as OutlineInputBorder;
    expect(border.borderRadius, BorderRadius.zero);
    expect(border.borderSide.color, AppColors.borderStrong);
    expect(field.decoration?.fillColor, AppColors.surface);
    final button = tester.widget<FilledButton>(_submit);
    expect(button.style?.backgroundColor?.resolve({}), AppColors.gold);
    expect(button.style?.foregroundColor?.resolve({}), AppColors.background);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(tester.getSize(_submit).height, greaterThanOrEqualTo(54));
  });

  testWidgets('response expiry is used rather than Web hardcoded ten minutes', (
    tester,
  ) async {
    await _pumpVerification(tester, auth: _OtpAuth(ttl: 37));
    expect(_countdown(tester), contains('0:37'));
    expect(_countdown(tester), isNot(contains('10:00')));
  });

  for (final ttl in [0, -5]) {
    testWidgets('nonpositive response TTL $ttl is already expired', (
      tester,
    ) async {
      await _pumpVerification(tester, auth: _OtpAuth(ttl: ttl));
      expect(_countdown(tester), contains('OTP đã hết hạn'));
      expect(tester.widget<OutlinedButton>(_resend).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('delayed registration keeps request-time deadline and email', (
    tester,
  ) async {
    final pending = Completer<void>();
    final fixture = await _pumpVerification(
      tester,
      auth: _OtpAuth()..pendingRegister = pending,
      submitRegistration: false,
    );
    await tester.ensureVisible(_submit);
    await tester.pumpAndSettle();
    await tester.tap(_submit);
    await tester.pump();
    expect(fixture.auth.registerCalls, 1);
    expect(fixture.auth.registrationEmail, 'customer@example.test');
    fixture.clock.advance(const Duration(seconds: 20));
    tester.widget<TextFormField>(_key('auth-email')).controller!.text =
        'changed.while.pending@example.test';
    await tester.pump();
    pending.complete();
    await tester.pumpAndSettle();
    expect(_countdown(tester), contains('1:10'));
    expect(find.text('customer@example.test'), findsOneWidget);
    expect(find.text('changed.while.pending@example.test'), findsNothing);
    await _enter(tester, 'auth-otp', '012345');
    await _tap(tester, _submit);
    expect(fixture.auth.verification, ('customer@example.test', '012345'));
  });

  testWidgets('delayed resend does not add request latency to OTP validity', (
    tester,
  ) async {
    final pending = Completer<bool>();
    final fixture = await _pumpVerification(
      tester,
      auth: _OtpAuth()..pendingResend = pending,
    );
    await _expire(tester, fixture.clock);
    await _enter(tester, 'auth-otp', '012345');
    await tester.ensureVisible(_resend);
    await tester.pumpAndSettle();
    await tester.tap(_resend);
    await tester.pump();
    fixture.clock.advance(const Duration(seconds: 20));
    pending.complete(true);
    await tester.pumpAndSettle();
    expect(_code(tester), isEmpty);
    expect(_countdown(tester), contains('1:10'));
    expect(fixture.auth.resendEmail, 'customer@example.test');
  });

  for (final point in [
    (
      name: 'before',
      elapsed: const Duration(seconds: 89, milliseconds: 999),
      expired: false,
    ),
    (name: 'exactly at', elapsed: const Duration(seconds: 90), expired: true),
    (name: 'after', elapsed: const Duration(seconds: 91), expired: true),
  ]) {
    testWidgets('OTP expiry ${point.name} deadline uses fake clock', (
      tester,
    ) async {
      final fixture = await _pumpVerification(tester);
      fixture.clock.advance(point.elapsed);
      await tester.pump(const Duration(seconds: 1));
      expect(
        _countdown(tester),
        point.expired ? contains('OTP đã hết hạn') : contains('0:01'),
      );
      expect(
        tester.widget<OutlinedButton>(_resend).onPressed,
        point.expired ? isNotNull : isNull,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('periodic timer derives time from clock rather than tick count', (
    tester,
  ) async {
    final fixture = await _pumpVerification(tester);
    fixture.clock.advance(const Duration(seconds: 12));
    await tester.pump(const Duration(seconds: 1));
    expect(_countdown(tester), contains('1:18'));
    await tester.pump(const Duration(seconds: 4));
    expect(_countdown(tester), contains('1:18'));
  });

  testWidgets('resume rechecks an expired deadline immediately', (
    tester,
  ) async {
    final fixture = await _pumpVerification(tester);
    for (final lifecycle in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(lifecycle);
      await tester.pump();
    }
    fixture.clock.advance(const Duration(minutes: 2));
    for (final lifecycle in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(lifecycle);
      await tester.pump();
    }
    expect(_countdown(tester), contains('OTP đã hết hạn'));
    expect(tester.widget<OutlinedButton>(_resend).onPressed, isNotNull);
  });

  testWidgets('timer is disposed when leaving registration OTP', (
    tester,
  ) async {
    final fixture = await _pumpVerification(tester);
    fixture.router.go(AppRoutes.login);
    await tester.pumpAndSettle();
    fixture.clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(minutes: 2));
    expect(tester.takeException(), isNull);
    expect(_key('auth-verification-panel'), findsNothing);
  });

  testWidgets('OTP focus traversal excludes preserved hidden Register fields', (
    tester,
  ) async {
    await _pumpVerification(tester);
    void expectHiddenFieldsUnfocused() {
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
        final field = find.byKey(ValueKey(key), skipOffstage: false);
        final editable = find.descendant(
          of: field,
          matching: find.byType(EditableText, skipOffstage: false),
          skipOffstage: false,
        );
        if (editable.evaluate().isNotEmpty) {
          expect(
            tester.widget<EditableText>(editable).focusNode.hasFocus,
            isFalse,
            reason: '$key must not receive focus during OTP',
          );
        }
      }
    }

    expectHiddenFieldsUnfocused();
    await tester.ensureVisible(_otp);
    await tester.pumpAndSettle();
    await tester.tap(_otp);
    await tester.pump();
    for (var step = 0; step < 16; step++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expectHiddenFieldsUnfocused();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid OTP is rejected and text input strips nonnumeric data', (
    tester,
  ) async {
    final fixture = await _pumpVerification(tester);
    await _enter(tester, 'auth-otp', 'AbC123');
    expect(_code(tester), '123');
    await _tap(tester, _submit);
    expect(fixture.auth.verifyCalls, 0);
    expect(find.text('OTP gồm 6 chữ số'), findsOneWidget);
    expect(
      fixture.router.routeInformationProvider.value.uri.path,
      AppRoutes.register,
    );
  });

  testWidgets('verify preserves leading zero and existing account navigation', (
    tester,
  ) async {
    final fixture = await _pumpVerification(tester);
    await _enter(tester, 'auth-otp', '012345');
    await _tap(tester, _submit);
    expect(fixture.auth.verification, ('customer@example.test', '012345'));
    expect(fixture.auth.loginCalls, 0);
    expect(fixture.auth.currentState.isAuthenticated, isFalse);
    expect(fixture.auth.currentState.session, isNull);
    expect(
      fixture.router.routeInformationProvider.value.uri.path,
      AppRoutes.account,
    );
  });

  testWidgets('pending verify guards repeat submit, resend and back', (
    tester,
  ) async {
    final pending = Completer<bool>();
    final fixture = await _pumpVerification(
      tester,
      auth: _OtpAuth()..pendingVerify = pending,
    );
    await _expire(tester, fixture.clock);
    await _enter(tester, 'auth-otp', '012345');
    await tester.ensureVisible(_submit);
    await tester.tap(_submit);
    await tester.pump();
    expect(fixture.auth.verifyCalls, 1);
    expect(tester.widget<FilledButton>(_submit).onPressed, isNull);
    expect(tester.widget<OutlinedButton>(_resend).onPressed, isNull);
    expect(tester.widget<OutlinedButton>(_back).onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    await tester.tap(_submit);
    await tester.pump();
    expect(fixture.auth.verifyCalls, 1);
    expect(fixture.auth.resendCalls, 0);
    pending.complete(false);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(_submit).onPressed, isNotNull);
    expect(_otp, findsOneWidget);
  });

  testWidgets('server expired OTP error is recoverable without clearing code', (
    tester,
  ) async {
    final fixture = await _pumpVerification(
      tester,
      auth: _OtpAuth()
        ..verifyResult = false
        ..verifyError = 'OTP is expired or already used',
    );
    await _enter(tester, 'auth-otp', '012345');
    await _tap(tester, _submit);
    expect(find.text('OTP is expired or already used'), findsOneWidget);
    expect(_code(tester), '012345');
    expect(tester.widget<FilledButton>(_submit).onPressed, isNotNull);
    expect(
      fixture.router.routeInformationProvider.value.uri.path,
      AppRoutes.register,
    );
    fixture.auth.verifyResult = true;
    await _enter(tester, 'auth-otp', '654321');
    await _tap(tester, _submit);
    expect(fixture.auth.verifyCalls, 2);
    expect(
      fixture.router.routeInformationProvider.value.uri.path,
      AppRoutes.account,
    );
  });

  testWidgets('resend is disabled while OTP is active and enabled at expiry', (
    tester,
  ) async {
    final fixture = await _pumpVerification(tester);
    expect(tester.widget<OutlinedButton>(_resend).onPressed, isNull);
    await _tap(tester, _resend);
    expect(fixture.auth.resendCalls, 0);
    await _expire(tester, fixture.clock);
    expect(tester.widget<OutlinedButton>(_resend).onPressed, isNotNull);
  });

  testWidgets('successful resend retains email, clears code and restarts TTL', (
    tester,
  ) async {
    final fixture = await _pumpVerification(tester, auth: _OtpAuth(ttl: 37));
    await _enter(tester, 'auth-otp', '012345');
    fixture.clock.advance(const Duration(seconds: 37));
    await tester.pump(const Duration(seconds: 1));
    await _tap(tester, _resend);
    expect(fixture.auth.resendCalls, 1);
    expect(fixture.auth.resendEmail, 'customer@example.test');
    expect(_code(tester), isEmpty);
    expect(_countdown(tester), contains('0:37'));
    expect(tester.widget<OutlinedButton>(_resend).onPressed, isNull);
    fixture.clock.advance(const Duration(seconds: 36));
    await tester.pump(const Duration(seconds: 1));
    expect(_countdown(tester), contains('0:01'));
    expect(tester.widget<OutlinedButton>(_resend).onPressed, isNull);
    fixture.clock.advance(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.widget<OutlinedButton>(_resend).onPressed, isNotNull);
  });

  testWidgets('failed resend keeps code and expired deadline with retry', (
    tester,
  ) async {
    final fixture = await _pumpVerification(
      tester,
      auth: _OtpAuth()..resendResult = false,
    );
    await _expire(tester, fixture.clock);
    await _enter(tester, 'auth-otp', '012345');
    await _tap(tester, _resend);
    expect(
      find.text('Không thể gửi lại OTP. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(_code(tester), '012345');
    expect(_countdown(tester), contains('OTP đã hết hạn'));
    expect(tester.widget<OutlinedButton>(_resend).onPressed, isNotNull);
    fixture.auth.resendResult = true;
    await _tap(tester, _resend);
    expect(fixture.auth.resendCalls, 2);
    expect(_code(tester), isEmpty);
    expect(_countdown(tester), contains('1:30'));
    expect(find.text('Không thể gửi lại OTP. Vui lòng thử lại.'), findsNothing);
  });

  testWidgets('pending resend guards duplicate request, verify and back', (
    tester,
  ) async {
    final pending = Completer<bool>();
    final fixture = await _pumpVerification(
      tester,
      auth: _OtpAuth()..pendingResend = pending,
    );
    await _expire(tester, fixture.clock);
    await _enter(tester, 'auth-otp', '012345');
    await tester.ensureVisible(_resend);
    await tester.tap(_resend);
    await tester.pump();
    expect(fixture.auth.resendCalls, 1);
    expect(tester.widget<OutlinedButton>(_resend).onPressed, isNull);
    expect(tester.widget<OutlinedButton>(_back).onPressed, isNull);
    expect(tester.widget<FilledButton>(_submit).onPressed, isNull);
    await tester.tap(_resend);
    await tester.pump();
    expect(fixture.auth.resendCalls, 1);
    expect(fixture.auth.verifyCalls, 0);
    pending.complete(true);
    await tester.pumpAndSettle();
    expect(_code(tester), isEmpty);
    expect(_countdown(tester), contains('1:30'));
  });

  testWidgets(
    'back returns to registration preserving all fields and consent',
    (tester) async {
      final fixture = await _pumpVerification(tester);
      await _enter(tester, 'auth-otp', '012345');
      await _tap(tester, _back);
      expect(
        fixture.router.routeInformationProvider.value.uri.path,
        AppRoutes.register,
      );
      expect(_key('auth-verification-panel'), findsNothing);
      expect(find.byType(TextFormField), findsNWidgets(8));
      for (final entry in {
        'auth-name': 'Customer',
        'auth-email': 'customer@example.test',
        'auth-phone': '0901234567',
        'auth-username': 'customer_name',
        'auth-identity-number': '001234567890',
        'auth-password': 'Password1!',
        'auth-confirm-password': 'Password1!',
      }.entries) {
        expect(
          tester.widget<TextFormField>(_key(entry.key)).controller!.text,
          entry.value,
        );
      }
      expect(
        tester.widget<TextFormField>(_key('auth-birth-date')).controller!.text,
        isNotEmpty,
      );
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      await _tap(tester, _submit);
      expect(fixture.auth.registerCalls, 2);
      expect(_code(tester), isEmpty);
      expect(_countdown(tester), contains('1:30'));
    },
  );

  for (final width in [320.0, 430.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('verification fits $width at ${scale * 100}% with keyboard', (
        tester,
      ) async {
        final metrics = ValueNotifier((scale: 1.0, keyboard: 0.0));
        final email = '${'long.registration.email.' * 3}customer@example.test';
        await _pumpVerification(
          tester,
          width: width,
          email: email,
          metrics: metrics,
        );
        metrics.value = (scale: scale, keyboard: 250.0);
        await tester.pumpAndSettle();
        for (final target in [
          _key('auth-verification-email'),
          _key('auth-verification-countdown'),
          _otp,
          _submit,
          _back,
          _resend,
          _key('auth-trust-footer'),
        ]) {
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
          final bounds = tester.getRect(target);
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(bounds.right, lessThanOrEqualTo(width));
          expect(bounds.bottom, lessThanOrEqualTo(650));
          expect(tester.takeException(), isNull);
        }
        expect(tester.getSize(_back).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(_resend).height, greaterThanOrEqualTo(48));
        expect(find.text('QUAY LẠI'), findsOneWidget);
        expect(find.text('GỬI LẠI MÃ OTP'), findsOneWidget);
        expect(find.text(email), findsOneWidget);
      });
    }
  }
}

Finder _key(String key) => find.byKey(ValueKey(key));
final _otp = _key('auth-otp');
final _submit = _key('auth-submit');
final _back = _key('auth-otp-back');
final _resend = _key('auth-otp-resend');

String _countdown(WidgetTester tester) =>
    tester.widget<Text>(_key('auth-verification-countdown')).data!;
String _code(WidgetTester tester) =>
    tester.widget<TextFormField>(_otp).controller!.text;
bool _isSelected(WidgetTester tester, String key) => tester
    .widget<Semantics>(
      find.descendant(of: _key(key), matching: find.byType(Semantics)).first,
    )
    .properties
    .selected!;

Future<void> _enter(WidgetTester tester, String key, String value) async {
  await tester.pumpAndSettle();
  await tester.ensureVisible(_key(key));
  await tester.pumpAndSettle();
  await tester.enterText(_key(key), value);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _expire(WidgetTester tester, FakeAppClock clock) async {
  clock.advance(const Duration(seconds: 90));
  await tester.pump(const Duration(seconds: 1));
}

Future<({GoRouter router, _OtpAuth auth, FakeAppClock clock})>
_pumpVerification(
  WidgetTester tester, {
  _OtpAuth? auth,
  String email = 'customer@example.test',
  double width = 430,
  bool submitRegistration = true,
  ValueNotifier<({double scale, double keyboard})>? metrics,
}) async {
  final recording = auth ?? _OtpAuth();
  final clock = FakeAppClock(DateTime.utc(2026, 10, 11));
  final viewport = metrics ?? ValueNotifier((scale: 1.0, keyboard: 0.0));
  await tester.binding.setSurfaceSize(Size(width, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(viewport.dispose);
  final router = GoRouter(
    initialLocation: AppRoutes.register,
    routes: [
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const AuthPage(mode: AuthPageMode.register),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const AuthPage(mode: AuthPageMode.login),
      ),
      for (final path in [AppRoutes.home, AppRoutes.account])
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
        authSessionProvider.overrideWith(() => recording),
        appClockProvider.overrideWithValue(clock),
      ],
      child: MaterialApp.router(
        theme: AppTheme.dark,
        routerConfig: router,
        builder: (context, child) => ValueListenableBuilder(
          valueListenable: viewport,
          builder: (context, current, _) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(current.scale),
              viewInsets: EdgeInsets.only(bottom: current.keyboard),
            ),
            child: child!,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  for (final entry in {
    'auth-name': 'Customer',
    'auth-email': email,
    'auth-password': 'Password1!',
    'auth-phone': '0901234567',
    'auth-username': 'customer_name',
    'auth-identity-number': '001234567890',
    'auth-confirm-password': 'Password1!',
  }.entries) {
    await _enter(tester, entry.key, entry.value);
  }
  await _tap(tester, _key('auth-birth-date'));
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  final checkbox = find.byType(Checkbox);
  await _tap(tester, checkbox);
  if (submitRegistration) {
    await _tap(tester, _submit);
    expect(_otp, findsOneWidget);
  }
  return (router: router, auth: recording, clock: clock);
}

class _OtpAuth extends AuthSessionController {
  _OtpAuth({this.ttl = 90});
  final int ttl;
  int registerCalls = 0;
  int verifyCalls = 0;
  int resendCalls = 0;
  int loginCalls = 0;
  String? registrationEmail;
  String? resendEmail;
  (String, String)? verification;
  bool verifyResult = true;
  bool resendResult = true;
  String verifyError = 'Invalid OTP';
  Completer<bool>? pendingVerify;
  Completer<bool>? pendingResend;
  Completer<void>? pendingRegister;
  AuthState get currentState => state;

  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);

  @override
  Future<RegistrationResult?> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    int? birthYear,
    String? username,
    String? identityNumber,
  }) async {
    registerCalls++;
    registrationEmail = email;
    if (pendingRegister != null) await pendingRegister!.future;
    state = const AuthState(status: AuthStatus.unauthenticated);
    return RegistrationResult(
      user: RegistrationProfile(
        id: null,
        email: email,
        fullName: fullName,
        roles: const ['CUSTOMER'],
      ),
      emailVerificationRequired: true,
      emailVerificationExpiresInSeconds: ttl,
    );
  }

  @override
  Future<bool> verifyEmail({required String email, required String otp}) async {
    verifyCalls++;
    verification = (email, otp);
    final result = await (pendingVerify?.future ?? Future.value(verifyResult));
    state = result
        ? const AuthState(status: AuthStatus.unauthenticated)
        : AuthState(status: AuthStatus.unauthenticated, message: verifyError);
    return result;
  }

  @override
  Future<bool> resendVerification(String email) async {
    resendCalls++;
    resendEmail = email;
    final result = await (pendingResend?.future ?? Future.value(resendResult));
    state = result
        ? const AuthState(status: AuthStatus.unauthenticated)
        : const AuthState(
            status: AuthStatus.unauthenticated,
            message: 'Không thể gửi lại OTP. Vui lòng thử lại.',
          );
    return result;
  }

  @override
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    loginCalls++;
    return true;
  }
}
