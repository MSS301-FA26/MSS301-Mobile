import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/money/vnd_money.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/core/time/app_clock.dart';
import 'package:mss301_mobile/features/discover/presentation/widgets/discover_movie_card.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';
import 'package:mss301_mobile/features/movie/data/models/movie_dto.dart';
import 'package:mss301_mobile/features/movie/data/repositories/catalog_providers.dart';
import 'package:mss301_mobile/features/movie/presentation/models/movie.dart';
import 'package:mss301_mobile/features/movie/presentation/providers/movies_provider.dart';
import 'package:mss301_mobile/features/showtime/presentation/models/showtime_models.dart';
import 'package:mss301_mobile/features/showtime/presentation/providers/showtimes_provider.dart';
import 'package:mss301_mobile/features/showtime/presentation/widgets/showtime_movie_card.dart';

import 'support/pump_test_app.dart';

const film = Movie(
  id: 2,
  title: 'Một bộ phim có tên rất dài để kiểm tra giao diện',
  ageRating: 'T18',
  duration: '128 phút',
  rating: null,
  genre: 'Hành động, Phiêu lưu, Tâm lý',
  tagline: '',
  posterAsset: 'assets/missing.jpg',
  status: MovieStatus.nowShowing,
);

void main() {
  final now = DateTime.utc(2026, 10, 14, 5);
  ShowtimeSlot slot(int id, ShowtimeStatus status, {bool past = false}) =>
      ShowtimeSlot(
        id: id,
        startAt: now.add(Duration(hours: past ? -1 : id)),
        endAt: now.add(Duration(hours: past ? 1 : id + 2)),
        price: const VndMoney(120000),
        status: status,
      );
  final rooms = [
    ShowtimeRoom(
      id: 1,
      name: 'Phòng chiếu có tên dài',
      formatBadge: 'IMAX',
      screenDetail: 'Phụ đề tiếng Việt',
      slots: [
        slot(1, ShowtimeStatus.open),
        slot(2, ShowtimeStatus.scheduled),
        slot(3, ShowtimeStatus.cancelled),
        slot(4, ShowtimeStatus.completed),
        slot(5, ShowtimeStatus.open, past: true),
      ],
    ),
    ShowtimeRoom(
      id: 2,
      name: 'Phòng 2',
      formatBadge: '2D',
      screenDetail: '',
      slots: [slot(6, ShowtimeStatus.open)],
    ),
  ];

  test('API without rating maps to missing instead of zero', () {
    final dto = MovieDto.fromJson({
      'id': 2,
      'title': 'Movie',
      'status': 'NOW_SHOWING',
    });
    expect(mapMovieToPresentation(dto).rating, isNull);
  });

  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    testWidgets(
      'cards handle long text, missing image and unavailable slots at $width',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 950));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        int? selected;
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 950),
                textScaler: TextScaler.linear(1.8),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DiscoverMovieCard(
                              movie: film,
                              onOpen: () {},
                              onBook: () {},
                            ),
                          ),
                          Expanded(
                            child: DiscoverMovieCard(
                              movie: film,
                              onOpen: () {},
                              onBook: () {},
                            ),
                          ),
                        ],
                      ),
                      ShowtimeMovieCard(
                        movie: film,
                        rooms: rooms,
                        now: now,
                        selectedSlotId: 1,
                        onSlotSelected: (value) => selected = value.id,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('0.0'), findsNothing);
        for (final reason in [
          'Chưa mở bán',
          'Đã hủy',
          'Đã kết thúc',
          'Đã qua giờ',
        ]) {
          expect(find.text(reason), findsOneWidget);
        }
        expect(find.text('✓ Đã chọn'), findsOneWidget);
        expect(find.text('Phòng 2'), findsOneWidget);
        for (final id in [2, 3, 4, 5]) {
          final finder = find.byKey(ValueKey('showtime-slot-$id'));
          expect(tester.widget<InkWell>(finder).onTap, isNull);
        }
        final open = find.byKey(const ValueKey('showtime-slot-1'));
        await tester.ensureVisible(open);
        await tester.tap(open);
        expect(selected, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Discover page lays out grid with large text at $width', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpTestApp(
        tester,
        initialLocation: AppRoutes.discover,
        size: Size(width, 950),
      );
      expect(find.byType(DiscoverMovieCard), findsWidgets);
      await tester.ensureVisible(find.text('Đặt vé').first);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Showtimes full page and selected footer fit 320 px with large text',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpTestApp(
        tester,
        initialLocation: AppRoutes.showtimes,
        size: const Size(320, 950),
        providerOverrides: [
          appClockProvider.overrideWithValue(FakeAppClock(now)),
          moviesProvider.overrideWith((ref) async => [film]),
          showtimesProvider.overrideWith(
            (ref, query) async => [MovieShowtime(movieId: 2, rooms: rooms)],
          ),
        ],
      );
      expect(tester.takeException(), isNull);
      final open = find.byKey(const ValueKey('showtime-slot-1'));
      await tester.ensureVisible(open);
      await tester.pumpAndSettle();
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('showtime-continue')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'changing day clears selection and expired selection cannot continue',
    (tester) async {
      final clock = FakeAppClock(now);
      await pumpTestApp(
        tester,
        initialLocation: AppRoutes.showtimes,
        size: const Size(390, 950),
        providerOverrides: [
          appClockProvider.overrideWithValue(clock),
          moviesProvider.overrideWith((ref) async => [film]),
          showtimesProvider.overrideWith(
            (ref, query) async => [MovieShowtime(movieId: 2, rooms: rooms)],
          ),
        ],
      );
      final open = find.byKey(const ValueKey('showtime-slot-1'));
      await tester.ensureVisible(open);
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('showtime-continue')), findsOneWidget);
      clock.advance(const Duration(hours: 2));
      await tester.tap(find.byKey(const ValueKey('showtime-continue')));
      await tester.pumpAndSettle();
      expect(find.textContaining('không còn mở bán'), findsOneWidget);
      expect(find.byKey(const ValueKey('showtime-continue')), findsNothing);
      clock.set(now);
      await tester.ensureVisible(open);
      await tester.tap(open);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('HÔM NAY'));
      await tester.tap(find.text('HÔM NAY'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('showtime-continue')), findsNothing);
    },
  );
}
