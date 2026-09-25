import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/app/app.dart';
import 'package:mss301_mobile/features/account/presentation/pages/account_page.dart';
import 'package:mss301_mobile/features/discover/presentation/pages/discover_page.dart';
import 'package:mss301_mobile/features/home/presentation/pages/home_page.dart';
import 'package:mss301_mobile/features/orders/presentation/pages/orders_page.dart';
import 'package:mss301_mobile/features/showtime/presentation/pages/showtimes_page.dart';
import 'package:mss301_mobile/features/showtime/presentation/widgets/date_selector.dart';
import 'package:mss301_mobile/features/movie/presentation/providers/movies_provider.dart';

void main() {
  for (final width in [360.0, 390.0, 412.0]) {
    testWidgets('home navigation at ${width.toInt()} px', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const ProviderScope(child: CinePremierApp()));
      await tester.pumpAndSettle();

      expect(find.text('Phim đang chiếu'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('hero-open-2')));
      await tester.pumpAndSettle();

      expect(find.text('Chi tiết phim'), findsOneWidget);
      expect(find.textContaining('thông tin phim cơ bản'), findsOneWidget);

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
    expect(find.textContaining('nội dung mô phỏng'), findsOneWidget);
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CineAI Central'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nguyễn Huệ'), findsOneWidget);
  });

  testWidgets('booking CTA opens movie-filtered showtimes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: CinePremierApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hero-book-2')));
    await tester.pumpAndSettle();

    expect(find.byType(ShowtimesPage), findsOneWidget);
    expect(find.text('AVENGERS: ENDGAME'), findsOneWidget);
    expect(find.text('INCEPTION'), findsNothing);
    expect(
      tester.widget<DateSelector>(find.byType(DateSelector)).selectedIndex,
      isNull,
    );
  });

  testWidgets('header actions route and preview notification is disabled', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: CinePremierApp()));
    await tester.pumpAndSettle();

    final notification = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.notifications_none),
    );
    expect(notification.onPressed, isNull);

    await tester.tap(find.byTooltip('Tìm kiếm'));
    await tester.pumpAndSettle();
    expect(find.byType(DiscoverPage), findsOneWidget);

    await tester.tap(find.byTooltip('Tài khoản'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountPage), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('header-home-logo')));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('preview quick actions are visibly disabled', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: CinePremierApp()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('bottom-nav-icon-0')).hitTestable(),
    );
    await tester.pumpAndSettle();

    final foodAction = find.byKey(const ValueKey('quick-action-Bắp & Nước'));
    expect(foodAction, findsOneWidget);
    expect(tester.widget<InkWell>(foodAction).onTap, isNull);
    expect(find.text('Sắp có'), findsNWidgets(4));
    expect(find.byType(SnackBar), findsNothing);
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

  testWidgets('R3 account and orders read backend-aligned repositories', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: CinePremierApp()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('bottom-nav-icon-3')).hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('CP-MOCK-5101'), findsOneWidget);
    expect(find.text('INCEPTION'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('bottom-nav-icon-4')).hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Minh'), findsOneWidget);
    expect(find.text('1.250'), findsOneWidget);
    expect(find.text('500.000đ'), findsOneWidget);
  });

  testWidgets('R3 repository error exposes retry state', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          moviesProvider.overrideWith(
            (ref) => throw StateError('catalog unavailable'),
          ),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đã xảy ra lỗi'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });
}
