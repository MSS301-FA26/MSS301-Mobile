import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/demo/demo_scenario.dart';
import 'package:mss301_mobile/core/theme/app_theme.dart';
import 'package:mss301_mobile/core/time/app_clock.dart';
import 'package:mss301_mobile/features/home/presentation/providers/home_preview_provider.dart';
import 'package:mss301_mobile/features/home/presentation/providers/poster_ambient_color.dart';
import 'package:mss301_mobile/features/home/presentation/widgets/home_movie_section.dart';
import 'package:mss301_mobile/features/home/presentation/widgets/home_quick_booking.dart';
import 'package:mss301_mobile/features/home/presentation/widgets/home_cinemas_section.dart';
import 'package:mss301_mobile/features/home/presentation/widgets/movie_coverflow.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';
import 'package:mss301_mobile/features/movie/data/models/movie_dto.dart';
import 'package:mss301_mobile/features/movie/data/repositories/catalog_providers.dart';
import 'package:mss301_mobile/features/movie/data/repositories/mock_catalog_repository.dart';
import 'package:mss301_mobile/features/movie/presentation/models/movie.dart';
import 'package:mss301_mobile/features/movie/presentation/widgets/trailer_preview_dialog.dart';

import 'support/pump_test_app.dart';

Movie film(
  int id, {
  MovieStatus status = MovieStatus.nowShowing,
  String? trailer,
  String? poster,
}) => Movie(
  id: id,
  title: 'Phim $id tên dài để kiểm tra đầy đủ trên màn hình nhỏ',
  ageRating: '',
  hasAgeRating: false,
  duration: '120 phút',
  rating: null,
  genre: 'Gia đình',
  genreTags: const ['Gia đình', 'Phiêu lưu'],
  tagline: '',
  posterAsset: poster ?? 'assets/mock/movies/inception-banner.jpg',
  status: status,
  trailerUrl: trailer,
);
final showing = [
  film(101, trailer: 'https://example.test/trailer'),
  film(102),
  film(103),
];
final upcoming = [
  film(201, status: MovieStatus.upcoming),
  film(202, status: MovieStatus.upcoming),
];

Future<ProviderContainer> pumpSection(
  WidgetTester tester, {
  double width = 390,
  List<Movie>? now,
  List<Movie>? soon,
  Future<List<Movie>> Function()? request,
  ValueChanged<Movie>? onOpen,
  ValueChanged<Movie>? onBook,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final container = ProviderContainer(
    overrides: [
      homeCategoryMoviesProvider(
        MovieStatus.nowShowing,
      ).overrideWith((ref) => request?.call() ?? Future.value(now ?? showing)),
      homeCategoryMoviesProvider(MovieStatus.upcoming)
          .overrideWith((ref) async => soon ?? upcoming),
      posterAmbientLoaderProvider.overrideWithValue((_) async => Colors.blue),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: HomeMovieSection(
              onOpen: onOpen ?? (_) {},
              onBook: onBook ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> switchTab(WidgetTester tester, MovieStatus status) async {
  final tab = find.byKey(ValueKey('home-category-${status.wireValue}'));
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

Future<void> nextFilm(WidgetTester tester) async {
  final carousel = find.byKey(const ValueKey('movie-coverflow'));
  await tester.ensureVisible(carousel);
  await tester.drag(carousel, const Offset(-110, 0));
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    testWidgets('UI15 two tabs and 3D carousel at $width large text', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpSection(tester, width: width);
      expect(find.byType(MovieCoverflow), findsOneWidget);
      await nextFilm(tester);
      expect(find.byKey(const ValueKey('movie-info-102')), findsOneWidget);
      await switchTab(tester, MovieStatus.upcoming);
      expect(find.byKey(const ValueKey('movie-info-201')), findsOneWidget);
      expect(find.text('Đặt vé'), findsNothing);
      expect(find.text('Xem chi tiết'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'UI15 remembers a different selected film per tab and uses settled CTA',
    (tester) async {
      int? opened, booked;
      final container = await pumpSection(
        tester,
        onOpen: (m) => opened = m.id,
        onBook: (m) => booked = m.id,
      );
      await nextFilm(tester);
      await switchTab(tester, MovieStatus.upcoming);
      await nextFilm(tester);
      final upcomingCta = find.byKey(const ValueKey('home-3d-book-202'));
      await tester.ensureVisible(upcomingCta);
      await tester.tap(upcomingCta);
      expect(opened, 202);
      expect(booked, isNull);
      await switchTab(tester, MovieStatus.nowShowing);
      expect(find.byKey(const ValueKey('movie-info-102')), findsOneWidget);
      final book = find.byKey(const ValueKey('home-3d-book-102'));
      await tester.ensureVisible(book);
      await tester.tap(book);
      expect(booked, 102);
      expect(container.read(homeMovieSelectionProvider), {
        MovieStatus.nowShowing: 102,
        MovieStatus.upcoming: 202,
      });
    },
  );
  testWidgets(
    'UI15 refresh keeps selected ID after reorder and falls back when removed',
    (tester) async {
      var data = showing;
      final container = await pumpSection(tester, request: () async => data);
      await nextFilm(tester);
      data = [showing[2], showing[1], showing[0]];
      container.invalidate(homeCategoryMoviesProvider(MovieStatus.nowShowing));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('movie-info-102')), findsOneWidget);
      data = [showing[2]];
      container.invalidate(homeCategoryMoviesProvider(MovieStatus.nowShowing));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('movie-info-103')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('UI15 failed refresh keeps the loaded selected movie', (
    tester,
  ) async {
    var failed = false;
    final container = await pumpSection(
      tester,
      request: () async {
        if (failed) throw StateError('refresh failed');
        return showing;
      },
    );
    await nextFilm(tester);
    failed = true;
    container.invalidate(homeCategoryMoviesProvider(MovieStatus.nowShowing));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('movie-info-102')), findsOneWidget);
    expect(
      find.textContaining('Danh sách đã tải vẫn được giữ lại'),
      findsOneWidget,
    );
  });
  testWidgets('UI15 reduced motion still selects the correct movie', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpSection(tester);
    await nextFilm(tester);
    expect(find.byKey(const ValueKey('movie-info-102')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('UI15 empty and failed tabs remain isolated and retry succeeds', (
    tester,
  ) async {
    var failed = true;
    await pumpSection(
      tester,
      soon: [],
      request: () async {
        if (failed) throw StateError('unavailable');
        return showing;
      },
    );
    expect(find.text('Chưa tải được phim'), findsOneWidget);
    await switchTab(tester, MovieStatus.upcoming);
    expect(find.text('Chưa có phim sắp chiếu'), findsOneWidget);
    expect(find.byType(MovieCoverflow), findsNothing);
    await switchTab(tester, MovieStatus.nowShowing);
    failed = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('movie-info-101')), findsOneWidget);
  });
  testWidgets(
    'UI15 late response from another tab does not replace selected tab',
    (tester) async {
      final pending = Completer<List<Movie>>();
      await pumpSection(tester, request: () => pending.future);
      expect(find.text('Đang tải phim…'), findsOneWidget);
      await switchTab(tester, MovieStatus.upcoming);
      pending.complete(showing);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('movie-info-201')), findsOneWidget);
      expect(find.byKey(const ValueKey('movie-info-101')), findsNothing);
    },
  );
  testWidgets('UI15 only valid trailer opens the existing trailer preview', (
    tester,
  ) async {
    await pumpSection(tester);
    final trailer = find.text('Xem trailer');
    await tester.ensureVisible(trailer);
    await tester.tap(trailer);
    await tester.pumpAndSettle();
    expect(find.byType(TrailerPreviewDialog), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpSection(
      tester,
      now: [film(104, trailer: 'javascript:bad', poster: '')],
    );
    expect(find.text('Xem trailer'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'UI15 tab changes preserve quick booking selection and cinema widget state',
    (tester) async {
      await pumpTestApp(tester, size: const Size(390, 1000));
      final quickState = tester.state(find.byType(HomeQuickBooking));
      final cinemasState = tester.state(find.byType(HomeCinemasSection));
      final first = find.byKey(const ValueKey('home-quick-step-1'));
      await tester.ensureVisible(first);
      await tester.tap(first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-choice-2')));
      await tester.pumpAndSettle();
      await switchTab(tester, MovieStatus.upcoming);
      await switchTab(tester, MovieStatus.nowShowing);
      expect(
        identical(tester.state(find.byType(HomeQuickBooking)), quickState),
        isTrue,
      );
      expect(
        identical(tester.state(find.byType(HomeCinemasSection)), cinemasState),
        isTrue,
      );
      expect(
        find.descendant(of: first, matching: find.text('Avengers: Endgame')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  test('UI15 category requests every page with exact status and removes duplicates', () async {
    final catalog = PagedCatalog();
    final container = ProviderContainer(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(catalog),
        homeUiPreviewProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);
    final movies = await container.read(
      homeCategoryMoviesProvider(MovieStatus.upcoming).future,
    );
    expect(movies.map((m) => m.id), [201, 202]);
    expect(catalog.calls, [0, 1]);
    expect(catalog.statuses, everyElement(MovieStatus.upcoming));
  });
}

class PagedCatalog extends MockCatalogRepository {
  PagedCatalog() : super(scenario: const DemoScenario(SystemAppClock()));
  final calls = <int>[];
  final statuses = <MovieStatus?>[];
  @override
  Future<MoviePageDto> getMoviePage({
    MovieStatus? status,
    String? keyword,
    int? genreId,
    int page = 0,
    int size = 20,
  }) async {
    calls.add(page);
    statuses.add(status);
    MovieDto dto(int id) => MovieDto.fromJson({
      'id': id,
      'title': 'Movie $id',
      'durationMinutes': 120,
      'status': 'UPCOMING',
    });
    return MoviePageDto(
      items: page == 0 ? [dto(201)] : [dto(201), dto(202)],
      page: page,
      size: size,
      totalItems: 2,
      totalPages: 2,
      first: page == 0,
      last: page == 1,
    );
  }
}
