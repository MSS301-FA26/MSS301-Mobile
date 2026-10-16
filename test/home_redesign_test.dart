import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/demo/demo_scenario.dart';
import 'package:mss301_mobile/core/time/app_clock.dart';
import 'package:mss301_mobile/features/home/data/home_banner_repository.dart';
import 'package:mss301_mobile/features/home/presentation/providers/home_preview_provider.dart';
import 'package:mss301_mobile/features/home/presentation/widgets/movie_coverflow.dart';
import 'package:mss301_mobile/features/home/presentation/widgets/promotional_banner_carousel.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';
import 'package:mss301_mobile/features/movie/data/models/movie_dto.dart';
import 'package:mss301_mobile/features/movie/data/repositories/catalog_providers.dart';
import 'package:mss301_mobile/features/movie/data/repositories/mock_catalog_repository.dart';
import 'package:mss301_mobile/features/movie/presentation/models/movie.dart';
import 'package:mss301_mobile/features/movie/presentation/providers/movies_provider.dart';

import 'support/pump_test_app.dart';

class _CountingCatalog extends MockCatalogRepository {
  _CountingCatalog() : super(scenario: const DemoScenario(SystemAppClock()));
  final calls = <MovieStatus?>[];
  @override
  Future<List<MovieDto>> getMovies({MovieStatus? status, String? keyword}) {
    calls.add(status);
    return super.getMovies(status: status, keyword: keyword);
  }
}

Future<List<Movie>> _movies() async =>
    (await _CountingCatalog().getMovies(status: MovieStatus.nowShowing))
        .map(mapMovieToPresentation)
        .toList();

Future<void> _pumpCarousel(
  WidgetTester tester,
  List<Movie> movies, {
  double width = 390,
  ValueChanged<Movie>? book,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: MovieCoverflow(
            movies: movies,
            colorLoader: (_) async => Colors.blue,
            onOpen: (_) {},
            onBook: book ?? (_) {},
            onTrailer: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late List<Movie> fixtureMovies;
  late List<Movie> upcomingFixtures;
  setUpAll(() async {
    fixtureMovies = await _movies();
    upcomingFixtures = (await _CountingCatalog().getMovies(
      status: MovieStatus.upcoming,
    )).map(mapHomeMovie).toList();
  });
  testWidgets(
    'switch tabs resets selection, uses upcoming action and caches both feeds',
    (tester) async {
      final upcoming = upcomingFixtures;
      final calls = <MovieStatus>[];
      await pumpTestApp(
        tester,
        size: const Size(390, 900),
        providerOverrides: [
          homeCategoryMoviesProvider.overrideWith((ref, status) async {
            calls.add(status);
            return status == MovieStatus.nowShowing ? fixtureMovies : upcoming;
          }),
        ],
      );
      await tester.drag(
        find.byKey(const ValueKey('movie-coverflow')),
        const Offset(-120, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sắp chiếu'));
      await tester.pumpAndSettle();
      expect(find.text('Xem chi tiết'), findsOneWidget);
      expect(find.text('Đặt vé'), findsNothing);
      expect(
        find.byKey(ValueKey('movie-info-${upcoming.first.id}')),
        findsOneWidget,
      );
      await tester.tap(find.text('Đang chiếu'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('movie-info-${fixtureMovies.first.id}')),
        findsOneWidget,
      );
      expect(calls, [MovieStatus.nowShowing, MovieStatus.upcoming]);
    },
  );
  test(
    'Home categories request exact API status and retain cache per tab',
    () async {
      final repository = _CountingCatalog();
      final container = ProviderContainer(
        overrides: [
          homeUiPreviewProvider.overrideWithValue(false),
          catalogRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final now = await container.read(
        homeCategoryMoviesProvider(MovieStatus.nowShowing).future,
      );
      final upcoming = await container.read(
        homeCategoryMoviesProvider(MovieStatus.upcoming).future,
      );
      expect(now.every((movie) => movie.isNowShowing), isTrue);
      expect(upcoming.every((movie) => movie.isComingSoon), isTrue);
      await container.read(
        homeCategoryMoviesProvider(MovieStatus.nowShowing).future,
      );
      expect(repository.calls, [MovieStatus.nowShowing, MovieStatus.upcoming]);
    },
  );

  test('banner API prefers desktop image like FE and maps CTA without invented target', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    var requests = 0;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests++;
          expect(request.path, '/api/v1/hero-banners');
          handler.resolve(
            Response(
              requestOptions: request,
              data: {
                'success': true,
                'data': [
                  {
                    'id': 7,
                    'mobileImageUrl': '/uploads/banner.jpg',
                    'desktopImageUrl': '/desktop.jpg',
                    'altText': 'Cinema banner',
                    'linkedMovieId': 2,
                    'primaryCtaType': 'VIEW_MOVIE',
                  },
                  {
                    'id': 8,
                    'imageMobile': 'https://example.test/banner.jpg',
                    'primaryCtaType': 'NONE',
                  },
                  {'id': 9, 'mobileImageUrl': ''},
                ],
              },
            ),
          );
        },
      ),
    );
    final banners = await HomeBannerRepository(dio).getBanners();
    expect(requests, 1);
    expect(banners, hasLength(2));
    expect(banners.first.image, 'http://localhost:8080/desktop.jpg');
    expect(banners.first.movieId, 2);
    expect(banners.last.movieId, isNull);
    expect(banners.last.url, isNull);
  });

  for (final count in [0, 1, 2]) {
    testWidgets(
      'coverflow handles $count movies without fake posters or overflow',
      (tester) async {
        final movies = fixtureMovies.take(count).toList();
        await _pumpCarousel(tester, movies, width: 320);
        expect(find.byType(MovieCoverflow), findsOneWidget);
        expect(find.byKey(const ValueKey('hero-open-3')), findsNothing);
        if (count > 0) {
          await tester.drag(
            find.byKey(const ValueKey('movie-coverflow')),
            const Offset(-600, 0),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(ValueKey('movie-info-${movies.last.id}')),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    '3D transform follows finger before release; booking uses settled selected movie',
    (tester) async {
      int? booked;
      final movies = fixtureMovies;
      await _pumpCarousel(tester, movies, book: (movie) => booked = movie.id);
      final poster = find.byKey(ValueKey('hero-open-${movies.first.id}'));
      Transform matrix() => tester.widget<Transform>(
        find.ancestor(of: poster, matching: find.byType(Transform)).first,
      );
      expect(matrix().transform.entry(0, 2), 0);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('movie-coverflow'))),
      );
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-80, 0));
      await tester.pump(const Duration(milliseconds: 100));
      expect(matrix().transform.entry(0, 2).abs(), greaterThan(0.01));
      expect(
        find.byKey(ValueKey('movie-info-${movies.first.id}')),
        findsOneWidget,
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('movie-info-${movies[1].id}')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(ValueKey('hero-book-${movies[1].id}')),
      );
      await tester.tap(find.byKey(ValueKey('hero-book-${movies[1].id}')));
      expect(booked, movies[1].id);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'short slow swipe springs back without changing movie information',
    (tester) async {
      final movies = fixtureMovies;
      await _pumpCarousel(tester, movies);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('movie-coverflow'))),
      );
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-15, 0));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('movie-info-${movies.first.id}')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'banner auto-slide pauses during touch and resumes after release',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeBannersProvider.overrideWith(
              (ref) async => const [
                HomeBanner(
                  id: 1,
                  image: 'assets/mock/movies/inception-banner.jpg',
                  title: 'One',
                ),
                HomeBanner(
                  id: 2,
                  image: 'assets/mock/movies/inception-banner.jpg',
                  title: 'Two',
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: PromotionalBannerCarousel()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final finder = find.byKey(const ValueKey('home-promotion-carousel'));
      final pages = tester.widget<PageView>(finder).controller!;
      final gesture = await tester.startGesture(tester.getCenter(finder));
      await tester.pump(const Duration(seconds: 6));
      expect(pages.page, 0);
      await gesture.up();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(pages.page, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
