import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';

import 'support/fake_auth_session.dart';
import 'support/pump_test_app.dart';

void main() {
  testWidgets('login uses the wallet auth panel and does not offer Google sign-in', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      authState: unauthenticatedState,
      initialLocation: AppRoutes.login,
    );

    expect(find.byKey(const ValueKey('auth-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-login-tab')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-register-tab')), findsOneWidget);
    expect(find.text('Đăng nhập với Google'), findsNothing);
  });
}
