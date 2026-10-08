import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/app/app.dart';
import 'package:mss301_mobile/core/routing/app_router.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/features/auth/application/auth_session.dart';
import 'package:mss301_mobile/features/auth/presentation/pages/auth_page.dart';
import 'package:mss301_mobile/features/home/presentation/pages/home_page.dart';
import 'package:mss301_mobile/features/orders/presentation/pages/orders_page.dart';

import 'support/fake_auth_session.dart';

void main() {
  Future<ProviderContainer> pumpApp(
    WidgetTester tester,
    AuthState initialState,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(
            () => FakeAuthSessionController(initialState),
          ),
        ],
        child: const CinePremierApp(),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(CinePremierApp)));
  }

  testWidgets('guest may open a public route', (tester) async {
    appRouter.go(AppRoutes.home);
    await pumpApp(tester, unauthenticatedState);

    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('guest is redirected from a protected route to login', (tester) async {
    appRouter.go(AppRoutes.orders);
    await pumpApp(tester, unauthenticatedState);

    expect(find.byType(AuthPage), findsOneWidget);
  });

  testWidgets('authenticated customer may open a protected route', (tester) async {
    appRouter.go(AppRoutes.orders);
    await pumpApp(tester, authenticatedCustomerState());

    expect(find.byType(OrdersPage), findsOneWidget);
  });

  testWidgets('authenticated customer is redirected away from login', (tester) async {
    appRouter.go(AppRoutes.login);
    await pumpApp(tester, authenticatedCustomerState());

    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('logout makes a protected route unavailable again', (tester) async {
    appRouter.go(AppRoutes.orders);
    final container = await pumpApp(tester, authenticatedCustomerState());

    await container.read(authSessionProvider.notifier).logout();
    appRouter.go(AppRoutes.orders);
    await tester.pumpAndSettle();

    expect(find.byType(AuthPage), findsOneWidget);
  });
}
