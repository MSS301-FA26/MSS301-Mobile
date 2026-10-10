import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/core/theme/app_theme.dart';
import 'package:mss301_mobile/features/auth/application/auth_session.dart';
import 'package:mss301_mobile/features/auth/presentation/pages/auth_page.dart';
import 'package:mss301_mobile/shared/widgets/app_button.dart';

import 'support/fake_auth_session.dart';

void main() {
  testWidgets('auth form is bounded and grouped on a tablet', (tester) async {
    await _pumpAuth(tester, _RecordingAuth(), width: 768);
    expect(find.byKey(const ValueKey('auth-form-panel')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('auth-form-panel'))).width,
      lessThanOrEqualTo(560),
    );
  });

  testWidgets('login keeps trimmed email, raw password and continue route', (
    tester,
  ) async {
    final auth = _RecordingAuth();
    final router = await _pumpAuth(
      tester,
      auth,
      location: '${AppRoutes.login}?continue=%2Forders',
    );
    await tester.enterText(_email, ' customer@example.test ');
    await tester.enterText(_password, ' password with spaces ');
    await _submit(tester);
    expect(auth.loginCalls, 1);
    expect(auth.username, 'customer@example.test');
    expect(auth.password, ' password with spaces ');
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.orders);
  });

  testWidgets('unsafe continue falls back to the existing home route', (
    tester,
  ) async {
    final router = await _pumpAuth(
      tester,
      _RecordingAuth(),
      location: '${AppRoutes.login}?continue=%2F%2Fexternal.test',
    );
    await tester.enterText(_password, 'password');
    await _submit(tester);
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.home);
  });

  testWidgets('password visibility is labeled and has a 48px target', (
    tester,
  ) async {
    await _pumpAuth(tester, _RecordingAuth());
    final visibility = find.byTooltip('Hiện mật khẩu');
    expect(tester.getSize(visibility).shortestSide, greaterThanOrEqualTo(48));
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: _password, matching: find.byType(TextField)),
          )
          .obscureText,
      isTrue,
    );
    await tester.tap(visibility);
    await tester.pump();
    expect(find.byTooltip('Ẩn mật khẩu'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: _password, matching: find.byType(TextField)),
          )
          .obscureText,
      isFalse,
    );
  });

  testWidgets('validation does not submit and remains readable at 200%', (
    tester,
  ) async {
    final auth = _RecordingAuth();
    await _pumpAuth(tester, auth, width: 320, scale: 2);
    await tester.enterText(_email, 'invalid');
    await _submit(tester);
    expect(auth.loginCalls, 0);
    expect(find.text('Email không hợp lệ'), findsOneWidget);
    expect(find.text('Mật khẩu tối thiểu 6 ký tự'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending login disables submit without a second call', (
    tester,
  ) async {
    final pending = Completer<bool>();
    final auth = _RecordingAuth()..pendingLogin = pending;
    await _pumpAuth(tester, auth);
    await tester.enterText(_password, 'password');
    await tester.ensureVisible(_submitButton);
    await tester.tap(_submitButton);
    await tester.pump();
    expect(auth.loginCalls, 1);
    expect(tester.widget<AppButton>(_submitButton).onPressed, isNull);
    await tester.tap(_submitButton);
    await tester.pump();
    expect(auth.loginCalls, 1);
    pending.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('Không thể đăng nhập. Vui lòng thử lại.'), findsOneWidget);
    expect(tester.widget<AppButton>(_submitButton).onPressed, isNotNull);
  });

  testWidgets('register preserves its existing fields and OTP transition', (
    tester,
  ) async {
    final auth = _RecordingAuth();
    final router = await _pumpAuth(tester, auth, location: AppRoutes.register);
    expect(find.byType(TextFormField), findsNWidgets(3));
    await tester.enterText(
      find.byKey(const ValueKey('auth-name')),
      ' Customer ',
    );
    await tester.enterText(_email, ' customer@example.test ');
    await tester.enterText(_password, ' password ');
    await _submit(tester);
    expect(auth.registration, (
      'Customer',
      'customer@example.test',
      ' password ',
    ));
    expect(find.text('Xác thực OTP'), findsWidgets);
    expect(find.byKey(const ValueKey('auth-otp')), findsOneWidget);
    // The existing register OTP form retains the password field.
    expect(_password, findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('auth-otp')), 'AbC123');
    await _submit(tester);
    expect(auth.verification, ('customer@example.test', 'AbC123'));
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.account);
  });

  testWidgets('failed registration remains on the existing registration form', (
    tester,
  ) async {
    final auth = _RecordingAuth()..registerResult = false;
    await _pumpAuth(tester, auth, location: AppRoutes.register);
    await tester.enterText(find.byKey(const ValueKey('auth-name')), 'Customer');
    await tester.enterText(_password, 'password');
    await _submit(tester);
    expect(find.byKey(const ValueKey('auth-otp')), findsNothing);
    expect(find.text('Không thể đăng ký. Vui lòng thử lại.'), findsOneWidget);
  });

  testWidgets('recovery preserves its existing two stages and reset mapping', (
    tester,
  ) async {
    final auth = _RecordingAuth();
    final router = await _pumpAuth(
      tester,
      auth,
      location: AppRoutes.forgotPassword,
    );
    expect(find.byType(TextFormField), findsOneWidget);
    await tester.enterText(_email, ' customer@example.test ');
    await _submit(tester);
    expect(auth.resetEmail, 'customer@example.test');
    expect(find.byType(TextFormField), findsNWidgets(2));
    await tester.enterText(find.byKey(const ValueKey('auth-otp')), '654321');
    await tester.enterText(_password, ' new password ');
    await _submit(tester);
    expect(auth.reset, ('customer@example.test', '654321', ' new password '));
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.login);
  });

  testWidgets('login secondary actions retain the existing destinations', (
    tester,
  ) async {
    final router = await _pumpAuth(tester, _RecordingAuth());
    await tester.ensureVisible(find.text('Quên mật khẩu?'));
    await tester.tap(find.text('Quên mật khẩu?'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.forgotPassword,
    );
    router.go(AppRoutes.login);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.register);
    router.go(AppRoutes.login);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tiếp tục với tư cách khách'));
    await tester.tap(find.text('Tiếp tục với tư cách khách'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.home);
  });

  for (final width in [320.0, 430.0, 768.0]) {
    for (final route in [
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.forgotPassword,
    ]) {
      testWidgets(
        '$route fits $width at 200% with keyboard and long feedback',
        (tester) async {
          final auth = _RecordingAuth(
            initialState: const AuthState(
              status: AuthStatus.unauthenticated,
              message:
                  'Không thể hoàn thành yêu cầu cho tài khoản này. '
                  'Vui lòng kiểm tra thông tin và thử lại sau.',
            ),
          );
          await _pumpAuth(
            tester,
            auth,
            location: route,
            width: width,
            scale: 2,
            keyboard: 250,
          );
          await _revealSubmit(tester);
          await tester.pumpAndSettle();
          expect(
            tester.getBottomRight(_submitButton).dy,
            lessThanOrEqualTo(650),
          );
          expect(tester.takeException(), isNull);
          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics && widget.properties.liveRegion == true,
            ),
            findsWidgets,
          );
          expect(find.textContaining('Google'), findsNothing);
          expect(find.textContaining('Thiết lập mật khẩu'), findsNothing);
        },
      );
    }
  }
}

final _email = find.byKey(const ValueKey('auth-email'));
final _password = find.byKey(const ValueKey('auth-password'));
final _submitButton = find.byKey(const ValueKey('auth-submit'));

Future<void> _submit(WidgetTester tester) async {
  await _revealSubmit(tester);
  await tester.tap(_submitButton);
  await tester.pumpAndSettle();
}

Future<void> _revealSubmit(WidgetTester tester) async {
  if (_submitButton.evaluate().isEmpty) {
    await tester.scrollUntilVisible(_submitButton, 200);
  }
  await tester.ensureVisible(_submitButton);
}

Future<GoRouter> _pumpAuth(
  WidgetTester tester,
  _RecordingAuth auth, {
  String location = AppRoutes.login,
  double width = 430,
  double scale = 1,
  double keyboard = 0,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
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
      overrides: [authSessionProvider.overrideWith(() => auth)],
      child: MaterialApp.router(
        theme: AppTheme.dark,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

class _RecordingAuth extends AuthSessionController {
  _RecordingAuth({this.initialState = unauthenticatedState});
  final AuthState initialState;
  Completer<bool>? pendingLogin;
  int loginCalls = 0;
  String? username;
  String? password;
  bool registerResult = true;
  (String, String, String)? registration;
  (String, String)? verification;
  String? resetEmail;
  (String, String, String)? reset;

  @override
  AuthState build() => initialState;

  @override
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    loginCalls++;
    this.username = username;
    this.password = password;
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      isSubmitting: true,
    );
    final success = await (pendingLogin?.future ?? Future.value(true));
    state = success
        ? authenticatedCustomerState()
        : const AuthState(
            status: AuthStatus.unauthenticated,
            message: 'Không thể đăng nhập. Vui lòng thử lại.',
          );
    return success;
  }

  @override
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    registration = (fullName, email, password);
    if (!registerResult) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        message: 'Không thể đăng ký. Vui lòng thử lại.',
      );
    }
    return registerResult;
  }

  @override
  Future<bool> verifyEmail({required String email, required String otp}) async {
    verification = (email, otp);
    return true;
  }

  @override
  Future<bool> requestPasswordReset(String email) async {
    resetEmail = email;
    return true;
  }

  @override
  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    reset = (email, otp, password);
    return true;
  }
}
