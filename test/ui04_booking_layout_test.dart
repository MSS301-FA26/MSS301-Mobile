import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/demo/demo_scenario.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/core/time/app_clock.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';
import 'package:mss301_mobile/features/movie/data/models/food_quote_dto.dart';
import 'package:mss301_mobile/features/movie/data/repositories/catalog_providers.dart';
import 'package:mss301_mobile/core/money/vnd_money.dart';
import 'package:mss301_mobile/features/movie/data/repositories/mock_catalog_repository.dart';
import 'package:mss301_mobile/features/seat/application/booking_entry_session.dart';
import 'package:mss301_mobile/features/seat/presentation/providers/seat_map_provider.dart';
import 'package:mss301_mobile/features/booking/application/booking_completion_controller.dart';
import 'package:mss301_mobile/features/showtime/data/models/showtime_dto.dart';

import 'support/pump_test_app.dart';

class _SurchargeCatalog extends MockCatalogRepository {
  _SurchargeCatalog() : super(scenario: const DemoScenario(SystemAppClock()));

  @override
  Future<CheckoutQuoteDto> createCheckoutQuote(
    CheckoutQuoteRequestDto request,
  ) async => CheckoutQuoteDto.fromJson({
    'quoteId': 'surcharge-quote',
    'validUntil': '2026-10-16T12:00:00Z',
    'showtime': {
      'showtimeId': request.showtimeId,
      'movieId': 2,
      'startTime': '2026-10-16T02:50:00',
    },
    'ticketSubtotal': 313000,
    'subtotal': 313000,
    'total': 313000,
  });
}

class _WideCatalog extends MockCatalogRepository {
  _WideCatalog() : super(scenario: const DemoScenario(SystemAppClock()));
  @override
  Future<ShowtimeSeatMapDto> getSeatMap(int showtimeId) async {
    final base = await super.getSeatMap(showtimeId);
    return ShowtimeSeatMapDto(
      showtime: base.showtime,
      rowCount: 1,
      columnCount: 16,
      seats: [
        for (var i = 1; i <= 16; i++)
          ShowtimeSeatDto(
            seatId: 9000 + i,
            seatRowId: 1,
            rowLabel: 'A',
            displayOrder: 1,
            seatNumber: i,
            displayColumn: i,
            startColumn: i,
            seatType: CatalogSeatType.standard,
            seatStatus: SeatStatus.available,
            runtimeStatus: SeatRuntimeStatus.available,
          ),
      ],
    );
  }
}

void main() {
  testWidgets('seat footer uses authoritative quote including surcharge', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      initialLocation: AppRoutes.seatSelection(1002),
      size: const Size(390, 844),
      providerOverrides: [
        mockCatalogRepositoryProvider.overrideWithValue(_SurchargeCatalog()),
      ],
    );
    await tester.tap(find.byKey(const ValueKey('ticket-plus-adult')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('seat-3001')));
    await tester.tap(find.byKey(const ValueKey('seat-3001')));
    await tester.pumpAndSettle();
    expect(find.text(const VndMoney(313000).format()), findsOneWidget);
  });

  testWidgets(
    'payment header Back uses payment leave guard and deadline survives food/checkout',
    (tester) async {
      final container = await pumpTestApp(
        tester,
        initialLocation: AppRoutes.seatSelection(1002),
        size: const Size(390, 844),
      );
      await tester.tap(find.byKey(const ValueKey('ticket-plus-adult')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('seat-3001')));
      await tester.tap(find.byKey(const ValueKey('seat-3001')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('seat-continue')));
      await tester.pumpAndSettle();
      final deadline = container
          .read(bookingCompletionProvider)
          .booking!
          .holdExpiresAt;
      expect(find.byKey(const ValueKey('booking-header')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('concessions-continue')));
      await tester.pumpAndSettle();
      expect(
        container.read(bookingCompletionProvider).booking!.holdExpiresAt,
        deadline,
      );
      await tester.tap(find.byKey(const ValueKey('checkout-pay')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('booking-header-back')));
      await tester.pumpAndSettle();
      expect(find.text('Rời màn hình thanh toán?'), findsOneWidget);
      await tester.tap(find.text('Ở lại'));
      await tester.pumpAndSettle();
      expect(
        container.read(bookingCompletionProvider).booking!.holdExpiresAt,
        deadline,
      );
    },
  );

  testWidgets(
    'compact header Back keeps the seat leave guard and cancel preserves selection',
    (tester) async {
      final container = await pumpTestApp(
        tester,
        initialLocation: AppRoutes.seatSelection(1002),
        size: const Size(390, 844),
      );
      expect(find.byKey(const ValueKey('booking-header')), findsOneWidget);
      expect(find.byTooltip('Tìm kiếm'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('ticket-plus-adult')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('seat-3001')));
      await tester.tap(find.byKey(const ValueKey('seat-3001')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('booking-header-back')));
      await tester.pumpAndSettle();
      expect(find.text('Dừng chọn ghế?'), findsOneWidget);
      await tester.tap(find.text('Ở lại'));
      await tester.pumpAndSettle();
      expect(
        container.read(bookingEntryProvider).selectedSeatIds,
        contains(3001),
      );
    },
  );

  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    testWidgets(
      'wide seat map scrolls to last seat with large text at $width',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.8;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final container = await pumpTestApp(
          tester,
          initialLocation: AppRoutes.seatSelection(1002),
          size: Size(width, 1000),
          providerOverrides: [
            seatMapProvider.overrideWith(
              (ref, id) => _WideCatalog().getSeatMap(id),
            ),
          ],
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('ticket-plus-adult')),
        );
        await tester.tap(find.byKey(const ValueKey('ticket-plus-adult')));
        await tester.pump();
        final last = find.byKey(const ValueKey('seat-9016'));
        await tester.ensureVisible(last);
        await tester.pumpAndSettle();
        await tester.tap(last.hitTestable());
        await tester.pumpAndSettle();
        expect(
          container.read(bookingEntryProvider).selectedSeatIds,
          contains(9016),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
