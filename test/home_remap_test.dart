import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/money/vnd_money.dart';
import 'package:mss301_mobile/core/theme/app_theme.dart';
import 'package:mss301_mobile/core/time/app_clock.dart';
import 'package:mss301_mobile/core/routing/app_router.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/features/auth/application/auth_session.dart';
import 'package:mss301_mobile/features/home/presentation/pages/home_page.dart';
import 'package:mss301_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:mss301_mobile/features/home/presentation/widgets/home_hero_carousel.dart';
import 'package:mss301_mobile/features/home/presentation/widgets/home_movie_carousel.dart';
import 'package:mss301_mobile/features/home/presentation/widgets/home_quick_booking.dart';
import 'package:mss301_mobile/features/home/presentation/widgets/home_section_heading.dart';
import 'package:mss301_mobile/shared/widgets/cinema_bottom_nav.dart';
import 'package:mss301_mobile/shared/widgets/cinema_header.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';
import 'package:mss301_mobile/features/movie/data/models/cinema_dto.dart';
import 'package:mss301_mobile/features/movie/data/models/movie_dto.dart';
import 'package:mss301_mobile/features/movie/data/repositories/catalog_providers.dart';
import 'package:mss301_mobile/features/movie/presentation/models/movie.dart';
import 'package:mss301_mobile/features/movie/presentation/pages/movie_detail_page.dart';
import 'package:mss301_mobile/features/movie/presentation/providers/movies_provider.dart';
import 'package:mss301_mobile/features/seat/presentation/pages/seat_selection_page.dart';
import 'package:mss301_mobile/features/showtime/presentation/models/showtime_models.dart';
import 'package:mss301_mobile/features/showtime/presentation/providers/showtimes_provider.dart';

import 'support/pump_test_app.dart';
import 'support/fake_auth_session.dart';

void main() {
  testWidgets('Home follows the current Web section hierarchy', (tester) async {
    await pumpTestApp(tester, size: const Size(430, 900));
    for (final label in [
      'CINEPREMIER',
      'MUA VÉ NHANH',
      'PHÒNG VÉ CINEPREMIER',
      'PHIM ĐANG CHIẾU',
      'SẮP KHỞI CHIẾU',
      'PHIM SẮP CHIẾU',
      'KHÔNG GIAN ĐIỆN ẢNH',
      'RẠP CINEPREMIER',
    ]) {
      expect(
        find.text(label),
        label == 'MUA VÉ NHANH' ? findsNWidgets(2) : findsOneWidget,
        reason: label,
      );
    }
    expect(find.textContaining('Watchlist'), findsNothing);
    expect(find.textContaining('Rạp yêu thích'), findsNothing);
    expect(find.text('PopBot AI'), findsNothing);
    expect(find.text('Ưu đãi VIP'), findsNothing);
    expect(find.byKey(const ValueKey('hero-open-1')), findsOneWidget);
    expect(find.byType(HomePage), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(HomeSectionHeading),
        matching: find.byType(FilledButton),
      ),
      findsNothing,
    );
    final buy = tester.widget<FilledButton>(
      find.byKey(const ValueKey('home-quick-buy')),
    );
    expect(buy.onPressed, isNull);
    final carousels = tester
        .widgetList<HomeMovieCarousel>(find.byType(HomeMovieCarousel))
        .toList();
    expect(carousels[0].movies.every((m) => m.isNowShowing), isTrue);
    expect(carousels[1].movies.every((m) => m.isComingSoon), isTrue);
    expect(find.byKey(const ValueKey('home-food-unavailable')), findsNothing);
    expect(find.text('BẮP NƯỚC & COMBO'), findsNothing);
    expect(find.text('Danh mục bắp nước chưa được hỗ trợ'), findsNothing);
    expect(find.text('ĐẶT BẮP NƯỚC'), findsNothing);
    expect(find.text('Chọn'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 430.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Home fits $width px at $scale text scale', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _open(tester, width: width);
        expect(find.byType(HomeHeroCarousel), findsOneWidget);
        expect(
          tester.getSize(find.byType(HomeHeroCarousel)).height,
          closeTo(
            width >= 600 ? width / 2.8 : (width * .46).clamp(180, 210),
            .01,
          ),
        );
        expect(find.text('PHIM ĐANG CHIẾU'), findsOneWidget);
        expect(find.text('PHIM SẮP CHIẾU'), findsOneWidget);
        expect(find.text('RẠP CINEPREMIER'), findsOneWidget);
        expect(find.text(_longTitle), findsWidgets);
        await tester.ensureVisible(
          find.byKey(const ValueKey('home-cinema-801')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('home-cinema-801')).hitTestable(),
          findsOneWidget,
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('home-cinema-802')),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.byKey(const ValueKey('home-cinema-802'))).bottom,
          lessThanOrEqualTo(tester.getRect(find.byType(CinemaBottomNav)).top),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('compact dark Quick Booking keeps four 48px selector rows', (
    tester,
  ) async {
    await _open(tester);
    for (var step = 1; step <= 4; step++) {
      expect(
        tester.getSize(find.byKey(ValueKey('home-quick-step-$step'))).height,
        48,
      );
    }
    final card = tester.widget<Material>(
      find.byKey(const ValueKey('home-quick-card')),
    );
    expect(card.color, AppColors.surface);
    expect(tester.getSize(find.byType(HomeQuickBooking)).height, lessThan(300));
    expect(_buy(tester).onPressed, isNull);
    // Real selector values and dependency behavior are covered below.
  });

  testWidgets(
    'compact Home header reserves 56px without changing other headers',
    (tester) async {
      await _open(tester);
      final header = tester.widget<CinemaHeader>(find.byType(CinemaHeader));
      expect(header.compact, isTrue);
      expect(header.preferredSize.height, 56);
      expect(
        const CinemaHeader(
          onHome: _noop,
          onSearch: _noop,
          onAccount: _noop,
        ).preferredSize.height,
        AppSpacing.headerHeight,
      );
    },
  );

  testWidgets(
    'movie cards show two readable titles lines and one metadata row',
    (tester) async {
      await _open(tester);
      final title = tester.widget<Text>(find.text(_longTitle).last);
      expect(title.maxLines, 2);
      expect(title.overflow, TextOverflow.ellipsis);
      expect(title.style!.fontSize, greaterThanOrEqualTo(15));
      final metadata = tester.widget<Text>(
        find.text('Hành động • 123 phút').first,
      );
      expect(metadata.maxLines, 1);
      expect(find.text('Khởi chiếu 10/11/2026'), findsOneWidget);
      final poster = tester.getSize(
        find.byKey(const ValueKey('home-movie-701')),
      );
      expect(poster.width / poster.height, closeTo(2 / 3, .01));
      // Two full posters and a peek of the next at ordinary phone font size.
      expect((430 - 16) / (poster.width + 12), closeTo(2.2, .05));
    },
  );

  for (final entry in [
    ('PHIM ĐANG CHIẾU', AppRoutes.discover),
    ('PHIM SẮP CHIẾU', AppRoutes.discover),
    ('RẠP CINEPREMIER', AppRoutes.showtimes),
  ]) {
    testWidgets('${entry.$1} compact see-all action uses existing route', (
      tester,
    ) async {
      await _open(tester);
      final action = find.byKey(ValueKey('home-section-action-${entry.$1}'));
      expect(tester.widget<TextButton>(action).onPressed, isNotNull);
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(appRouter.routeInformationProvider.value.uri.path, entry.$2);
    });
  }

  testWidgets(
    'cinema chips scroll horizontally and preview limits after filtering',
    (tester) async {
      final cinemas = [
        ..._cinemas,
        for (var id = 803; id <= 808; id++)
          CinemaDto(
            id: id,
            name: 'Rạp $id',
            address: 'Địa chỉ dài từ contract $id',
            city: 'Thành phố $id',
            active: id != 808,
          ),
      ];
      await _open(tester, width: 320, cinemas: () => cinemas);
      expect(find.byKey(const ValueKey('home-cinema-801')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-cinema-803')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-cinema-804')), findsNothing);
      final strip = find.byKey(const ValueKey('home-cinema-filters'));
      await tester.ensureVisible(strip);
      await tester.pumpAndSettle();
      final chips = find.descendant(
        of: strip,
        matching: find.byType(ChoiceChip),
      );
      final tops = tester
          .elementList(chips)
          .map((e) => tester.getRect(find.byWidget(e.widget)).top)
          .toSet();
      expect(tops.length, 1);
      for (final chip in tester.elementList(chips)) {
        expect(
          tester.getSize(find.byWidget(chip.widget)).height,
          greaterThanOrEqualTo(48),
        );
        expect((chip.widget as ChoiceChip).labelStyle!.fontFamily, 'Inter');
      }
      final lastCity = find.widgetWithText(ChoiceChip, 'Thành phố 807');
      await tester.ensureVisible(lastCity);
      await tester.pumpAndSettle();
      await tester.tap(lastCity);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-cinema-807')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-cinema-801')), findsNothing);
      expect(find.text('Thành phố 808'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Home scroll ends with cinema action safely above bottom navigation',
    (tester) async {
      await _open(tester, width: 320);
      final scrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const ValueKey('home-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pumpAndSettle();
      final last = find.byKey(const ValueKey('home-cinema-802'));
      expect(
        tester.getRect(last).bottom,
        lessThan(tester.getRect(find.byType(CinemaBottomNav)).top),
      );
      expect(last.hitTestable(), findsOneWidget);
      expect(find.text('BẮP NƯỚC & COMBO'), findsNothing);
      expect(find.textContaining('chưa được hỗ trợ'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('four real selectors pass the exact showtime ID', (tester) async {
    await _open(tester);
    expect(_step(tester, 2).onTap, isNull);
    expect(_step(tester, 3).onTap, isNull);
    expect(_step(tester, 4).onTap, isNull);
    await _choose(tester, 1, 701);
    expect(_step(tester, 2).onTap, isNotNull);
    await _choose(tester, 2, 801);
    await _choose(tester, 3, DateTime(2026, 11, 3));
    await _choose(tester, 4, 901);
    expect(_buy(tester).onPressed, isNotNull);
    await tester.ensureVisible(find.byKey(const ValueKey('home-quick-buy')));
    await tester.tap(find.byKey(const ValueKey('home-quick-buy')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SeatSelectionPage>(find.byType(SeatSelectionPage))
          .showtimeId,
      901,
    );
  });

  testWidgets('guest Quick Booking keeps the existing login continuation', (
    tester,
  ) async {
    final container = await _open(tester, guest: true);
    await _choose(tester, 1, 701);
    await _choose(tester, 2, 801);
    await _choose(tester, 3, DateTime(2026, 11, 3));
    await _choose(tester, 4, 901);
    await tester.ensureVisible(find.byKey(const ValueKey('home-quick-buy')));
    await tester.tap(find.byKey(const ValueKey('home-quick-buy')));
    await tester.pumpAndSettle();
    final uri = appRouter.routeInformationProvider.value.uri;
    expect(uri.path, AppRoutes.login);
    expect(uri.queryParameters['continue'], AppRoutes.seatSelection(901));
    expect(container.read(authSessionProvider).isAuthenticated, isFalse);
  });

  testWidgets('compact selectors remain usable at 320px and 200 percent text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _open(tester, width: 320);
    await _choose(tester, 1, 701);
    await _choose(tester, 2, 801);
    await _choose(tester, 3, DateTime(2026, 11, 3));
    await _choose(tester, 4, 901);
    expect(_buy(tester).onPressed, isNotNull);
    expect(_step(tester, 1).label, _longTitle);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact hero preserves swipe, pager and next movie navigation', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _open(tester);
      await tester.drag(find.byType(HomeHeroCarousel), const Offset(-430, 0));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Ảnh 2 trên 3'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('hero-open-702')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MovieDetailPage>(find.byType(MovieDetailPage)).movieId,
        702,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('changing a parent clears dependent choices', (tester) async {
    await _open(tester);
    await _choose(tester, 1, 701);
    await _choose(tester, 2, 801);
    await _choose(tester, 3, DateTime(2026, 11, 3));
    await _choose(tester, 4, 901);
    await _choose(tester, 3, DateTime(2026, 11, 4));
    expect(_step(tester, 4).label, 'Chọn suất');
    expect(_buy(tester).onPressed, isNull);
    await _choose(tester, 2, 802);
    expect(_step(tester, 3).label, 'Chọn ngày');
    expect(_step(tester, 4).onTap, isNull);
    await _choose(tester, 1, 702);
    expect(_step(tester, 2).label, 'Chọn rạp');
    expect(_step(tester, 3).onTap, isNull);
    expect(_buy(tester).onPressed, isNull);
  });

  testWidgets('refresh removes stale selectable showtime and disables CTA', (
    tester,
  ) async {
    var removed = false;
    final container = await _open(
      tester,
      schedule: () => removed ? [] : _schedule(),
    );
    await _choose(tester, 1, 701);
    await _choose(tester, 2, 801);
    await _choose(tester, 3, DateTime(2026, 11, 3));
    await _choose(tester, 4, 901);
    removed = true;
    container.invalidate(showtimesProvider(const ShowtimeQuery(movieId: 701)));
    await tester.pumpAndSettle();
    expect(_buy(tester).onPressed, isNull);
    expect(_step(tester, 2).label, 'Chọn rạp');
    expect(_step(tester, 4).label, 'Chọn suất');
  });

  testWidgets('cinema cards preserve IDs and only show that cinema schedule', (
    tester,
  ) async {
    await _open(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('home-cinema-802')));
    await tester.tap(find.byKey(const ValueKey('home-cinema-802')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-cinema-slot-905')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-cinema-slot-901')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('home-cinema-slot-905')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SeatSelectionPage>(find.byType(SeatSelectionPage))
          .showtimeId,
      905,
    );
  });

  testWidgets('hero keeps actual movie detail ID', (tester) async {
    await _open(tester);
    await tester.tap(find.byKey(const ValueKey('hero-open-701')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MovieDetailPage>(find.byType(MovieDetailPage)).movieId,
      701,
    );
  });

  testWidgets('coming-soon poster preserves actual movie detail ID', (
    tester,
  ) async {
    await _open(tester);
    final poster = find.byKey(const ValueKey('home-movie-703'));
    await tester.ensureVisible(poster);
    await tester.tap(poster);
    await tester.pumpAndSettle();
    expect(
      tester.widget<MovieDetailPage>(find.byType(MovieDetailPage)).movieId,
      703,
    );
  });

  testWidgets('unknown age/format/rating do not become fake Home badges', (
    tester,
  ) async {
    final movie = mapMovieToPresentation(
      MovieDto.fromJson({
        'id': 709,
        'title': 'Không có metadata',
        'durationMinutes': 90,
        'status': 'NOW_SHOWING',
      }),
    );
    await pumpTestApp(
      tester,
      size: const Size(430, 900),
      providerOverrides: [
        moviesProvider.overrideWith((ref) async => [movie]),
      ],
    );
    expect(movie.hasAgeRating, isFalse);
    expect(find.text('P'), findsNothing);
    expect(find.text('2D'), findsNothing);
    expect(find.text('0.0'), findsNothing);
  });

  testWidgets(
    'Quick Booking schedule error is recoverable and does not hide movies',
    (tester) async {
      var failed = true;
      await _open(
        tester,
        schedule: () {
          if (failed) throw StateError('schedule unavailable');
          return _schedule();
        },
      );
      await _choose(tester, 1, 701);
      expect(_step(tester, 2).onTap, isNull);
      expect(_buy(tester).onPressed, isNull);
      expect(find.text('Đã xảy ra lỗi'), findsOneWidget);
      expect(find.byType(HomeMovieCarousel), findsNWidgets(2));
      failed = false;
      await tester.ensureVisible(find.text('Thử lại'));
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(_step(tester, 2).onTap, isNotNull);
      expect(find.text('Đã xảy ra lỗi'), findsNothing);
    },
  );

  testWidgets('closed showtimes are never offered as Quick Booking options', (
    tester,
  ) async {
    await _open(tester);
    await _choose(tester, 1, 701);
    await _choose(tester, 2, 801);
    await _choose(tester, 3, DateTime(2026, 11, 4));
    await tester.ensureVisible(find.byKey(const ValueKey('home-quick-step-4')));
    await tester.tap(find.byKey(const ValueKey('home-quick-step-4')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-choice-902')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-choice-903')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('home-choice-902')));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'cinema failure does not hide movie sections and retry recovers',
    (tester) async {
      var failed = true;
      await _open(
        tester,
        cinemas: () {
          if (failed) throw StateError('unavailable');
          return _cinemas;
        },
      );
      expect(find.byType(HomeHeroCarousel), findsOneWidget);
      expect(find.byType(HomeMovieCarousel), findsNWidgets(2));
      expect(find.text('Đã xảy ra lỗi'), findsNWidgets(2));
      failed = false;
      final retry = find.text('Thử lại').last;
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-cinema-801')), findsOneWidget);
      expect(find.text('Đã xảy ra lỗi'), findsNothing);
    },
  );

  testWidgets(
    'movie failure does not hide independent cinemas or become empty',
    (tester) async {
      await _open(tester, movieError: true);
      expect(find.text('Đã xảy ra lỗi'), findsNWidgets(3));
      expect(find.byKey(const ValueKey('home-cinema-801')), findsOneWidget);
      expect(find.text('Chưa có phim'), findsNothing);
    },
  );

  testWidgets(
    'loading is explicit per section and resolves without a global block',
    (tester) async {
      final pending = Completer<List<Movie>>();
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            moviesProvider.overrideWith((ref) => pending.future),
            homeCinemasProvider.overrideWith((ref) async => _cinemas),
          ],
          child: MaterialApp(theme: AppTheme.dark, home: const HomePage()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('Đang tải dữ liệu...'), findsNWidgets(3));
      expect(find.byKey(const ValueKey('home-cinema-801')), findsOneWidget);
      pending.complete(_movies());
      await tester.pumpAndSettle();
      expect(find.byType(HomeHeroCarousel), findsOneWidget);
      expect(find.text('Đang tải dữ liệu...'), findsNothing);
    },
  );

  testWidgets('empty movies/cinemas are not silently missing sections', (
    tester,
  ) async {
    await _open(tester, emptyMovies: true, cinemas: () => []);
    expect(find.text('Chưa có phim'), findsOneWidget);
    expect(find.text('Chưa có phim đang chiếu'), findsOneWidget);
    expect(find.text('Chưa có phim sắp chiếu'), findsOneWidget);
    expect(find.text('Chưa có rạp khả dụng'), findsOneWidget);
    expect(_buy(tester).onPressed, isNull);
  });
}

void _noop() {}

HomeBookingStep _step(WidgetTester tester, int step) =>
    tester.widget<HomeBookingStep>(find.byType(HomeBookingStep).at(step - 1));
FilledButton _buy(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(const ValueKey('home-quick-buy')));

Future<void> _choose(WidgetTester tester, int step, Object id) async {
  final control = find.byKey(ValueKey('home-quick-step-$step'));
  await tester.ensureVisible(control);
  await tester.tap(control);
  await tester.pumpAndSettle();
  final option = find.byKey(ValueKey('home-choice-$id'));
  await tester.ensureVisible(option);
  expect(
    option.hitTestable(),
    findsOneWidget,
    reason: 'Selector option rect: ${tester.getRect(option)}',
  );
  await tester.tap(option);
  await tester.pumpAndSettle();
}

Future<ProviderContainer> _open(
  WidgetTester tester, {
  double width = 430,
  bool movieError = false,
  bool emptyMovies = false,
  bool guest = false,
  List<CinemaDto> Function()? cinemas,
  List<MovieShowtime> Function()? schedule,
}) => pumpTestApp(
  tester,
  authState: guest ? unauthenticatedState : authenticatedCustomerState(),
  size: Size(width, 900),
  providerOverrides: [
    appClockProvider.overrideWithValue(FakeAppClock(DateTime(2026, 11, 1))),
    moviesProvider.overrideWith((ref) async {
      if (movieError) throw StateError('movie unavailable');
      return emptyMovies ? [] : _movies();
    }),
    homeCinemasProvider.overrideWith(
      (ref) async => cinemas?.call() ?? _cinemas,
    ),
    showtimesProvider.overrideWith(
      (ref, query) async => (schedule?.call() ?? _schedule())
          .where((s) => query.movieId == null || s.movieId == query.movieId)
          .toList(),
    ),
  ],
);

const _longTitle =
    'Một bộ phim có tên đầy đủ rất dài để kiểm tra khả năng đọc trên điện thoại';
List<Movie> _movies() => [
  _movie(701, _longTitle, MovieStatus.nowShowing),
  _movie(702, 'Phim thứ hai', MovieStatus.nowShowing),
  _movie(703, 'Phim sắp chiếu', MovieStatus.upcoming),
];
Movie _movie(int id, String title, MovieStatus status) => Movie(
  id: id,
  title: title,
  ageRating: 'T13',
  duration: '123 phút',
  rating: 0,
  genre: 'Hành động',
  genreTags: const ['Hành động'],
  tagline: '',
  posterAsset: 'assets/mock/movies/inception-poster.jpg',
  format: '',
  releaseDate: DateTime(2026, 11, 10),
  status: status,
);
const _cinemas = [
  CinemaDto(
    id: 801,
    name: 'Rạp dữ liệu số 801',
    address: 'Địa chỉ thực từ contract 801',
    city: 'Thành phố A',
    active: true,
  ),
  CinemaDto(
    id: 802,
    name: 'Rạp dữ liệu số 802',
    address: 'Địa chỉ thực từ contract 802',
    city: 'Thành phố B',
    active: true,
  ),
];
List<MovieShowtime> _schedule() => [
  MovieShowtime(
    movieId: 701,
    rooms: [
      ShowtimeRoom(
        id: 81,
        name: 'Phòng A',
        formatBadge: '',
        screenDetail: '',
        cinemaId: 801,
        slots: [
          _slot(901, 3),
          _slot(902, 4),
          _slot(903, 4, status: ShowtimeStatus.cancelled),
        ],
      ),
      ShowtimeRoom(
        id: 82,
        name: 'Phòng B',
        formatBadge: '',
        screenDetail: '',
        cinemaId: 802,
        slots: [_slot(905, 3)],
      ),
    ],
  ),
  MovieShowtime(
    movieId: 702,
    rooms: [
      ShowtimeRoom(
        id: 83,
        name: 'Phòng C',
        formatBadge: '',
        screenDetail: '',
        cinemaId: 801,
        slots: [_slot(906, 3)],
      ),
    ],
  ),
];
ShowtimeSlot _slot(
  int id,
  int day, {
  ShowtimeStatus status = ShowtimeStatus.open,
}) => ShowtimeSlot(
  id: id,
  startAt: DateTime(2026, 11, day, 18),
  endAt: DateTime(2026, 11, day, 20),
  price: const VndMoney(100000),
  status: status,
);
