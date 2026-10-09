import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/demo/demo_scenario.dart';
import 'package:mss301_mobile/core/time/app_clock.dart';
import 'package:mss301_mobile/features/auth/application/auth_session.dart';
import 'package:mss301_mobile/features/booking/presentation/pages/concessions_page.dart';
import 'package:mss301_mobile/features/movie/data/repositories/catalog_providers.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_dto.dart';
import 'package:mss301_mobile/features/orders/data/repositories/booking_providers.dart';
import 'package:mss301_mobile/features/seat/application/booking_entry_session.dart';
import 'package:mss301_mobile/features/seat/presentation/pages/seat_selection_page.dart';

import 'support/fake_auth_session.dart';
import 'support/pump_test_app.dart';

void main() {
  Future<ProviderContainer> openAvengersSeat(
    WidgetTester tester, {
    bool guest = false,
    AppClock? clock,
    Size size = const Size(390, 844),
  }) async {
    final container = await pumpTestApp(
      tester,
      authState: guest ? unauthenticatedState : authenticatedCustomerState(),
      size: size,
      providerOverrides: [
        if (clock != null) appClockProvider.overrideWithValue(clock),
      ],
    );

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hero-book-2')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('showtime-slot-1002')).hitTestable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('showtime-continue')));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> addAdultTickets(WidgetTester tester, [int count = 1]) async {
    for (var i = 0; i < count; i++) {
      await tester.tap(find.byKey(const ValueKey('ticket-plus-adult')));
      await tester.pump();
    }
  }

  testWidgets('R4 happy path selects seats, holds, and guards logo exit', (
    tester,
  ) async {
    final container = await openAvengersSeat(tester);
    expect(find.byType(SeatSelectionPage), findsOneWidget);
    expect(find.byKey(const ValueKey('seat-hold-timer')), findsNothing);

    await addAdultTickets(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('seat-3001')));
    await tester.tap(find.byKey(const ValueKey('seat-3001')));
    await tester.pump();
    expect(
      container.read(bookingEntryProvider).selectedSeatIds,
      contains(3001),
    );

    await tester.tap(find.byKey(const ValueKey('seat-continue')));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(container.read(bookingEntryProvider).hasActiveHold, isTrue);
    expect(find.byType(ConcessionsPage), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('header-home-logo')));
    await tester.pumpAndSettle();
    expect(find.text('Quay lại Trang chủ?'), findsOneWidget);
    final noButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('booking-leave-no')),
    );
    final yesButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('booking-leave-yes')),
    );
    expect(noButton.onPressed, isNotNull);
    expect(yesButton.onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('booking-leave-no')));
    await tester.pumpAndSettle();
    expect(find.byType(ConcessionsPage), findsOneWidget);

    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.byType(SeatSelectionPage), findsOneWidget);
    expect(
      container.read(bookingEntryProvider).selectedSeatIds,
      contains(3001),
    );
    expect(find.byKey(const ValueKey('edit-held-seats')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('header-home-logo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('booking-leave-yes')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(container.read(bookingEntryProvider).hasActiveDraft, isFalse);
    expect(find.text('Phim đang chiếu'), findsOneWidget);
  });

  testWidgets(
    'R4 seat map puts legend first and preserves usable tap targets',
    (tester) async {
      await openAvengersSeat(tester, size: const Size(320, 844));

      final legendY = tester
          .getTopLeft(find.byKey(const ValueKey('seat-map-legend')))
          .dy;
      final mapY = tester
          .getTopLeft(find.byKey(const ValueKey('seat-map-horizontal-scroll')))
          .dy;
      expect(legendY, lessThan(mapY));

      await addAdultTickets(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('seat-3001')));
      expect(
        tester.getSize(find.byKey(const ValueKey('seat-3001'))).height,
        44,
      );
      expect(tester.getSize(find.byKey(const ValueKey('seat-3001'))).width, 44);
    },
  );

  testWidgets('R4 guest auth resumes the exact selected showtime', (
    tester,
  ) async {
    final container = await openAvengersSeat(tester, guest: true);

    expect(find.byKey(const ValueKey('auth-submit')), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).last, 'test-password');
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();

    expect(find.byType(SeatSelectionPage), findsOneWidget);
    expect(find.text('Avengers: Endgame'), findsOneWidget);
    expect(container.read(authSessionProvider).isAuthenticated, isTrue);
  });

  testWidgets('R4 couple seat toggles as a pair and back asks confirmation', (
    tester,
  ) async {
    final container = await openAvengersSeat(tester);

    await addAdultTickets(tester, 2);
    await tester.ensureVisible(find.byKey(const ValueKey('seat-3010')));
    await tester.tap(find.byKey(const ValueKey('seat-3010')));
    await tester.pump();
    expect(
      container.read(bookingEntryProvider).selectedSeatIds,
      containsAll(<int>[3010, 3011]),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Dừng chọn ghế?'), findsOneWidget);
    expect(find.text('Ở lại'), findsOneWidget);
    await tester.tap(find.text('Ở lại'));
    await tester.pumpAndSettle();
    expect(find.byType(SeatSelectionPage), findsOneWidget);
  });

  testWidgets('R4 seat conflict returns to selection with business error', (
    tester,
  ) async {
    final container = await openAvengersSeat(tester);
    await addAdultTickets(tester);
    final competingHold = container
        .read(bookingRepositoryProvider)
        .holdSeats(
          DemoIds.user + 1,
          const HoldSeatsRequestDto(
            showtimeId: DemoIds.showtimeAvengers,
            seatIds: [DemoIds.seatC4],
          ),
        );
    await tester.pumpAndSettle();
    await competingHold;

    await tester.ensureVisible(find.byKey(const ValueKey('seat-3004')));
    await tester.tap(find.byKey(const ValueKey('seat-3004')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('seat-continue')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byKey(const ValueKey('booking-entry-message')), findsOneWidget);
    expect(
      container.read(bookingEntryProvider).selectedSeatIds,
      contains(DemoIds.seatC4),
    );
    expect(container.read(bookingEntryProvider).hasActiveHold, isFalse);
  });

  testWidgets('R4 fake clock expires a hold and offers safe recovery', (
    tester,
  ) async {
    final clock = FakeAppClock(DateTime.utc(2026, 9, 25, 12));
    final container = await openAvengersSeat(tester, clock: clock);
    await addAdultTickets(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('seat-3001')));
    await tester.tap(find.byKey(const ValueKey('seat-3001')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('seat-continue')));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(container.read(bookingEntryProvider).hasActiveHold, isTrue);

    clock.advance(const Duration(minutes: 3, seconds: 1));
    final expired = await tester.runAsync(
      () => container.read(bookingEntryProvider.notifier).refreshExpiry(),
    );
    expect(expired, isTrue);
    container.read(bookingEntryProvider.notifier).restartSelection();
    expect(
      container.read(bookingEntryProvider).phase,
      BookingEntryPhase.selectingSeats,
    );
  });

  testWidgets('V2 maps mixed ticket types to seats and enforces max 8', (
    tester,
  ) async {
    final container = await openAvengersSeat(tester);
    for (var i = 0; i < BookingTicketPolicy.maxTickets; i++) {
      await tester.tap(find.byKey(const ValueKey('ticket-plus-adult')));
      await tester.pump();
    }
    expect(container.read(bookingEntryProvider).ticketCount, 8);
    final plus = tester.widget<IconButton>(
      find.byKey(const ValueKey('ticket-plus-adult')),
    );
    expect(plus.onPressed, isNull);

    for (var i = 0; i < 7; i++) {
      await tester.tap(find.byKey(const ValueKey('ticket-minus-adult')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('ticket-plus-student')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('ticket-type-adult')));
    await tester.ensureVisible(find.byKey(const ValueKey('seat-3001')));
    await tester.tap(find.byKey(const ValueKey('seat-3001')));
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('ticket-type-student')),
      find.byType(SingleChildScrollView),
      const Offset(0, 250),
    );
    await tester.tap(find.byKey(const ValueKey('ticket-type-student')));
    await tester.ensureVisible(find.byKey(const ValueKey('seat-3002')));
    await tester.tap(find.byKey(const ValueKey('seat-3002')));
    await tester.pump();

    final session = container.read(bookingEntryProvider);
    expect(session.assignments[3001]?.ticketType, TicketType.adult);
    expect(session.assignments[3002]?.ticketType, TicketType.student);
    expect(session.assignmentComplete, isTrue);
  });

  for (final width in [320.0, 430.0]) {
    testWidgets('V2 Vé & Ghế has no overflow at ${width.toInt()} px', (
      tester,
    ) async {
      await openAvengersSeat(tester, size: Size(width, 844));
      await addAdultTickets(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('seat-3001')));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
