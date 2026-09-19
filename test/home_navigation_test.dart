import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/app/app.dart';
import 'package:mss301_mobile/features/account/presentation/pages/account_page.dart';
import 'package:mss301_mobile/features/discover/presentation/pages/discover_page.dart';
import 'package:mss301_mobile/features/home/presentation/pages/home_page.dart';
import 'package:mss301_mobile/features/orders/presentation/pages/orders_page.dart';
import 'package:mss301_mobile/features/showtime/presentation/pages/showtimes_page.dart';

void main() {
  for (final width in [360.0, 390.0, 412.0]) {
    testWidgets('home navigation at ${width.toInt()} px', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const ProviderScope(child: CinePremierApp()));
      await tester.pumpAndSettle();

      expect(find.text('Phim đang chiếu'), findsOneWidget);
      await tester.tap(find.text('Đặt vé ngay'));
      await tester.pumpAndSettle();

      expect(find.text('Chi tiết phim'), findsOneWidget);
      expect(find.textContaining('Thông tin đầy đủ và đặt vé'), findsOneWidget);

      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Phim đang chiếu'), findsOneWidget);
    });
  }

  testWidgets('home preview and cinema information open', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: CinePremierApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Xem trailer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Trailer sẽ được cập nhật'), findsOneWidget);
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CineAI Central'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nguyễn Huệ'), findsOneWidget);
  });

  testWidgets('bottom navigation tabs navigate to destinations', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: CinePremierApp()));
    await tester.pumpAndSettle();

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
