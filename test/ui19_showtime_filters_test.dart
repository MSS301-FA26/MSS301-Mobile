import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/money/vnd_money.dart';
import 'package:mss301_mobile/core/routing/app_router.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/core/time/app_clock.dart';
import 'package:mss301_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';
import 'package:mss301_mobile/features/movie/data/models/cinema_dto.dart';
import 'package:mss301_mobile/features/movie/data/repositories/catalog_providers.dart';
import 'package:mss301_mobile/features/movie/presentation/models/movie.dart';
import 'package:mss301_mobile/features/movie/presentation/providers/movies_provider.dart';
import 'package:mss301_mobile/features/showtime/presentation/models/showtime_models.dart';
import 'package:mss301_mobile/features/showtime/presentation/providers/showtimes_provider.dart';
import 'package:mss301_mobile/features/showtime/data/models/showtime_dto.dart';

import 'support/pump_test_app.dart';

const movies = [
  Movie(
    id: 1,
    title: 'Phim Một',
    ageRating: 'T13',
    duration: '100 phút',
    rating: null,
    genre: 'Hành động',
    tagline: '',
    posterAsset: '',
    status: MovieStatus.nowShowing,
  ),
  Movie(
    id: 2,
    title: 'Phim Hai',
    ageRating: 'P',
    duration: '90 phút',
    rating: null,
    genre: 'Gia đình',
    tagline: '',
    posterAsset: '',
    status: MovieStatus.nowShowing,
  ),
];
const cinemas = [
  CinemaDto(id: 10, name: 'Rạp A', address: '', city: 'Hà Nội', active: true),
  CinemaDto(id: 20, name: 'Rạp B', address: '', city: 'Hà Nội', active: true),
];
final now = DateTime.utc(2026, 10, 14, 5);

MovieShowtime schedule(int movieId, int cinemaId, int slotId) => MovieShowtime(
  movieId: movieId,
  rooms: [
    ShowtimeRoom(
      id: cinemaId,
      name: 'Phòng 1',
      formatBadge: '',
      screenDetail: '',
      cinemaId: cinemaId,
      cinemaName: cinemaId == 10 ? 'Rạp A' : 'Rạp B',
      slots: [
        ShowtimeSlot(
          id: slotId,
          startAt: now.add(const Duration(hours: 5)),
          endAt: now.add(const Duration(hours: 7)),
          price: const VndMoney(100000),
          status: ShowtimeStatus.open,
        ),
      ],
    ),
  ],
);

Future<void> removeChip(WidgetTester tester, String key) async {
  tester.widget<InputChip>(find.byKey(ValueKey(key))).onDeleted!();
  await tester.pumpAndSettle();
}

void main() {
  test('route serializes movie, cinema and Vietnam calendar date', () {
    final route = AppRoutes.showtimesWithFilters(
      movieId: 2,
      cinemaId: 20,
      date: DateTime(2026, 10, 15),
    );
    expect(Uri.parse(route).queryParameters, {
      'movieId': '2',
      'cinemaId': '20',
      'date': '2026-10-15',
    });
  });

  test('same room ID at different cinemas stays in separate groups', () {
    ShowtimeDto dto(int id, int cinemaId) => ShowtimeDto(
      id: id,
      movieId: 1,
      cinemaId: cinemaId,
      roomId: 7,
      startTime: now.add(Duration(hours: id)),
      endTime: now.add(Duration(hours: id + 2)),
      movieGenreNames: const [],
      weekendSurcharge: false,
      holidaySurcharge: false,
      status: ShowtimeStatus.open,
    );
    final result = mapShowtimesToPresentation(1, [dto(2, 20), dto(1, 10)]);
    expect(result.rooms.map((room) => room.cinemaId), containsAll([10, 20]));
    expect(result.rooms.length, 2);
  });

  testWidgets('remove one filter preserves others and clear all resets date', (
    tester,
  ) async {
    final queries = <ShowtimeQuery>[];
    await pumpTestApp(
      tester,
      initialLocation: AppRoutes.showtimesWithFilters(
        movieId: 1,
        cinemaId: 10,
        date: DateTime(2026, 10, 15),
      ),
      size: const Size(390, 900),
      providerOverrides: [
        appClockProvider.overrideWithValue(FakeAppClock(now)),
        moviesProvider.overrideWith((ref) async => movies),
        homeCinemasProvider.overrideWith((ref) async => cinemas),
        showtimesProvider.overrideWith((ref, query) async {
          queries.add(query);
          return [schedule(1, 10, 101)];
        }),
      ],
    );
    expect(queries.last.movieId, 1);
    expect(queries.last.cinemaId, 10);
    expect(queries.last.date, DateTime(2026, 10, 15));
    await removeChip(tester, 'showtime-movie-filter');
    expect(queries.last.movieId, isNull);
    expect(queries.last.cinemaId, 10);
    expect(queries.last.date, DateTime(2026, 10, 15));
    expect(
      appRouter.routeInformationProvider.value.uri.queryParameters['movieId'],
      isNull,
    );
    await removeChip(tester, 'showtime-cinema-filter');
    expect(queries.last.cinemaId, isNull);
    expect(queries.last.date, DateTime(2026, 10, 15));
    await tester.tap(find.byKey(const ValueKey('showtime-clear-all')));
    await tester.pumpAndSettle();
    expect(queries.last.movieId, isNull);
    expect(queries.last.cinemaId, isNull);
    expect(queries.last.date, DateTime(2026, 10, 14));
    expect(
      appRouter.routeInformationProvider.value.uri.queryParameters,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('searching a cinema updates query and groups rooms by cinema', (
    tester,
  ) async {
    final queries = <ShowtimeQuery>[];
    await pumpTestApp(
      tester,
      initialLocation: AppRoutes.showtimes,
      size: const Size(390, 900),
      providerOverrides: [
        appClockProvider.overrideWithValue(FakeAppClock(now)),
        moviesProvider.overrideWith((ref) async => movies),
        homeCinemasProvider.overrideWith((ref) async => cinemas),
        showtimesProvider.overrideWith((ref, query) async {
          queries.add(query);
          return [schedule(1, 10, 101), schedule(2, 20, 202)];
        }),
      ],
    );
    expect(find.text('Rạp A'), findsWidgets);
    expect(find.text('Rạp B'), findsWidgets);
    await tester.tap(find.text('Rạp: Tất cả'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Rạp B');
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Rạp B ·'));
    await tester.pumpAndSettle();
    expect(queries.last.cinemaId, 20);
    expect(
      appRouter.routeInformationProvider.value.uri.queryParameters['cinemaId'],
      '20',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('late result from old filter does not replace current route', (
    tester,
  ) async {
    final slow = Completer<List<MovieShowtime>>();
    await pumpTestApp(
      tester,
      initialLocation: AppRoutes.showtimesForMovie(1),
      size: const Size(390, 900),
      providerOverrides: [
        appClockProvider.overrideWithValue(FakeAppClock(now)),
        moviesProvider.overrideWith((ref) async => movies),
        homeCinemasProvider.overrideWith((ref) async => cinemas),
        showtimesProvider.overrideWith(
          (ref, query) => query.movieId == 1
              ? slow.future
              : Future.value([schedule(2, 20, 202)]),
        ),
      ],
    );
    await removeChip(tester, 'showtime-movie-filter');
    expect(find.text('PHIM HAI'), findsWidgets);
    slow.complete([schedule(1, 10, 101)]);
    await tester.pumpAndSettle();
    expect(find.text('PHIM HAI'), findsWidgets);
    expect(find.text('PHIM MỘT'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing film filter clears the previously selected showtime', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      initialLocation: AppRoutes.showtimesForMovie(1),
      size: const Size(390, 900),
      providerOverrides: [
        appClockProvider.overrideWithValue(FakeAppClock(now)),
        moviesProvider.overrideWith((ref) async => movies),
        homeCinemasProvider.overrideWith((ref) async => cinemas),
        showtimesProvider.overrideWith(
          (ref, query) async => query.movieId == 1
              ? [schedule(1, 10, 101)]
              : [schedule(2, 20, 202)],
        ),
      ],
    );
    final slot = find.byKey(const ValueKey('showtime-slot-101'));
    await tester.ensureVisible(slot);
    await tester.tap(slot);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('showtime-continue')), findsOneWidget);
    await removeChip(tester, 'showtime-movie-filter');
    expect(find.byKey(const ValueKey('showtime-continue')), findsNothing);
    expect(find.byKey(const ValueKey('showtime-slot-202')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
