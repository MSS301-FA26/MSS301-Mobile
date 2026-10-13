import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/money/vnd_money.dart';
import 'package:mss301_mobile/core/time/app_clock.dart';
import 'package:mss301_mobile/features/booking/presentation/widgets/booking_hold_countdown.dart';
import 'package:mss301_mobile/features/movie/data/repositories/catalog_providers.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_dto.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_enums.dart';

void main() {
  final now = DateTime.utc(2026, 10, 11, 6);

  BookingDto booking(BookingStatus status) => BookingDto(
    id: 42,
    bookingCode: 'BK-42',
    userId: 1,
    showtimeId: 1,
    movieId: 1,
    subtotal: VndMoney.zero,
    discountAmount: VndMoney.zero,
    loyaltyPointsRedeemed: 0,
    totalAmount: VndMoney.zero,
    status: status,
    holdExpiresAt: now.add(const Duration(minutes: 3)),
    seats: const [],
    tickets: const [],
    foods: const [],
    createdAt: now,
  );

  Future<void> open(
    WidgetTester tester,
    FakeAppClock clock,
    BookingStatus status,
  ) => tester.pumpWidget(
    ProviderScope(
      overrides: [appClockProvider.overrideWithValue(clock)],
      child: MaterialApp(
        home: Scaffold(body: BookingHoldCountdown(booking: booking(status))),
      ),
    ),
  );

  testWidgets(
    'countdown keeps the same deadline across screens and app resume',
    (tester) async {
      final clock = FakeAppClock(now);
      await open(tester, clock, BookingStatus.holding);
      expect(find.text('03:00'), findsOneWidget);
      clock.advance(const Duration(seconds: 41));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('02:19'), findsOneWidget);

      // A new screen receives the same booking, not a new three-minute timer.
      await tester.pumpWidget(const SizedBox.shrink());
      await open(tester, clock, BookingStatus.pendingPayment);
      expect(find.text('02:19'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      clock.advance(const Duration(seconds: 60));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('01:19'), findsOneWidget);

      clock.advance(const Duration(minutes: 2));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('Đã hết thời gian giữ ghế'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('paid booking hides the countdown and narrow screens fit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final clock = FakeAppClock(now);
    await open(tester, clock, BookingStatus.holding);
    expect(tester.takeException(), isNull);
    await open(tester, clock, BookingStatus.paid);
    expect(find.byKey(const ValueKey('booking-hold-countdown')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
