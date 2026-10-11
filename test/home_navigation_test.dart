import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mss301_mobile/core/routing/app_router.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/features/account/presentation/pages/account_page.dart';
import 'package:mss301_mobile/features/discover/presentation/pages/discover_page.dart';
import 'package:mss301_mobile/features/home/presentation/pages/home_page.dart';
import 'package:mss301_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:mss301_mobile/features/home/presentation/widgets/home_cinemas_section.dart';
import 'package:mss301_mobile/features/home/presentation/widgets/home_quick_booking.dart';
import 'package:mss301_mobile/features/movie/presentation/pages/movie_detail_page.dart';
import 'package:mss301_mobile/features/orders/presentation/pages/orders_page.dart';
import 'package:mss301_mobile/features/showtime/presentation/pages/showtimes_page.dart';
import 'package:mss301_mobile/features/showtime/presentation/widgets/date_selector.dart';
import 'package:mss301_mobile/features/movie/presentation/providers/movies_provider.dart';

import 'support/pump_test_app.dart';

void main() {
  setUp(() => appRouter.go(AppRoutes.home));

  for (final width in [360.0, 390.0, 412.0]) {
    testWidgets('home navigation at ${width.toInt()} px', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpTestApp(tester);

      expect(find.text('PHIM ĐANG CHIẾU'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('hero-open-1')));
      await tester.pumpAndSettle();

      expect(find.byType(MovieDetailPage), findsOneWidget);
      expect(
        tester.widget<MovieDetailPage>(find.byType(MovieDetailPage)).movieId,
        1,
      );
      expect(
        GoRouterState.of(tester.element(find.byType(MovieDetailPage))).uri.path,
        AppRoutes.movieDetail(1),
      );
      expect(find.text('Thông tin phim'), findsOneWidget);
      expect(
        find.textContaining('Dữ liệu phim được tải từ CatalogRepository'),
        findsNothing,
      );

      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('PHIM ĐANG CHIẾU'), findsOneWidget);
    });
  }

  testWidgets('home cinema card opens real cinema schedule', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpTestApp(tester);

    await tester.ensureVisible(find.text('CineAI Central'));
    await tester.tap(find.text('CineAI Central'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeCinemaSchedule), findsOneWidget);
    expect(
      tester
          .widget<HomeCinemaSchedule>(find.byType(HomeCinemaSchedule))
          .cinema
          .name,
      'CineAI Central',
    );
    expect(find.text('Inception'), findsWidgets);
  });

  testWidgets('booking CTA opens movie-filtered showtimes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpTestApp(tester);

    await tester.ensureVisible(
      find.byKey(const ValueKey('now-showing-book-2')),
    );
    await tester.tap(find.byKey(const ValueKey('now-showing-book-2')));
    await tester.pumpAndSettle();

    expect(find.byType(ShowtimesPage), findsOneWidget);
    expect(tester.widget<ShowtimesPage>(find.byType(ShowtimesPage)).movieId, 2);
    expect(find.text('Avengers: Endgame'), findsOneWidget);
    expect(find.text('Inception'), findsNothing);
    expect(
      tester.widget<DateSelector>(find.byType(DateSelector)).selectedIndex,
      isNull,
    );
  });

  testWidgets(
    'compact Home header actions route without unsupported notifications',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpTestApp(tester);

      expect(
        find.widgetWithIcon(IconButton, Icons.notifications_none),
        findsNothing,
      );

      await tester.tap(find.byTooltip('Tìm kiếm'));
      await tester.pumpAndSettle();
      expect(find.byType(DiscoverPage), findsOneWidget);

      await tester.tap(find.byTooltip('Tài khoản'));
      await tester.pumpAndSettle();
      expect(find.byType(AccountPage), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('header-home-logo')));
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
    },
  );

  testWidgets('real quick booking replaces unsupported preview actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpTestApp(tester);

    await tester.tap(
      find.byKey(const ValueKey('bottom-nav-icon-0')).hitTestable(),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('quick-action-Bắp & Nước')), findsNothing);
    expect(find.byType(HomeQuickBooking), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('home-quick-buy')))
          .onPressed,
      isNull,
    );
    expect(find.byKey(const ValueKey('home-food-unavailable')), findsNothing);
    expect(find.text('BẮP NƯỚC & COMBO'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('bottom navigation tabs navigate to destinations', (
    tester,
  ) async {
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

  testWidgets('R3 account and orders read backend-aligned repositories', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpTestApp(tester);

    await tester.tap(
      find.byKey(const ValueKey('bottom-nav-icon-3')).hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('CP-MOCK-5101'), findsOneWidget);
    // History preserves the supplied booking title instead of uppercasing it.
    expect(find.text('Inception'), findsOneWidget);

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
          homeCinemasProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đã xảy ra lỗi'), findsNWidgets(3));
    expect(find.text('Thử lại'), findsNWidgets(3));
  });
}
