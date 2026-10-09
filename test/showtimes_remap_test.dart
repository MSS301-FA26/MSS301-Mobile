import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mss301_mobile/core/demo/demo_scenario.dart';
import 'package:mss301_mobile/core/money/vnd_money.dart';
import 'package:mss301_mobile/core/routing/app_router.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/core/theme/app_theme.dart';
import 'package:mss301_mobile/core/time/app_clock.dart';
import 'package:mss301_mobile/features/auth/presentation/pages/auth_page.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';
import 'package:mss301_mobile/features/movie/data/models/movie_dto.dart';
import 'package:mss301_mobile/features/movie/data/repositories/catalog_providers.dart';
import 'package:mss301_mobile/features/movie/data/repositories/mock_catalog_repository.dart';
import 'package:mss301_mobile/features/seat/presentation/pages/seat_selection_page.dart';
import 'package:mss301_mobile/features/showtime/data/models/showtime_dto.dart';
import 'package:mss301_mobile/features/showtime/presentation/pages/showtimes_page.dart';
import 'package:mss301_mobile/features/showtime/presentation/widgets/cinema_status_card.dart';
import 'package:mss301_mobile/features/showtime/presentation/widgets/date_selector.dart';
import 'package:mss301_mobile/features/showtime/presentation/widgets/showtime_movie_card.dart';
import 'package:mss301_mobile/shared/widgets/repository_state_pane.dart';

import 'support/fake_auth_session.dart';
import 'support/pump_test_app.dart';

const _movieId = 701;
const _movieTitle =
    'Hành trình đến hành tinh cát và những bí mật chưa được khám phá';
const _cinemaName =
    'Rạp Ánh Sao tại khu đô thị phía Đông với tên đầy đủ được cung cấp';
const _roomName =
    'Phòng chiếu số 12 dành cho những hành trình điện ảnh xuyên không gian';
final _now = DateTime(2026, 10, 30, 23, 45);

const _movie = MovieDto(
  id: _movieId,
  title: _movieTitle,
  durationMinutes: 150,
  status: MovieStatus.nowShowing,
  ageRating: 'T13',
  posterUrl: 'https://catalog.test/701.jpg',
  genres: [GenreDto(id: 31, name: 'Khoa học viễn tưởng và phiêu lưu')],
  actors: [],
  mainActorIds: [],
);

ShowtimeDto _showtime({
  int id = 9101,
  ShowtimeStatus status = ShowtimeStatus.open,
  DateTime? startTime,
  String? cinemaName = _cinemaName,
  String? roomName = _roomName,
}) {
  final start = startTime ?? DateTime(2026, 10, 30, 18, 45);
  return ShowtimeDto(
    id: id,
    movieId: _movieId,
    movieTitle: _movieTitle,
    cinemaId: 811,
    cinemaName: cinemaName,
    roomId: 812,
    roomName: roomName,
    startTime: start,
    endTime: start.add(const Duration(minutes: 150)),
    basePrice: const VndMoney(123000),
    movieGenreNames: const ['Khoa học viễn tưởng và phiêu lưu'],
    weekendSurcharge: false,
    holidaySurcharge: false,
    status: status,
  );
}

List<ShowtimeDto> _weekShowtimes() => List.generate(
  7,
  (index) => _showtime(
    id: 9200 + index,
    startTime: DateTime(_now.year, _now.month, _now.day + index, 18, 45),
  ),
);

Future<void> _open(
  WidgetTester tester,
  _RecordingCatalog repository, {
  double width = 430,
  double height = 844,
  bool guest = false,
  String? location,
}) async {
  await pumpTestApp(
    tester,
    initialLocation: location ?? AppRoutes.showtimesForMovie(_movieId),
    authState: guest ? unauthenticatedState : authenticatedCustomerState(),
    size: Size(width, height),
    providerOverrides: [
      appClockProvider.overrideWithValue(repository.clock),
      mockCatalogRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

Future<void> _tapDate(WidgetTester tester, int index) async {
  final option = find.byKey(ValueKey('date-option-$index'));
  await tester.ensureVisible(option);
  await tester.pumpAndSettle();
  await tester.tap(option);
  await tester.pumpAndSettle();
}

Future<void> _selectSlot(WidgetTester tester, int showtimeId) async {
  final slot = find.byKey(ValueKey('showtime-slot-$showtimeId'));
  await tester.ensureVisible(slot);
  await tester.pumpAndSettle();
  await tester.tap(slot);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('initial request retains exact movie ID and no selected date', (
    tester,
  ) async {
    final repository = _RecordingCatalog();
    await _open(tester, repository);

    expect(repository.requests.single.movieId, _movieId);
    expect(repository.requests.single.date, isNull);
    final selector = tester.widget<DateSelector>(find.byType(DateSelector));
    expect(selector.selectedIndex, isNull);
    expect(selector.dates, hasLength(7));
    expect(selector.dates.first.label, 'Hôm nay');
    expect(selector.dates.first.date, DateTime(2026, 10, 30));
    expect(selector.dates.last.date, DateTime(2026, 11, 5));
    expect(find.byKey(const ValueKey('showtime-continue')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unfiltered route retains null movie and date request fields', (
    tester,
  ) async {
    final repository = _RecordingCatalog();
    await _open(tester, repository, location: AppRoutes.showtimes);
    expect(repository.requests.single.movieId, isNull);
    expect(repository.requests.single.date, isNull);
    expect(find.byKey(const ValueKey('showtime-slot-9101')), findsOneWidget);
  });

  testWidgets(
    'date taps request the provided calendar day and selected state',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final repository = _RecordingCatalog(showtimes: _weekShowtimes());
        await _open(tester, repository);

        for (final index in [0, 3, 6]) {
          await _tapDate(tester, index);
          final expected = DateTime(_now.year, _now.month, _now.day + index);
          expect(repository.requests.last.movieId, _movieId);
          expect(repository.requests.last.date, expected);
          expect(
            tester
                .widget<DateSelector>(find.byType(DateSelector))
                .selectedIndex,
            index,
          );
          expect(
            tester
                .getSemantics(find.byKey(ValueKey('date-option-$index')))
                .flagsCollection
                .isSelected
                .toBoolOrNull(),
            isTrue,
          );
          expect(
            find.byKey(ValueKey('showtime-slot-${9200 + index}')),
            findsOneWidget,
          );
          expect(find.text(_cinemaName), findsWidgets);
        }
        expect(repository.requests.map((request) => request.date), [
          null,
          DateTime(2026, 10, 30),
          DateTime(2026, 11, 2),
          DateTime(2026, 11, 5),
        ]);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('cards show supplied cinema, room, date, times and price', (
    tester,
  ) async {
    final repository = _RecordingCatalog();
    await _open(tester, repository);
    final slot = find.byKey(const ValueKey('showtime-slot-9101'));
    final content = find.byWidgetPredicate(
      (widget) => widget is ShowtimeMovieCard || widget is CinemaStatusCard,
    );

    expect(find.text(_cinemaName), findsWidgets);
    expect(find.textContaining('0.0'), findsNothing);
    expect(find.text(_movieTitle), findsOneWidget);
    expect(find.text(_roomName), findsOneWidget);
    expect(
      find.descendant(of: slot, matching: find.text('30/10')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: slot, matching: find.text('18:45')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: slot, matching: find.textContaining('21:15')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: slot, matching: find.text('123.000đ')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: slot, matching: find.text('Mở bán')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: content, matching: find.text('CineAI Central')),
      findsNothing,
    );
    expect(
      find.descendant(of: content, matching: find.textContaining('Nguyễn Huệ')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('only OPEN slots are actionable with distinct status labels', (
    tester,
  ) async {
    const statuses = {
      ShowtimeStatus.open: 'Mở bán',
      ShowtimeStatus.scheduled: 'Chưa mở bán',
      ShowtimeStatus.cancelled: 'Đã hủy',
      ShowtimeStatus.completed: 'Đã kết thúc',
      ShowtimeStatus.unknown: 'Không khả dụng',
    };
    final fixtures = [
      for (final (index, status) in statuses.keys.indexed)
        _showtime(id: 9300 + index, status: status),
    ];
    await _open(tester, _RecordingCatalog(showtimes: fixtures));

    for (final showtime in fixtures) {
      final slot = find.byKey(ValueKey('showtime-slot-${showtime.id}'));
      await tester.ensureVisible(slot);
      await tester.pumpAndSettle();
      expect(
        tester.widget<InkWell>(slot).onTap,
        showtime.status == ShowtimeStatus.open ? isNotNull : isNull,
      );
      expect(
        find.descendant(
          of: slot,
          matching: find.text(statuses[showtime.status]!),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: slot, matching: find.text('123.000đ')),
        findsOneWidget,
      );
      if (showtime.status != ShowtimeStatus.open) {
        await tester.tap(slot);
        await tester.pump();
        expect(find.byKey(const ValueKey('showtime-continue')), findsNothing);
      }
    }
    await _selectSlot(tester, fixtures.first.id);
    expect(find.byKey(const ValueKey('showtime-continue')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('authenticated continue preserves the selected showtime ID', (
    tester,
  ) async {
    final repository = _RecordingCatalog();
    await _open(tester, repository);
    await _selectSlot(tester, 9101);
    await tester.tap(find.byKey(const ValueKey('showtime-continue')));
    await tester.pumpAndSettle();

    expect(find.byType(SeatSelectionPage), findsOneWidget);
    expect(
      tester
          .widget<SeatSelectionPage>(find.byType(SeatSelectionPage))
          .showtimeId,
      9101,
    );
    expect(
      GoRouterState.of(tester.element(find.byType(SeatSelectionPage))).uri.path,
      AppRoutes.seatSelection(9101),
    );
    expect(repository.seatMapRequests, [9101]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'guest continue keeps the exact selected showtime auth redirect',
    (tester) async {
      final repository = _RecordingCatalog();
      await _open(tester, repository, guest: true);
      await _selectSlot(tester, 9101);
      await tester.tap(find.byKey(const ValueKey('showtime-continue')));
      await tester.pumpAndSettle();

      expect(find.byType(AuthPage), findsOneWidget);
      expect(
        appRouter.routeInformationProvider.value.uri.toString(),
        AppRoutes.loginWithRedirect(AppRoutes.seatSelection(9101)),
      );
      expect(repository.seatMapRequests, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('changing the date retains the existing chosen showtime', (
    tester,
  ) async {
    final repository = _RecordingCatalog(showtimes: _weekShowtimes());
    await _open(tester, repository);
    await _selectSlot(tester, 9200);
    await _tapDate(tester, 3);

    expect(find.byKey(const ValueKey('showtime-slot-9200')), findsNothing);
    expect(find.byKey(const ValueKey('showtime-slot-9203')), findsOneWidget);
    expect(find.byKey(const ValueKey('showtime-continue')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('showtime-continue')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SeatSelectionPage>(find.byType(SeatSelectionPage))
          .showtimeId,
      9200,
    );
    expect(repository.seatMapRequests, [9200]);
  });

  testWidgets('missing cinema name uses no invented address or amenities', (
    tester,
  ) async {
    await _open(
      tester,
      _RecordingCatalog(showtimes: [_showtime(cinemaName: null)]),
    );
    final content = find.byWidgetPredicate(
      (widget) => widget is ShowtimeMovieCard || widget is CinemaStatusCard,
    );
    expect(find.text(_roomName), findsOneWidget);
    expect(find.byKey(const ValueKey('showtime-slot-9101')), findsOneWidget);
    expect(find.text(_cinemaName), findsNothing);
    for (final unsupported in [
      'CineAI Central',
      'Nguyễn Huệ',
      'Dolby',
      'IMAX',
    ]) {
      expect(
        find.descendant(
          of: content,
          matching: find.textContaining(unsupported),
        ),
        findsNothing,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty results retain the empty state with no booking action', (
    tester,
  ) async {
    await _open(tester, _RecordingCatalog(showtimes: []));
    expect(find.text('Chưa có lịch chiếu'), findsOneWidget);
    expect(find.byType(ShowtimeMovieCard), findsNothing);
    expect(find.byKey(const ValueKey('showtime-continue')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending repository request retains the loading state', (
    tester,
  ) async {
    final pending = Completer<List<ShowtimeDto>>();
    final repository = _RecordingCatalog()..pendingShowtimes = pending.future;
    await tester.binding.setSurfaceSize(const Size(430, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogRepositoryProvider.overrideWith(
            (ref) => ref.watch(mockCatalogRepositoryProvider),
          ),
          mockCatalogRepositoryProvider.overrideWithValue(repository),
          appClockProvider.overrideWithValue(repository.clock),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const ShowtimesPage(movieId: _movieId),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(RepositoryStatePane), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(ShowtimeMovieCard), findsNothing);
    expect(find.byKey(const ValueKey('showtime-continue')), findsNothing);
    expect(repository.requests.single.movieId, _movieId);
    expect(repository.requests.single.date, isNull);

    pending.complete(repository.showtimes);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(const ValueKey('showtime-slot-9101')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retry repeats the exact movie and selected calendar date', (
    tester,
  ) async {
    final repository = _RecordingCatalog(showtimes: _weekShowtimes());
    await _open(tester, repository);
    repository.failuresRemaining = 1;
    await _tapDate(tester, 3);
    expect(find.text('Đã xảy ra lỗi'), findsOneWidget);
    expect(find.byKey(const ValueKey('showtime-continue')), findsNothing);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(repository.requests, hasLength(3));
    for (final request in repository.requests.skip(1)) {
      expect(request.movieId, _movieId);
      expect(request.date, DateTime(2026, 11, 2));
    }
    expect(find.byKey(const ValueKey('showtime-slot-9203')), findsOneWidget);
    expect(find.text('Đã xảy ra lỗi'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 430.0, 768.0]) {
    testWidgets('long title, cinema and room fit at $width px', (tester) async {
      await _open(tester, _RecordingCatalog(), width: width);
      expect(find.text(_movieTitle), findsOneWidget);
      expect(find.text(_cinemaName), findsWidgets);
      expect(find.text(_roomName), findsOneWidget);
      await _selectSlot(tester, 9101);
      final slot = find.byKey(const ValueKey('showtime-slot-9101'));
      expect(tester.getSize(slot).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(slot).height, greaterThanOrEqualTo(44));
      expect(
        find.byKey(const ValueKey('showtime-continue')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('populated landscape scrolls to slots without overflow', (
    tester,
  ) async {
    await _open(tester, _RecordingCatalog(), width: 844, height: 320);
    expect(tester.takeException(), isNull);
    final slot = find.byKey(const ValueKey('showtime-slot-9101'));
    await tester.scrollUntilVisible(
      slot,
      150,
      scrollable: find
          .descendant(
            of: find.byType(ShowtimesPage),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            ),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(find.text(_movieTitle), findsOneWidget);
    expect(find.text(_cinemaName), findsWidgets);
    expect(find.text(_roomName), findsOneWidget);
    expect(slot.hitTestable(), findsOneWidget);
    expect(find.byKey(const ValueKey('showtime-continue')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'selected landscape keeps a usable continue action without overflow',
    (tester) async {
      await _open(tester, _RecordingCatalog(), width: 844, height: 320);
      final slot = find.byKey(const ValueKey('showtime-slot-9101'));
      await tester.scrollUntilVisible(
        slot,
        150,
        scrollable: find
            .descendant(
              of: find.byType(ShowtimesPage),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Scrollable &&
                    widget.axisDirection == AxisDirection.down,
              ),
            )
            .first,
      );
      await _selectSlot(tester, 9101);

      expect(
        tester
            .widget<ShowtimeMovieCard>(find.byType(ShowtimeMovieCard))
            .selectedSlotId,
        9101,
      );
      expect(
        find.byKey(const ValueKey('showtime-continue')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('long supplied content and selection fit with 200 percent text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _open(tester, _RecordingCatalog(), width: 320);

    expect(
      MediaQuery.textScalerOf(tester.element(find.byType(ShowtimeMovieCard)))
          .scale(14),
      closeTo(28, 0.001),
    );
    expect(find.text(_movieTitle), findsOneWidget);
    expect(find.text(_cinemaName), findsWidgets);
    expect(find.text(_roomName), findsOneWidget);
    await _selectSlot(tester, 9101);
    expect(
      find.byKey(const ValueKey('showtime-continue')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

class _ShowtimeRequest {
  const _ShowtimeRequest({this.movieId, this.date});

  final int? movieId;
  final DateTime? date;
}

class _RecordingCatalog extends MockCatalogRepository {
  _RecordingCatalog({List<ShowtimeDto>? showtimes})
    : clock = FakeAppClock(_now),
      showtimes = showtimes ?? [_showtime()],
      super(scenario: DemoScenario(FakeAppClock(_now)));

  final FakeAppClock clock;
  final List<ShowtimeDto> showtimes;
  final requests = <_ShowtimeRequest>[];
  final seatMapRequests = <int>[];
  int failuresRemaining = 0;
  Future<List<ShowtimeDto>>? pendingShowtimes;

  @override
  Future<List<MovieDto>> getMovies({
    MovieStatus? status,
    String? keyword,
  }) async => [_movie];

  @override
  Future<MovieDto?> getMovie(int movieId) async =>
      movieId == _movieId ? _movie : null;

  @override
  Future<List<ShowtimeDto>> getShowtimes({int? movieId, DateTime? date}) async {
    requests.add(_ShowtimeRequest(movieId: movieId, date: date));
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw StateError('catalog unavailable');
    }
    final values = pendingShowtimes == null
        ? showtimes
        : await pendingShowtimes!;
    return values
        .where((showtime) {
          if (movieId != null && showtime.movieId != movieId) return false;
          if (date == null) return true;
          final start = showtime.startTime;
          return start.year == date.year &&
              start.month == date.month &&
              start.day == date.day;
        })
        .toList(growable: false);
  }

  @override
  Future<ShowtimeDto?> getShowtime(int showtimeId) async {
    for (final showtime in showtimes) {
      if (showtime.id == showtimeId) return showtime;
    }
    return null;
  }

  @override
  Future<ShowtimeSeatMapDto> getSeatMap(int showtimeId) async {
    seatMapRequests.add(showtimeId);
    final layout = await super.getSeatMap(DemoIds.showtimeInception);
    return ShowtimeSeatMapDto(
      showtime: (await getShowtime(showtimeId))!,
      rowCount: layout.rowCount,
      columnCount: layout.columnCount,
      seats: layout.seats,
    );
  }
}
