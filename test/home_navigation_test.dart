import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/routing/app_router.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/features/account/presentation/pages/account_page.dart';
import 'package:mss301_mobile/features/discover/presentation/pages/discover_page.dart';
import 'package:mss301_mobile/features/home/presentation/pages/home_page.dart';
import 'package:mss301_mobile/features/orders/presentation/pages/orders_page.dart';
import 'package:mss301_mobile/features/showtime/presentation/pages/showtimes_page.dart';

import 'support/pump_test_app.dart';

void main() {
  setUp(() => appRouter.go(AppRoutes.home));

  for (final width in [360.0, 390.0, 412.0]) {
    testWidgets('wallet Home renders at ${width.toInt()} px', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpTestApp(tester);

      expect(find.text('MUA VÉ NHANH'), findsNWidgets(2));
      expect(find.text('PHIM ĐANG CHIẾU'), findsOneWidget);
      expect(find.text('PHIM SẮP CHIẾU'), findsOneWidget);
      expect(find.text('RẠP CINEPREMIER'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('bottom navigation tabs navigate to destinations', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpTestApp(tester);
    final tabPages = [DiscoverPage, ShowtimesPage, OrdersPage, AccountPage];

    for (var i = 1; i < 5; i++) {
      await tester.tap(
        find.byKey(ValueKey('bottom-nav-icon-$i')).hitTestable(),
      );
      await tester.pumpAndSettle();
      expect(find.byType(tabPages[i - 1]), findsOneWidget);
    }

    await tester.tap(
      find.byKey(const ValueKey('bottom-nav-icon-0')).hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
  });
}
