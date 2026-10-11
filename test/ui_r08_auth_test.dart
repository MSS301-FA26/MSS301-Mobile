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

import 'support/fake_auth_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
    await font.load();
  });

  for (final route in [
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.forgotPassword,
  ]) {
    testWidgets('$route displays only the CinePremier auth shell', (
      tester,
    ) async {
      await _pumpAuth(tester, _RecordingAuth(), location: route);

      expect(find.byType(AppShell), findsNothing);
      expect(find.byType(CinemaHeader), findsNothing);
      expect(find.text('CineAI Central'), findsNothing);
      expect(find.byKey(const ValueKey('header-home-logo')), findsNothing);
      expect(find.byTooltip('Tìm kiếm'), findsNothing);
      expect(find.byTooltip('Thông báo • Sắp có'), findsNothing);
      expect(find.byTooltip('Tài khoản'), findsNothing);
      expect(find.text('CINEPREMIER'), findsOneWidget);
      expect(find.byKey(const ValueKey('auth-panel')), findsOneWidget);
      expect(find.byKey(const ValueKey('auth-brand-header')), findsOneWidget);
      expect(find.byKey(const ValueKey('auth-trust-footer')), findsOneWidget);
    });
  }

  for (final width in [320.0, 430.0, 768.0]) {
    testWidgets('register uses one full-width auth panel at $width', (
      tester,
    ) async {
      await _pumpAuth(
        tester,
        _RecordingAuth(),
        location: AppRoutes.register,
        width: width,
      );

      final panel = find.byKey(const ValueKey('auth-panel'));
      final header = find.byKey(const ValueKey('auth-brand-header'));
      final footer = find.byKey(const ValueKey('auth-trust-footer'));
      final form = find.byKey(const ValueKey('auth-form-panel'));
      final panelRect = tester.getRect(panel);
      final expectedWidth = width < 592 ? width - 32 : 560.0;
      expect(panelRect.width, closeTo(expectedWidth, 1));
      expect(panelRect.center.dx, closeTo(width / 2, 1));
      expect(panelRect.top, closeTo(16, 1));
      expect(panelRect.height, greaterThan(868));

      final panelDecoration = tester.widget<Container>(panel).decoration;
      expect(panelDecoration, isA<BoxDecoration>());
      final surface = panelDecoration! as BoxDecoration;
      expect(surface.color, AppColors.surface);
      expect(surface.border, isNotNull);
      expect(surface.borderRadius, isNot(AppRadii.card));

      final headerRect = tester.getRect(header);
      expect(headerRect.height, inInclusiveRange(56, 64));
      final headerDecoration =
          tester.widget<Container>(header).decoration! as BoxDecoration;
      final headerBorder = headerDecoration.border! as Border;
      expect(headerBorder.bottom.width, greaterThan(0));
      expect(headerBorder.bottom.color, isNot(Colors.transparent));

      final formRect = tester.getRect(form);
      expect(formRect.left - panelRect.left, inInclusiveRange(16, 18));
      expect(panelRect.right - formRect.right, inInclusiveRange(16, 18));
      for (final field in [
        find.byKey(const ValueKey('auth-name')),
        find.byKey(const ValueKey('auth-birth-date')),
        find.byKey(const ValueKey('auth-phone')),
        _email,
        find.byKey(const ValueKey('auth-username')),
        find.byKey(const ValueKey('auth-identity-number')),
        _password,
        find.byKey(const ValueKey('auth-confirm-password')),
        _submitButton,
      ]) {
        final bounds = tester.getRect(field);
        expect(bounds.left, closeTo(formRect.left, 1));
        expect(bounds.right, closeTo(formRect.right, 1));
      }
      for (final field in [
        find.byKey(const ValueKey('auth-name')),
        _email,
        _password,
      ]) {
        final input = find.descendant(
          of: field,
          matching: find.byType(TextField),
        );
        expect(tester.getSize(input).height, inInclusiveRange(48, 54));
        expect(tester.widget<TextField>(input).style?.fontSize, 14);
      }
      expect(tester.getSize(_submitButton).height, inInclusiveRange(54, 58));

      final loginTab = find.byKey(const ValueKey('auth-login-tab'));
      final registerTab = find.byKey(const ValueKey('auth-register-tab'));
      final loginRect = tester.getRect(loginTab);
      final registerRect = tester.getRect(registerTab);
      expect(loginRect.height, greaterThanOrEqualTo(52));
      expect(registerRect.height, greaterThanOrEqualTo(52));
      expect(loginRect.width, closeTo(registerRect.width, 0.1));
      expect(loginRect.left, closeTo(formRect.left + 1, 1));
      expect(registerRect.right, closeTo(formRect.right - 1, 1));
      final activeLabel = tester.widget<Text>(
        find.descendant(of: registerTab, matching: find.text('ĐĂNG KÝ')),
      );
      expect(activeLabel.style?.fontSize, greaterThanOrEqualTo(13));
      expect(activeLabel.style?.color, AppColors.text);
      expect(activeLabel.style?.letterSpacing, greaterThanOrEqualTo(0.6));

      for (final label in ['HỌ VÀ TÊN', 'EMAIL', 'MẬT KHẨU']) {
        final text = tester.widget<Text>(find.text(label));
        expect(text.style?.fontSize, inInclusiveRange(11, 12));
        expect(
          text.style?.fontWeight,
          anyOf(FontWeight.w700, FontWeight.w800, FontWeight.w900),
        );
        expect(
          text.style?.color,
          anyOf(AppColors.text, AppColors.textSecondary),
        );
        expect(text.style?.letterSpacing, greaterThanOrEqualTo(1));
      }

      final footerRect = tester.getRect(footer);
      expect(footerRect.height, inInclusiveRange(52, 60));
      expect(footerRect.bottom, closeTo(panelRect.bottom, 1));
      expect(
        footerRect.top - tester.getRect(_submitButton).bottom,
        inInclusiveRange(16, 32),
      );
      final footerDecoration =
          tester.widget<Container>(footer).decoration! as BoxDecoration;
      final footerBorder = footerDecoration.border! as Border;
      expect(footerBorder.top.width, greaterThan(0));
      expect(footerBorder.top.color, isNot(Colors.transparent));
      final safeLabel = tester.getRect(find.text('AN TOÀN'));
      final clubLabel = tester.getRect(find.text('CINEPREMIER CLUB'));
      expect(safeLabel.top, greaterThanOrEqualTo(footerRect.top));
      expect(clubLabel.bottom, lessThanOrEqualTo(footerRect.bottom));
      await tester.ensureVisible(_submitButton);
      await tester.pumpAndSettle();
      expect(tester.getRect(_submitButton).bottom, lessThanOrEqualTo(900));
      await tester.ensureVisible(footer);
      await tester.pumpAndSettle();
      expect(tester.getRect(footer).bottom, lessThanOrEqualTo(900));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('auth tabs share a bottom edge at 200%', (tester) async {
    await _pumpAuth(
      tester,
      _RecordingAuth(),
      location: AppRoutes.register,
      width: 430,
      scale: 2,
    );

    final loginRect = tester.getRect(
      find.byKey(const ValueKey('auth-login-tab')),
    );
    final registerRect = tester.getRect(
      find.byKey(const ValueKey('auth-register-tab')),
    );
    expect(loginRect.height, closeTo(registerRect.height, 0.1));
    expect(loginRect.bottom, closeTo(registerRect.bottom, 0.1));
    expect(loginRect.height, greaterThanOrEqualTo(52));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'register remains usable in short landscape at 200% with keyboard',
    (tester) async {
      final auth = _RecordingAuth(
        initialState: const AuthState(
          status: AuthStatus.unauthenticated,
          message:
              'Không thể hoàn thành yêu cầu. Vui lòng kiểm tra thông tin tài khoản '
              'và thử lại sau khi kết nối được khôi phục.',
        ),
      );
      await _pumpAuth(
        tester,
        auth,
        location: AppRoutes.register,
        width: 768,
        height: 430,
        scale: 2,
        keyboard: 160,
      );
      for (final input in [
        (key: 'auth-name', value: ''),
        (key: 'auth-email', value: 'invalid'),
        (key: 'auth-password', value: 'short'),
      ]) {
        final field = find.byKey(ValueKey(input.key));
        await tester.pumpAndSettle();
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        expect(tester.getRect(field).bottom, lessThanOrEqualTo(270));
        await tester.enterText(field, input.value);
      }
      await _submit(tester);
      expect(auth.registerCalls, 0);
      expect(find.text('Vui lòng nhập họ tên'), findsOneWidget);
      expect(find.text('Email không hợp lệ'), findsOneWidget);
      expect(_fieldHasError(tester, 'auth-password'), isTrue);
      await _revealSubmit(tester);
      expect(tester.getRect(_submitButton).bottom, lessThanOrEqualTo(270));
      await tester.ensureVisible(find.text('CINEPREMIER CLUB'));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.text('CINEPREMIER CLUB')).bottom,
        lessThanOrEqualTo(270),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('auth form is bounded and grouped on a tablet', (tester) async {
    await _pumpAuth(tester, _RecordingAuth(), width: 768);
    expect(find.byKey(const ValueKey('auth-form-panel')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('auth-form-panel'))).width,
      lessThanOrEqualTo(560),
    );
  });

  testWidgets('login maps the CinePremier brand, tabs and trust row', (
    tester,
  ) async {
    await _pumpAuth(tester, _RecordingAuth());

    expect(find.text('CINEPREMIER'), findsOneWidget);
    expect(find.text('ĐĂNG NHẬP'), findsNWidgets(2));
    expect(find.text('ĐĂNG KÝ'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-login-tab')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-register-tab')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth-google-login')),
      findsOneWidget,
    );
    expect(find.text('AN TOÀN'), findsOneWidget);
    expect(find.text('CINEPREMIER CLUB'), findsOneWidget);
  });

  testWidgets('login register tab keeps the existing register navigation', (
    tester,
  ) async {
    final router = await _pumpAuth(tester, _RecordingAuth());

    await tester.tap(find.byKey(const ValueKey('auth-register-tab')));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.register);
  });

  testWidgets('auth forms do not prefill a demo email', (tester) async {
    await _pumpAuth(tester, _RecordingAuth());
    expect(tester.widget<TextFormField>(_email).controller!.text, isEmpty);
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
    await tester.enterText(_email, 'customer@example.test');
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
    await tester.enterText(_email, 'customer@example.test');
    await tester.enterText(_password, 'password');
    await tester.ensureVisible(_submitButton);
    await tester.tap(_submitButton);
    await tester.pump();
    expect(auth.loginCalls, 1);
    expect(tester.widget<FilledButton>(_submitButton).onPressed, isNull);
    await tester.tap(_submitButton);
    await tester.pump();
    expect(auth.loginCalls, 1);
    pending.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('Không thể đăng nhập. Vui lòng thử lại.'), findsOneWidget);
    expect(tester.widget<FilledButton>(_submitButton).onPressed, isNotNull);
  });

  testWidgets('register preserves its existing fields and OTP transition', (
    tester,
  ) async {
    final auth = _RecordingAuth();
    final router = await _pumpAuth(tester, auth, location: AppRoutes.register);
    expect(find.byType(TextFormField), findsNWidgets(8));
    await _fillRegisterExtras(tester, password: ' Password1! ');
    await tester.enterText(
      find.byKey(const ValueKey('auth-name')),
      ' Customer ',
    );
    await tester.enterText(_email, ' customer@example.test ');
    await _enterAuthText(tester, 'auth-password', ' Password1! ');
    await _submit(tester);
    expect(auth.registration, (
      'Customer',
      'customer@example.test',
      ' Password1! ',
    ));
    expect(find.text('XÁC THỰC EMAIL'), findsWidgets);
    expect(find.byKey(const ValueKey('auth-otp')), findsOneWidget);
    expect(_password, findsNothing);
    await tester.enterText(find.byKey(const ValueKey('auth-otp')), '012345');
    await _submit(tester);
    expect(auth.verification, ('customer@example.test', '012345'));
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.account);
  });

  testWidgets('register maps the Web hierarchy, required inputs and gold CTA', (
    tester,
  ) async {
    await _pumpAuth(tester, _RecordingAuth(), location: AppRoutes.register);

    final registerTab = find.byKey(const ValueKey('auth-register-tab'));
    final loginTab = find.byKey(const ValueKey('auth-login-tab'));
    expect(registerTab, findsOneWidget);
    expect(loginTab, findsOneWidget);
    expect(
      tester
          .widget<Semantics>(
            find
                .descendant(of: registerTab, matching: find.byType(Semantics))
                .first,
          )
          .properties
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<Semantics>(
            find
                .descendant(of: loginTab, matching: find.byType(Semantics))
                .first,
          )
          .properties
          .selected,
      isFalse,
    );
    expect(find.text('CINEPREMIER'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(8));
    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.text('Tạo tài khoản'), findsNothing);
    expect(find.text('Về đăng nhập'), findsNothing);
    expect(find.text('*'), findsNWidgets(8));
    for (final star in tester.widgetList<Text>(find.text('*'))) {
      expect(star.style?.color, AppColors.gold);
    }
    for (final label in ['HỌ VÀ TÊN', 'EMAIL', 'MẬT KHẨU']) {
      expect(find.text(label), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == '$label, bắt buộc',
        ),
        findsOneWidget,
      );
    }
    for (final key in ['auth-name', 'auth-email', 'auth-password']) {
      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(TextField),
        ),
      );
      expect(field.decoration?.prefixIcon, isNotNull);
      expect(field.decoration?.filled, isTrue);
      expect(field.decoration?.fillColor, AppColors.surface);
      expect(field.decoration?.prefixIconColor, AppColors.textMuted);
      expect(field.style?.color, AppColors.text);
      final border = field.decoration!.enabledBorder! as OutlineInputBorder;
      expect(border.borderSide.color, AppColors.borderStrong);
      expect(border.borderSide.width, 1);
      expect(border.borderRadius, BorderRadius.zero);
      final focus = field.decoration!.focusedBorder! as OutlineInputBorder;
      expect(focus.borderSide.color, AppColors.gold);
      expect(focus.borderSide.width, 1.5);
    }
    final button = tester.widget<FilledButton>(_submitButton);
    expect(button.style?.backgroundColor?.resolve({}), AppColors.gold);
    expect(button.style?.foregroundColor?.resolve({}), AppColors.background);
    expect(button.style?.textStyle?.resolve({})?.fontWeight, FontWeight.w800);
    expect(button.style?.textStyle?.resolve({})?.fontFamily, 'Inter');
    expect(
      (button.style?.shape?.resolve(
        {},
      ) as RoundedRectangleBorder?)?.borderRadius,
      BorderRadius.zero,
    );
    expect(
      find.descendant(of: _submitButton, matching: find.text('ĐĂNG KÝ')),
      findsOneWidget,
    );
    expect(tester.getSize(_submitButton).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(registerTab).width, tester.getSize(loginTab).width);
    expect(
      find.descendant(
        of: _submitButton,
        matching: find.byIcon(Icons.arrow_forward_rounded),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('auth-google-login')), findsNothing);
    expect(find.text('AN TOÀN'), findsOneWidget);
    expect(find.text('CINEPREMIER CLUB'), findsOneWidget);
  });

  testWidgets('register password visibility preserves raw input and target', (
    tester,
  ) async {
    await _pumpAuth(tester, _RecordingAuth(), location: AppRoutes.register);
    await tester.enterText(_password, ' password with spaces ');
    TextField passwordField() => tester.widget<TextField>(
      find.descendant(of: _password, matching: find.byType(TextField)),
    );
    expect(passwordField().obscureText, isTrue);
    final toggle = find.descendant(
      of: _password,
      matching: find.byTooltip('Hiện mật khẩu'),
    );
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    expect(tester.getSize(toggle).shortestSide, greaterThanOrEqualTo(48));
    await tester.tap(toggle);
    await tester.pump();
    expect(passwordField().obscureText, isFalse);
    expect(passwordField().controller!.text, ' password with spaces ');
    await tester.tap(
      find.descendant(of: _password, matching: find.byTooltip('Ẩn mật khẩu')),
    );
    await tester.pump();
    expect(passwordField().obscureText, isTrue);
    expect(passwordField().controller!.text, ' password with spaces ');
  });

  testWidgets('register validation still blocks its current callback', (
    tester,
  ) async {
    final auth = _RecordingAuth();
    await _pumpAuth(tester, auth, location: AppRoutes.register);
    await _enterAuthText(tester, 'auth-name', '');
    await tester.enterText(_email, 'invalid');
    await tester.enterText(_password, 'short');
    await _submit(tester);
    expect(auth.registerCalls, 0);
    expect(find.text('Vui lòng nhập họ tên'), findsOneWidget);
    expect(find.text('Email không hợp lệ'), findsOneWidget);
    expect(_fieldHasError(tester, 'auth-password'), isTrue);
  });

  testWidgets('register name advances keyboard focus to the next field', (
    tester,
  ) async {
    await _pumpAuth(tester, _RecordingAuth(), location: AppRoutes.register);
    final name = find.byKey(const ValueKey('auth-name'));
    await tester.tap(name);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    final nextInput = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('auth-birth-date')),
        matching: find.byType(EditableText),
      ),
    );
    expect(nextInput.focusNode.hasFocus, isTrue);
  });

  testWidgets('pending register disables submit and prevents a duplicate', (
    tester,
  ) async {
    final pending = Completer<bool>();
    final auth = _RecordingAuth()..pendingRegister = pending;
    await _pumpAuth(tester, auth, location: AppRoutes.register);
    await _fillRegister(tester);
    await _revealSubmit(tester);
    await tester.tap(_submitButton);
    await tester.pump();
    expect(auth.registerCalls, 1);
    expect(tester.widget<FilledButton>(_submitButton).onPressed, isNull);
    await tester.tap(_submitButton);
    await tester.pump();
    expect(auth.registerCalls, 1);
    pending.complete(true);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('auth-otp')), findsOneWidget);
  });

  testWidgets('register OTP keeps one input and rejects an invalid code', (
    tester,
  ) async {
    final auth = _RecordingAuth();
    await _pumpAuth(tester, auth, location: AppRoutes.register);
    await _fillRegister(tester);
    await _submit(tester);

    expect(find.text('MÃ OTP EMAIL'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-otp')), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(_password, findsNothing);
    expect(find.text('*'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(_submitButton)
          .style
          ?.backgroundColor
          ?.resolve({}),
      AppColors.gold,
    );
    expect(find.byKey(const ValueKey('auth-otp-resend')), findsOneWidget);
    expect(find.text('0/6'), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('auth-otp')), 'AbC123');
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('auth-otp')))
          .controller!
          .text,
      '123',
    );
    await tester.enterText(find.byKey(const ValueKey('auth-otp')), '12');
    await _submit(tester);
    expect(auth.verification, isNull);
    expect(find.text('OTP gồm 6 chữ số'), findsOneWidget);
  });

  testWidgets('register login tab navigates and OTP back returns to its form', (
    tester,
  ) async {
    final router = await _pumpAuth(
      tester,
      _RecordingAuth(),
      location: AppRoutes.register,
    );
    await tester.tap(find.byKey(const ValueKey('auth-login-tab')));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.login);

    router.go(AppRoutes.register);
    await tester.pumpAndSettle();
    await _fillRegister(tester);
    await _submit(tester);
    final back = find.byKey(const ValueKey('auth-otp-back'));
    await tester.ensureVisible(back);
    expect(tester.getSize(back).height, greaterThanOrEqualTo(48));
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.register);
    expect(find.byKey(const ValueKey('auth-otp')), findsNothing);
    expect(
      tester.widget<TextFormField>(_email).controller!.text,
      'customer@example.test',
    );
  });

  testWidgets('failed registration remains on the existing registration form', (
    tester,
  ) async {
    final auth = _RecordingAuth()..registerResult = false;
    await _pumpAuth(tester, auth, location: AppRoutes.register);
    await _fillRegister(tester);
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

  testWidgets('recovery uses the auth shell and returns to login', (
    tester,
  ) async {
    final router = await _pumpAuth(
      tester,
      _RecordingAuth(),
      location: AppRoutes.forgotPassword,
    );
    expect(find.text('CINEPREMIER'), findsOneWidget);
    expect(find.text('KHÔI PHỤC MẬT KHẨU'), findsOneWidget);
    expect(find.text('ĐỊA CHỈ EMAIL'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-google-login')), findsNothing);
    await tester.ensureVisible(find.text('Về đăng nhập'));
    await tester.tap(find.text('Về đăng nhập'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.login);
  });

  testWidgets('pending recovery request prevents a duplicate', (tester) async {
    final pending = Completer<bool>();
    final auth = _RecordingAuth()..pendingResetRequest = pending;
    await _pumpAuth(tester, auth, location: AppRoutes.forgotPassword);
    await tester.enterText(_email, 'customer@example.test');
    await _revealSubmit(tester);
    await tester.tap(_submitButton);
    await tester.pump();
    expect(auth.resetRequestCalls, 1);
    expect(tester.widget<FilledButton>(_submitButton).onPressed, isNull);
    await tester.tap(_submitButton);
    await tester.pump();
    expect(auth.resetRequestCalls, 1);
    pending.complete(true);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('auth-otp')), findsOneWidget);
  });

  testWidgets('reset step keeps OTP and new password with error feedback', (
    tester,
  ) async {
    final auth = _RecordingAuth()..resetResult = false;
    final router = await _pumpAuth(
      tester,
      auth,
      location: AppRoutes.forgotPassword,
    );
    await tester.enterText(_email, 'customer@example.test');
    await _submit(tester);
    expect(find.text('MÃ OTP'), findsOneWidget);
    expect(find.text('MẬT KHẨU MỚI'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    await tester.enterText(find.byKey(const ValueKey('auth-otp')), '123456');
    await tester.enterText(_password, 'short');
    await _submit(tester);
    expect(auth.reset, isNull);
    expect(find.text('Mật khẩu tối thiểu 6 ký tự'), findsOneWidget);
    await tester.enterText(_password, 'new password');
    await _submit(tester);
    expect(auth.reset, ('customer@example.test', '123456', 'new password'));
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.forgotPassword,
    );
    expect(find.text('Không thể đặt lại mật khẩu.'), findsOneWidget);
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
    await tester.ensureVisible(find.text('Đăng Ký Ngay'));
    await tester.tap(find.text('Đăng Ký Ngay'));
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
          if (route == AppRoutes.register) {
            for (final input in [
              (key: 'auth-name', value: ''),
              (key: 'auth-email', value: 'invalid'),
              (key: 'auth-password', value: 'short'),
            ]) {
              final field = find.byKey(ValueKey(input.key));
              await tester.pumpAndSettle();
              await tester.ensureVisible(field);
              await tester.pumpAndSettle();
              expect(tester.getRect(field).bottom, lessThanOrEqualTo(650));
              await tester.enterText(field, input.value);
            }
            await _submit(tester);
            expect(auth.registerCalls, 0);
            expect(find.text('Vui lòng nhập họ tên'), findsOneWidget);
            expect(find.text('Email không hợp lệ'), findsOneWidget);
            expect(_fieldHasError(tester, 'auth-password'), isTrue);
          }
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
          expect(
            find.byKey(const ValueKey('auth-google-login')),
            route == AppRoutes.login ? findsOneWidget : findsNothing,
          );
          expect(find.textContaining('Thiết lập mật khẩu'), findsNothing);
          if (route == AppRoutes.register) {
            await tester.ensureVisible(find.text('CINEPREMIER CLUB'));
            await tester.pumpAndSettle();
            for (final label in ['AN TOÀN', 'CINEPREMIER CLUB']) {
              final bounds = tester.getRect(find.text(label));
              expect(bounds.left, greaterThanOrEqualTo(0));
              expect(bounds.right, lessThanOrEqualTo(width));
              expect(bounds.bottom, lessThanOrEqualTo(650));
            }
            expect(tester.takeException(), isNull);
          }
        },
      );
    }

    for (final route in [AppRoutes.register, AppRoutes.forgotPassword]) {
      testWidgets('$route follow-up fits $width at 200% with keyboard', (
        tester,
      ) async {
        final viewport = ValueNotifier((scale: 1.0, keyboard: 0.0));
        await _pumpAuth(
          tester,
          _RecordingAuth(),
          location: route,
          width: width,
          viewport: viewport,
        );
        if (route == AppRoutes.register) {
          await _fillRegister(tester);
        } else {
          await tester.enterText(_email, 'customer@example.test');
        }
        await _submit(tester);
        expect(find.byKey(const ValueKey('auth-otp')), findsOneWidget);
        viewport.value = (scale: 2.0, keyboard: 250.0);
        await tester.pumpAndSettle();
        await _revealSubmit(tester);
        await tester.pumpAndSettle();
        expect(tester.getBottomRight(_submitButton).dy, lessThanOrEqualTo(650));
        expect(tester.takeException(), isNull);
      });
    }
  }
}

final _email = find.byKey(const ValueKey('auth-email'));
final _password = find.byKey(const ValueKey('auth-password'));
final _submitButton = find.byKey(const ValueKey('auth-submit'));

bool _fieldHasError(WidgetTester tester, String key) =>
    tester.state<FormFieldState>(find.byKey(ValueKey(key))).hasError;

Future<void> _enterAuthText(
  WidgetTester tester,
  String key,
  String value,
) async {
  await tester.pumpAndSettle();
  final field = find.byKey(ValueKey(key));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, value);
  await tester.pump();
}

Future<void> _chooseBirthDate(WidgetTester tester) async {
  await tester.pumpAndSettle();
  final field = find.byKey(const ValueKey('auth-birth-date'));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Future<void> _setConsent(WidgetTester tester, bool value) async {
  await tester.pumpAndSettle();
  final consent = find.byKey(const ValueKey('auth-consent'));
  final checkbox = find.descendant(
    of: consent,
    matching: find.byType(Checkbox),
  );
  await tester.ensureVisible(checkbox);
  await tester.pumpAndSettle();
  if (tester.widget<Checkbox>(checkbox).value != value) {
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
  }
}

Future<void> _fillRegisterExtras(
  WidgetTester tester, {
  String password = 'Password1!',
  bool consent = true,
}) async {
  await _chooseBirthDate(tester);
  await _enterAuthText(tester, 'auth-phone', '0901234567');
  await _enterAuthText(tester, 'auth-username', 'customer_name');
  await _enterAuthText(tester, 'auth-identity-number', '001234567890');
  await _enterAuthText(tester, 'auth-confirm-password', password);
  await _setConsent(tester, consent);
}

Future<void> _fillRegister(
  WidgetTester tester, {
  String name = 'Customer',
  String email = 'customer@example.test',
  String password = 'Password1!',
  bool consent = true,
}) async {
  await _enterAuthText(tester, 'auth-name', name);
  await _enterAuthText(tester, 'auth-email', email);
  await _enterAuthText(tester, 'auth-password', password);
  await _fillRegisterExtras(tester, password: password, consent: consent);
}

Future<void> _submit(WidgetTester tester) async {
  await _revealSubmit(tester);
  await tester.tap(_submitButton);
  await tester.pumpAndSettle();
}

Future<void> _revealSubmit(WidgetTester tester) async {
  await tester.pumpAndSettle();
  for (
    var attempt = 0;
    attempt < 8 && _submitButton.evaluate().isEmpty;
    attempt++
  ) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pump();
  }
  await tester.ensureVisible(_submitButton);
  await tester.pumpAndSettle();
}

Future<GoRouter> _pumpAuth(
  WidgetTester tester,
  _RecordingAuth auth, {
  String location = AppRoutes.login,
  double width = 430,
  double height = 900,
  double scale = 1,
  double keyboard = 0,
  AppClock? clock,
  bool settle = true,
  ValueNotifier<({double scale, double keyboard})>? viewport,
}) async {
  await tester.binding.setSurfaceSize(Size(width, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final metrics = viewport ?? ValueNotifier((scale: scale, keyboard: keyboard));
  addTearDown(metrics.dispose);
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
        authSessionProvider.overrideWith(() => auth),
        appClockProvider.overrideWithValue(
          clock ?? FakeAppClock(DateTime.utc(2026, 10, 10)),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.dark,
        routerConfig: router,
        builder: (context, child) => ValueListenableBuilder(
          valueListenable: metrics,
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
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return router;
}

class _RecordingAuth extends AuthSessionController {
  _RecordingAuth({this.initialState = unauthenticatedState});
  final AuthState initialState;
  Completer<bool>? pendingLogin;
  Completer<bool>? pendingRegister;
  Completer<bool>? pendingResetRequest;
  int loginCalls = 0;
  int registerCalls = 0;
  int resetRequestCalls = 0;
  String? username;
  String? password;
  bool registerResult = true;
  bool resetResult = true;
  (String, String, String)? registration;
  Map<String, Object?>? registrationExtras;
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
    registration = (fullName, email, password);
    registrationExtras = {
      'phone': phone,
      'birthYear': birthYear,
      'username': username,
      'identityNumber': identityNumber,
    };
    final success =
        await (pendingRegister?.future ?? Future.value(registerResult));
    if (!success) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        message: 'Không thể đăng ký. Vui lòng thử lại.',
      );
      return null;
    }
    return RegistrationResult(
      user: RegistrationProfile(
        id: null,
        email: email,
        fullName: fullName,
        roles: const ['CUSTOMER'],
      ),
      emailVerificationRequired: true,
      emailVerificationExpiresInSeconds: 90,
    );
  }

  @override
  Future<bool> verifyEmail({required String email, required String otp}) async {
    verification = (email, otp);
    return true;
  }

  @override
  Future<bool> requestPasswordReset(String email) async {
    resetRequestCalls++;
    resetEmail = email;
    return pendingResetRequest?.future ?? true;
  }

  @override
  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    reset = (email, otp, password);
    if (!resetResult) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        message: 'Không thể đặt lại mật khẩu.',
      );
    }
    return resetResult;
  }
}
