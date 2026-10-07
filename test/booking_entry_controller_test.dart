import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/money/vnd_money.dart';
import 'package:mss301_mobile/core/network/api_exception.dart';
import 'package:mss301_mobile/core/time/app_clock.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';
import 'package:mss301_mobile/features/movie/data/repositories/catalog_providers.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_dto.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_enums.dart';
import 'package:mss301_mobile/features/seat/application/booking_entry_session.dart';
import 'package:mss301_mobile/features/seat/data/repositories/seat_hold_providers.dart';
import 'package:mss301_mobile/features/seat/data/repositories/seat_hold_repository.dart';
import 'package:mss301_mobile/features/seat/presentation/providers/seat_map_provider.dart';
import 'package:mss301_mobile/features/showtime/data/models/showtime_dto.dart';

const _showtimeId = 92831;
const _movieId = 7;

void main() {
  final now = DateTime.utc(2026, 10, 7, 10);

  ProviderContainer containerFor(
    _FakeSeatHoldRepository repository, {
    AppClock? clock,
    Future<ShowtimeSeatMapDto> Function()? seatMap,
  }) => ProviderContainer(
    overrides: [
      seatHoldRepositoryProvider.overrideWithValue(repository),
      if (clock != null) appClockProvider.overrideWithValue(clock),
      if (seatMap != null)
        seatMapProvider(_showtimeId).overrideWith((ref) => seatMap()),
    ],
  );

  void selectSeats(ProviderContainer container, List<int> seatIds) {
    final controller = container.read(bookingEntryProvider.notifier);
    controller.begin(movieId: _movieId, showtimeId: _showtimeId);
    expect(
      controller.setTicketQuantity(TicketType.adult, seatIds.length),
      isTrue,
    );
    controller.toggleSeatIds(seatIds.toSet());
    expect(container.read(bookingEntryProvider).assignmentComplete, isTrue);
  }

  test(
    'hold success preserves selected backend ids and authoritative expiry',
    () async {
      final expiry = now.add(const Duration(minutes: 3));
      final repository = _FakeSeatHoldRepository(
        holdResult: _booking(expiry: expiry),
      );
      final container = containerFor(repository, clock: FakeAppClock(now));
      addTearDown(container.dispose);
      selectSeats(container, const [441, 442]);

      final result = await container
          .read(bookingEntryProvider.notifier)
          .holdSelectedSeats();

      expect(repository.holdCallCount, 1);
      expect(repository.lastHoldRequest!.showtimeId, _showtimeId);
      expect(repository.lastHoldRequest!.seatIds, [441, 442]);
      expect(result!.id, 741852);
      expect(result.holdExpiresAt, expiry);
      expect(container.read(bookingEntryProvider).hasActiveHold, isTrue);
    },
  );

  test(
    'double submit starts only one hold while the first request is pending',
    () async {
      final pending = Completer<BookingDto>();
      final repository = _FakeSeatHoldRepository(pendingHold: pending);
      final container = containerFor(repository, clock: FakeAppClock(now));
      addTearDown(container.dispose);
      selectSeats(container, const [441]);
      final controller = container.read(bookingEntryProvider.notifier);

      final first = controller.holdSelectedSeats();
      final second = controller.holdSelectedSeats();

      expect(repository.holdCallCount, 1);
      expect(await second, isNull);
      pending.complete(_booking(expiry: now.add(const Duration(minutes: 3))));
      expect((await first)!.id, 741852);
      expect(container.read(bookingEntryProvider).hasActiveHold, isTrue);
    },
  );

  test('conflict refresh reconciles against the fresh seat map only', () async {
    final maps = _SeatMapSequence([
      _seatMap(availableIds: const {441, 442}),
      _seatMap(availableIds: const {442}),
    ]);
    final repository = _FakeSeatHoldRepository(
      holdError: const ApiException(
        type: ApiErrorType.conflict,
        message: 'Taken',
      ),
    );
    final container = containerFor(
      repository,
      clock: FakeAppClock(now),
      seatMap: maps.next,
    );
    addTearDown(container.dispose);
    await container.read(seatMapProvider(_showtimeId).future);
    selectSeats(container, const [441, 442]);

    final result = await container
        .read(bookingEntryProvider.notifier)
        .holdSelectedSeats();
    final state = container.read(bookingEntryProvider);

    expect(result, isNull);
    expect(maps.calls, 2);
    expect(state.hasActiveHold, isFalse);
    expect(state.message, isNotNull);
    expect(state.selectedSeatIds, {442});
    expect(state.unavailableSeatIds, contains(441));
  });

  for (final scenario in [
    (
      name: 'before deadline',
      offset: const Duration(minutes: -1),
      expired: false,
    ),
    (name: 'at deadline', offset: Duration.zero, expired: true),
    (name: 'after deadline', offset: const Duration(minutes: 1), expired: true),
  ]) {
    test(
      'expiry is ${scenario.name} from holdExpiresAt and fake clock',
      () async {
        final expiry = now.add(const Duration(minutes: 3));
        final clock = FakeAppClock(expiry.add(scenario.offset));
        final repository = _FakeSeatHoldRepository(
          holdResult: _booking(expiry: expiry),
        );
        final container = containerFor(repository, clock: clock);
        addTearDown(container.dispose);
        selectSeats(container, const [441]);
        await container.read(bookingEntryProvider.notifier).holdSelectedSeats();

        final expired = await container
            .read(bookingEntryProvider.notifier)
            .refreshExpiry();

        expect(expired, scenario.expired);
        expect(
          container.read(bookingEntryProvider).phase ==
              BookingEntryPhase.expired,
          scenario.expired,
        );
      },
    );
  }

  test(
    'cancel success passes exact booking id and clears active hold afterwards',
    () async {
      final repository = _FakeSeatHoldRepository(
        holdResult: _booking(expiry: now.add(const Duration(minutes: 3))),
      );
      final container = containerFor(repository, clock: FakeAppClock(now));
      addTearDown(container.dispose);
      selectSeats(container, const [441]);
      await container.read(bookingEntryProvider.notifier).holdSelectedSeats();

      await container.read(bookingEntryProvider.notifier).abandon();

      expect(repository.cancelCallCount, 1);
      expect(repository.cancelledBookingId, 741852);
      expect(container.read(bookingEntryProvider).hasActiveHold, isFalse);
      expect(
        container.read(bookingEntryProvider).phase,
        BookingEntryPhase.idle,
      );
    },
  );

  test(
    'cancel failure preserves active hold and exposes a recoverable error',
    () async {
      final repository = _FakeSeatHoldRepository(
        holdResult: _booking(expiry: now.add(const Duration(minutes: 3))),
        cancelError: const ApiException(
          type: ApiErrorType.server,
          message: 'Retry cancellation',
        ),
      );
      final container = containerFor(repository, clock: FakeAppClock(now));
      addTearDown(container.dispose);
      selectSeats(container, const [441]);
      await container.read(bookingEntryProvider.notifier).holdSelectedSeats();

      await container.read(bookingEntryProvider.notifier).abandon();

      expect(repository.cancelCallCount, 1);
      expect(repository.cancelledBookingId, 741852);
      expect(container.read(bookingEntryProvider).hasActiveHold, isTrue);
      expect(
        container.read(bookingEntryProvider).message,
        'Retry cancellation',
      );
    },
  );
}

class _FakeSeatHoldRepository implements SeatHoldRepository {
  _FakeSeatHoldRepository({
    this.holdResult,
    this.pendingHold,
    this.holdError,
    this.cancelError,
  });

  final BookingDto? holdResult;
  final Completer<BookingDto>? pendingHold;
  final ApiException? holdError;
  final ApiException? cancelError;
  int holdCallCount = 0;
  int cancelCallCount = 0;
  int? cancelledBookingId;
  HoldSeatsRequestDto? lastHoldRequest;

  @override
  bool get canEnterMockCheckout => true;

  @override
  Future<BookingDto> hold(HoldSeatsRequestDto request) async {
    holdCallCount++;
    lastHoldRequest = request;
    if (holdError != null) throw holdError!;
    if (pendingHold != null) return pendingHold!.future;
    return holdResult!;
  }

  @override
  Future<BookingDto> getBooking(int bookingId) async => holdResult!;

  @override
  Future<BookingDto> cancel(int bookingId) async {
    cancelCallCount++;
    cancelledBookingId = bookingId;
    if (cancelError != null) throw cancelError!;
    return holdResult!;
  }
}

class _SeatMapSequence {
  _SeatMapSequence(this._maps);
  final List<ShowtimeSeatMapDto> _maps;
  int calls = 0;
  Future<ShowtimeSeatMapDto> next() async => _maps[calls++];
}

BookingDto _booking({required DateTime expiry}) => BookingDto(
  id: 741852,
  bookingCode: 'BK-741852',
  userId: 19,
  showtimeId: _showtimeId,
  movieId: _movieId,
  subtotal: const VndMoney(90000),
  discountAmount: VndMoney.zero,
  loyaltyPointsRedeemed: 0,
  totalAmount: const VndMoney(90000),
  status: BookingStatus.holding,
  holdExpiresAt: expiry,
  seats: const [],
  tickets: const [],
  foods: const [],
  createdAt: DateTime.utc(2026, 10, 7, 10),
);

ShowtimeSeatMapDto _seatMap({required Set<int> availableIds}) =>
    ShowtimeSeatMapDto(
      showtime: ShowtimeDto(
        id: _showtimeId,
        movieId: _movieId,
        cinemaId: 3,
        roomId: 5,
        startTime: DateTime.utc(2026, 10, 7, 10),
        endTime: DateTime.utc(2026, 10, 7, 12),
        movieGenreNames: const [],
        weekendSurcharge: false,
        holidaySurcharge: false,
        status: ShowtimeStatus.open,
      ),
      rowCount: 1,
      columnCount: 2,
      seats: [
        for (final id in [441, 442])
          ShowtimeSeatDto(
            seatId: id,
            seatRowId: 1,
            rowLabel: 'A',
            displayOrder: 1,
            seatNumber: id - 440,
            displayColumn: id - 440,
            startColumn: 1,
            seatType: CatalogSeatType.standard,
            seatStatus: availableIds.contains(id)
                ? SeatStatus.available
                : SeatStatus.unavailable,
            runtimeStatus: SeatRuntimeStatus.available,
          ),
      ],
    );
