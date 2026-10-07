import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/app/app.dart';
import 'package:mss301_mobile/core/routing/app_router.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/features/auth/application/auth_session.dart';
import 'package:mss301_mobile/features/movie/data/repositories/catalog_providers.dart';

import 'fake_auth_session.dart';

Future<ProviderContainer> pumpTestApp(
  WidgetTester tester, {
  AuthState? authState,
  String initialLocation = AppRoutes.home,
  Size? size,
  List<dynamic> providerOverrides = const [],
}) async {
  appRouter.go(initialLocation);
  if (size != null) {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWith(
          (ref) => ref.watch(mockCatalogRepositoryProvider),
        ),
        authSessionProvider.overrideWith(
          () => FakeAuthSessionController(
            authState ?? authenticatedCustomerState(),
          ),
        ),
        ...providerOverrides,
      ],
      child: const CinePremierApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(CinePremierApp)));
}
