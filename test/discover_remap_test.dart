import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/demo/demo_scenario.dart';
import 'package:mss301_mobile/core/routing/app_router.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/core/theme/app_theme.dart';
import 'package:mss301_mobile/core/time/app_clock.dart';
import 'package:mss301_mobile/features/discover/presentation/widgets/discover_movie_card.dart';
import 'package:mss301_mobile/features/discover/presentation/providers/discover_provider.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';
import 'package:mss301_mobile/features/movie/data/models/movie_dto.dart';
import 'package:mss301_mobile/features/movie/data/repositories/catalog_providers.dart';
import 'package:mss301_mobile/features/movie/data/repositories/mock_catalog_repository.dart';
import 'package:mss301_mobile/shared/widgets/app_button.dart';
import 'package:mss301_mobile/shared/widgets/app_image.dart';

import 'support/pump_test_app.dart';

void main() {
  Future<void> openDiscover(
    WidgetTester tester,
    _RecordingCatalog repository, {
    double width = 390,
  }) async {
    await pumpTestApp(
      tester,
      initialLocation: AppRoutes.discover,
      size: Size(width, 844),
      providerOverrides: [
        mockCatalogRepositoryProvider.overrideWithValue(repository),
      ],
    );
  }

  testWidgets(
    'search keeps debounce and filters pass real status and genre ID',
    (tester) async {
      final repository = _RecordingCatalog();
      await openDiscover(tester, repository);
      final initialCalls = repository.requests.length;

      await tester.enterText(
        find.byKey(const ValueKey('discover-search')),
        '  Dune  ',
      );
      await tester.pump(const Duration(milliseconds: 299));
      expect(repository.requests.length, initialCalls);
      expect(
        find.byKey(const ValueKey('discover-search-clear')),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(repository.requests.last.keyword, 'Dune');
      expect(repository.requests.last.page, 0);
      expect(repository.requests.last.size, 20);

      await tester.tap(find.byKey(const ValueKey('discover-status-Sắp chiếu')));
      await tester.pumpAndSettle();
      expect(repository.requests.last.status, MovieStatus.upcoming);
      expect(repository.requests.last.keyword, 'Dune');
      await tester.ensureVisible(
        find.byKey(const ValueKey('discover-genre-731')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('discover-genre-731')));
      await tester.pumpAndSettle();
      expect(repository.requests.last.genreId, 731);
      expect(repository.requests.last.page, 0);

      await tester.ensureVisible(
        find.byKey(const ValueKey('discover-clear-filters')),
      );
      await tester.tap(find.byKey(const ValueKey('discover-clear-filters')));
      await tester.pumpAndSettle();
      final search = tester.widget<TextField>(
        find.byKey(const ValueKey('discover-search')),
      );
      expect(search.controller!.text, isEmpty);
      expect(search.textInputAction, TextInputAction.search);
      expect(
        find.byKey(const ValueKey('discover-clear-filters')),
        findsNothing,
      );
      expect(find.text('Đã hiển thị 2 / 2'), findsOneWidget);
    },
  );

  testWidgets('empty search retains filter context and existing clear action', (
    tester,
  ) async {
    final repository = _RecordingCatalog();
    await openDiscover(tester, repository);
    await tester.enterText(
      find.byKey(const ValueKey('discover-search')),
      'no-match',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Không tìm thấy phim'));
    expect(find.text('Từ khóa: “no-match”'), findsOneWidget);
    expect(find.text('0 phim'), findsOneWidget);
    expect(find.text('Đã xảy ra lỗi'), findsNothing);
    await tester.ensureVisible(
      find.byKey(const ValueKey('discover-clear-filters')),
    );
    await tester.tap(find.byKey(const ValueKey('discover-clear-filters')));
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy phim'), findsNothing);
  });

  testWidgets('catalog error retries the same query instead of showing empty', (
    tester,
  ) async {
    final repository = _RecordingCatalog()..failNext = true;
    await openDiscover(tester, repository);
    expect(find.text('Đã xảy ra lỗi'), findsOneWidget);
    expect(find.text('Không tìm thấy phim'), findsNothing);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(repository.requests.length, 2);
    expect(repository.requests.first, repository.requests.last);
    expect(find.text('Khám phá phim'), findsOneWidget);
  });

  testWidgets('load more displays pending state and authoritative total', (
    tester,
  ) async {
    final pending = Completer<MoviePageDto>();
    final repository = _RecordingCatalog(paginated: true)..pending = pending;
    await openDiscover(tester, repository);
    expect(find.text('21 phim'), findsOneWidget);
    expect(find.text('Đã hiển thị 20 / 21'), findsOneWidget);
    final loadMore = find.byKey(const ValueKey('discover-load-more'));
    await tester.scrollUntilVisible(
      loadMore,
      600,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(loadMore);
    await tester.pump();
    expect(tester.widget<AppButton>(loadMore).loading, isTrue);
    expect(repository.requests.where((query) => query.page == 1).length, 1);
    pending.complete(repository.resultForPage(1));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('discover-load-more')), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Đã hiển thị hết kết quả.'),
      600,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Đã hiển thị hết kết quả.'), findsOneWidget);
  });

  for (final width in [320.0, 430.0, 768.0]) {
    testWidgets('Discover long titles and real genre labels fit at $width px', (
      tester,
    ) async {
      final repository = _RecordingCatalog();
      await openDiscover(tester, repository, width: width);
      await tester.ensureVisible(
        find.byKey(const ValueKey('discover-genre-731')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('discover-genre-731')));
      await tester.pumpAndSettle();
      expect(repository.requests.last.genreId, 731);
      await tester.ensureVisible(find.byType(DiscoverMovieCard).first);
      await tester.pumpAndSettle();
      expect(find.text('0.0'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tapAt(
        tester.getTopLeft(find.byKey(const ValueKey('discover-movie-701'))) +
            const Offset(24, 24),
      );
      expect(appRouter.routeInformationProvider.value.uri.path, '/movie/701');
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('AppImage uses remote poster URL and keeps error fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: AppImage(
            asset: 'https://catalog.test/poster.jpg',
            aspectRatio: AppSizes.posterAspectRatio,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final provider = tester.widget<Image>(find.byType(Image)).image;
    expect(provider, isA<NetworkImage>());
    expect((provider as NetworkImage).url, 'https://catalog.test/poster.jpg');
    expect(tester.takeException(), isNull);
  });
}

class _RecordingCatalog extends MockCatalogRepository {
  _RecordingCatalog({this.paginated = false})
    : super(scenario: const DemoScenario(SystemAppClock()));

  final bool paginated;
  final requests = <DiscoverQuery>[];
  var failNext = false;
  Completer<MoviePageDto>? pending;

  static const genre = GenreDto(
    id: 731,
    name: 'Khoa học viễn tưởng và những chuyến phiêu lưu xuyên không gian',
  );

  @override
  Future<List<GenreDto>> getGenres({int page = 0, int size = 100}) async => [
    genre,
  ];

  @override
  Future<MoviePageDto> getMoviePage({
    MovieStatus? status,
    String? keyword,
    int? genreId,
    int page = 0,
    int size = 20,
  }) async {
    requests.add(
      DiscoverQuery(
        keyword: keyword ?? '',
        status: status,
        genreId: genreId,
        page: page,
        size: size,
      ),
    );
    if (failNext) {
      failNext = false;
      throw StateError('Catalog unavailable');
    }
    if (keyword == 'no-match') return resultForPage(0, empty: true);
    if (page == 1 && pending != null) return pending!.future;
    return resultForPage(page);
  }

  MoviePageDto resultForPage(int page, {bool empty = false}) {
    final count = empty
        ? 0
        : paginated
        ? (page == 0 ? 20 : 1)
        : 2;
    return MoviePageDto(
      items: List.generate(
        count,
        (index) => MovieDto(
          id: 701 + page * 20 + index,
          title: 'Dune — Cuộc hành trình đến hành tinh cát và những bí mật chưa được khám phá',
          durationMinutes: 166,
          status: MovieStatus.nowShowing,
          genres: [genre],
          actors: const [],
          mainActorIds: const [],
          ageRating: 'T13',
        ),
      ),
      page: page,
      size: 20,
      totalItems: empty
          ? 0
          : paginated
          ? 21
          : 2,
      totalPages: empty
          ? 0
          : paginated
          ? 2
          : 1,
      first: page == 0,
      last: !paginated || page == 1 || empty,
    );
  }
}
