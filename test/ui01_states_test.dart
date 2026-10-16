import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/theme/app_theme.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/core/demo/demo_scenario.dart';
import 'package:mss301_mobile/core/time/app_clock.dart';
import 'package:mss301_mobile/shared/widgets/repository_state_pane.dart';
import 'package:mss301_mobile/features/movie/data/models/movie_dto.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';
import 'package:mss301_mobile/features/movie/data/repositories/mock_catalog_repository.dart';
import 'package:mss301_mobile/features/movie/data/repositories/catalog_providers.dart';

import 'support/pump_test_app.dart';

MoviePageDto page(String title, {int index = 0, bool last = false}) =>
    MoviePageDto(
      items: [
        MovieDto(
          id: title.hashCode,
          title: title,
          durationMinutes: 100,
          status: MovieStatus.nowShowing,
          genres: const [],
          actors: const [],
          mainActorIds: const [],
          posterUrl: 'assets/mock/movies/inception-poster.jpg',
        ),
      ],
      page: index,
      size: 1,
      totalItems: 2,
      totalPages: 2,
      first: index == 0,
      last: last,
    );

class _Catalog extends MockCatalogRepository {
  _Catalog(this.fetch) : super(scenario: const DemoScenario(SystemAppClock()));
  final Future<MoviePageDto> Function(MovieStatus?, int) fetch;
  @override
  Future<MoviePageDto> getMoviePage({
    MovieStatus? status,
    String? keyword,
    int? genreId,
    int page = 0,
    int size = 20,
  }) => fetch(status, page);
}

void main() {
  testWidgets(
    'loading keeps discover controls and can change query before response',
    (tester) async {
      final pending = Completer<MoviePageDto>();
      await pumpTestApp(
        tester,
        initialLocation: AppRoutes.discover,
        providerOverrides: [
          mockCatalogRepositoryProvider.overrideWithValue(
            _Catalog(
              (status, _) => status == MovieStatus.upcoming
                  ? Future.value(page('New Film', last: true))
                  : pending.future,
            ),
          ),
        ],
      );
      expect(find.text('Đang tìm phim…'), findsOneWidget);
      await tester.tap(find.text('Phim sắp chiếu'));
      await tester.pumpAndSettle();
      pending.complete(page('Old Film'));
      await tester.pumpAndSettle();
      expect(find.text('NEW FILM'), findsOneWidget);
      expect(find.text('OLD FILM'), findsNothing);
    },
  );

  testWidgets(
    'load more error retains films, retries same page and avoids duplicate first-page fetch',
    (tester) async {
      var firstCalls = 0, moreCalls = 0;
      await pumpTestApp(
        tester,
        initialLocation: AppRoutes.discover,
        size: const Size(390, 844),
        providerOverrides: [
          mockCatalogRepositoryProvider.overrideWithValue(
            _Catalog((_, index) async {
              if (index == 0) {
                firstCalls++;
                return page('First Film');
              }
              if (++moreCalls == 1) throw StateError('QA network failure');
              return page('Second Film', index: 1, last: true);
            }),
          ),
        ],
      );
      await tester.scrollUntilVisible(
        find.text('Tải thêm'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tải thêm'));
      await tester.pumpAndSettle();
      expect(find.text('FIRST FILM'), findsOneWidget);
      expect(find.text('Thử lại tải thêm'), findsOneWidget);
      await tester.ensureVisible(find.text('Thử lại tải thêm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thử lại tải thêm'));
      await tester.pumpAndSettle();
      expect(firstCalls, 1);
      expect(moreCalls, 2);
      expect(find.text('FIRST FILM'), findsOneWidget);
      expect(find.text('SECOND FILM'), findsOneWidget);
    },
  );

  testWidgets(
    'late pagination from a previous filter never mixes into current films',
    (tester) async {
      final pending = Completer<MoviePageDto>();
      await pumpTestApp(
        tester,
        initialLocation: AppRoutes.discover,
        size: const Size(390, 844),
        providerOverrides: [
          mockCatalogRepositoryProvider.overrideWithValue(
            _Catalog((status, index) async {
              if (status == MovieStatus.upcoming) {
                return page('Upcoming Film', last: true);
              }
              if (index == 1) return pending.future;
              return page('First Film');
            }),
          ),
        ],
      );
      await tester.scrollUntilVisible(
        find.text('Tải thêm'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tải thêm'));
      await tester.pump();
      final tab = find.textContaining('Phim sắp chiếu');
      await tester.scrollUntilVisible(
        tab,
        -200,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(tab);
      await tester.pumpAndSettle();
      pending.complete(page('Stale Film', index: 1, last: true));
      await tester.pumpAndSettle();
      expect(find.text('UPCOMING FILM'), findsOneWidget);
      expect(find.text('STALE FILM'), findsNothing);
    },
  );

  testWidgets(
    'static skeletons and error retry fit small screen with large text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final layout in RepositorySkeleton.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
              child: Scaffold(
                body: RepositoryStatePane.loading(layout: layout),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
            child: Scaffold(
              body: SizedBox(
                height: 250,
                child: RepositoryStatePane.error(
                  message: 'Không thể tải dữ liệu lúc này. Bạn có thể kiểm tra kết nối rồi thử lại.',
                  onRetry: () => retried = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Thử lại'));
      await tester.tap(find.text('Thử lại'));
      expect(retried, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
