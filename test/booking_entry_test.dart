import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/app/app.dart';
import 'package:mss301_mobile/core/demo/demo_scenario.dart';
import 'package:mss301_mobile/core/routing/app_router.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/core/time/app_clock.dart';
import 'package:mss301_mobile/features/auth/application/mock_auth_session.dart';
import 'package:mss301_mobile/features/movie/data/repositories/catalog_providers.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_dto.dart';
import 'package:mss301_mobile/features/orders/data/repositories/booking_providers.dart';
import 'package:mss301_mobile/features/seat/application/booking_entry_session.dart';
import 'package:mss301_mobile/features/seat/presentation/pages/seat_selection_page.dart';

void main() {
  Future<ProviderContainer> openAvengersSeat(
    WidgetTester tester, {
    bool guest = false,
    AppClock? clock,
  }) async {
    appRouter.go(AppRoutes.home);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (clock != null) appClockProvider.overrideWithValue(clock),
        ],
        child: const CinePremierApp(),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CinePremierApp)),
    );
    if (guest) {
      container.read(mockAuthSessionProvider.notifier).signOut();
    }

    await tester.tap(find.byKey(const ValueKey('hero-book-2')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('showtime-slot-1002')).hitTestable(),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('R4 happy path selects seats, holds, and guards logo exit', (
    tester,
  ) async {
    final container = await openAvengersSeat(tester);
    expect(find.byType(SeatSelectionPage), findsOneWidget);
    expect(find.byKey(const ValueKey('seat-hold-timer')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('seat-3001')));
    await tester.pump();
    expect(
      container.read(bookingEntryProvider).selectedSeatIds,
      contains(3001),
    );

    await tester.tap(find.byKey(const ValueKey('seat-continue')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(container.read(bookingEntryProvider).hasActiveHold, isTrue);
    expect(find.byKey(const ValueKey('seat-hold-timer')), findsOneWidget);

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
    expect(find.byType(SeatSelectionPage), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('header-home-logo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('booking-leave-yes')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(container.read(bookingEntryProvider).hasActiveDraft, isFalse);
    expect(find.text('Phim đang chiếu'), findsOneWidget);
  });

  testWidgets('R4 guest auth resumes the exact selected showtime', (
    tester,
  ) async {
    final container = await openAvengersSeat(tester, guest: true);

    expect(find.text('Đăng nhập để đặt vé'), findsOneWidget);
    expect(
      container.read(mockAuthSessionProvider).pendingBooking?.showtimeId,
      1002,
    );
    await tester.tap(find.byKey(const ValueKey('mock-auth-continue')));
    await tester.pumpAndSettle();

    expect(find.byType(SeatSelectionPage), findsOneWidget);
    expect(find.text('Avengers: Endgame'), findsOneWidget);
    expect(container.read(mockAuthSessionProvider).isAuthenticated, isTrue);
    expect(container.read(mockAuthSessionProvider).pendingBooking, isNull);
  });

  testWidgets('R4 couple seat toggles as a pair and back asks confirmation', (
    tester,
  ) async {
    final container = await openAvengersSeat(tester);

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

    await tester.tap(find.byKey(const ValueKey('seat-3004')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('seat-continue')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byKey(const ValueKey('booking-entry-message')), findsOneWidget);
    expect(
      container.read(bookingEntryProvider).unavailableSeatIds,
      contains(DemoIds.seatC4),
    );
    expect(container.read(bookingEntryProvider).hasActiveHold, isFalse);
  });

  testWidgets('R4 fake clock expires a hold and offers safe recovery', (
    tester,
  ) async {
    final clock = FakeAppClock(DateTime.utc(2026, 9, 25, 12));
    final container = await openAvengersSeat(tester, clock: clock);
    await tester.tap(find.byKey(const ValueKey('seat-3001')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('seat-continue')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(container.read(bookingEntryProvider).hasActiveHold, isTrue);

    clock.advance(const Duration(minutes: 3, seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('Đã hết thời gian giữ ghế'), findsOneWidget);
    expect(find.text('Chọn lại'), findsOneWidget);
    await tester.tap(find.text('Chọn lại'));
    await tester.pumpAndSettle();
    expect(
      container.read(bookingEntryProvider).phase,
      BookingEntryPhase.selectingSeats,
    );
  });
}
