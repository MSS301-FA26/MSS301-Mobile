import 'dart:async';

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

class _OccupiedCatalog extends _WideCatalog {
  @override
  Future<ShowtimeSeatMapDto> getSeatMap(int showtimeId) async {
    final base = await super.getSeatMap(showtimeId);
    return ShowtimeSeatMapDto(
      showtime: base.showtime,
      rowCount: base.rowCount,
      columnCount: base.columnCount,
      seats: [
        for (final seat in base.seats)
          ShowtimeSeatDto(
            seatId: seat.seatId,
            seatRowId: seat.seatRowId,
            rowLabel: seat.rowLabel,
            displayOrder: seat.displayOrder,
            seatNumber: seat.seatNumber,
            displayColumn: seat.displayColumn,
            startColumn: seat.startColumn,
            seatType: seat.seatType,
            seatStatus: seat.seatStatus,
            runtimeStatus: switch (seat.seatNumber) {
              2 => SeatRuntimeStatus.holding,
              3 => SeatRuntimeStatus.booked,
              4 => SeatRuntimeStatus.unknown,
              _ => SeatRuntimeStatus.available,
            },
          ),
      ],
    );
  }
}

class _TransientSeatCatalog extends _WideCatalog {
  int calls = 0;

  @override
  Future<ShowtimeSeatMapDto> getSeatMap(int showtimeId) async {
    calls++;
    if (calls == 2) throw StateError('offline');
    return super.getSeatMap(showtimeId);
  }
}

class _DeferredRefreshCatalog extends _WideCatalog {
  int calls = 0;
  final pending = Completer<ShowtimeSeatMapDto>();
  ShowtimeSeatMapDto? lastMap;

  @override
  Future<ShowtimeSeatMapDto> getSeatMap(int showtimeId) async {
    calls++;
    if (calls == 3) return pending.future;
    final map = await super.getSeatMap(showtimeId);
    lastMap = map;
    return map;
  }
}

void main() {
  testWidgets('background refresh keeps seats and layout visible', (
    tester,
  ) async {
    final catalog = _DeferredRefreshCatalog();
    await pumpTestApp(
      tester,
      initialLocation: AppRoutes.seatSelection(1002),
      size: const Size(390, 844),
      providerOverrides: [
        seatMapProvider.overrideWith((ref, id) => catalog.getSeatMap(id)),
      ],
    );
    expect(catalog.calls, 2);
    final seat = find.byKey(const ValueKey('seat-9001'));
    final before = tester.getRect(seat);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(catalog.calls, 3);
    expect(find.byKey(const ValueKey('seat-map-stale-warning')), findsNothing);
    expect(find.byKey(const ValueKey('seat-9001')), findsOneWidget);
    expect(tester.getRect(seat), before);
    expect(tester.widget<InkWell>(seat).onTap, isNotNull);

    catalog.pending.complete(catalog.lastMap!);
    await tester.pumpAndSettle();
    expect(tester.getRect(seat), before);
  });

  testWidgets('offline refresh keeps a read-only map until retry succeeds', (
    tester,
  ) async {
    final catalog = _TransientSeatCatalog();
    await pumpTestApp(
      tester,
      initialLocation: AppRoutes.seatSelection(1002),
      size: const Size(390, 844),
      providerOverrides: [
        seatMapProvider.overrideWith((ref, id) => catalog.getSeatMap(id)),
      ],
    );
    await tester.pumpAndSettle();
    expect(catalog.calls, 2);
    expect(
      find.byKey(const ValueKey('seat-map-stale-warning')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('seat-9001')), findsOneWidget);
    expect(
      tester.widget<InkWell>(find.byKey(const ValueKey('seat-9001'))).onTap,
      isNull,
    );

    await tester.tap(find.byTooltip('Tải lại sơ đồ ghế'));
    await tester.pumpAndSettle();
    expect(catalog.calls, 3);
    expect(find.byKey(const ValueKey('seat-map-stale-warning')), findsNothing);
    expect(
      tester.widget<InkWell>(find.byKey(const ValueKey('seat-9001'))).onTap,
      isNotNull,
    );
  });

  testWidgets('occupied seats keep slots but cannot be selected', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      initialLocation: AppRoutes.seatSelection(1002),
      size: const Size(390, 844),
      providerOverrides: [
        seatMapProvider.overrideWith(
          (ref, id) => _OccupiedCatalog().getSeatMap(id),
        ),
      ],
    );
    await tester.ensureVisible(find.byKey(const ValueKey('seat-9002')));
    for (final number in [2, 3, 4]) {
      final seat = find.byKey(ValueKey('seat-${9000 + number}'));
      expect(tester.widget<InkWell>(seat).onTap, isNull);
      final semantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label?.startsWith('Ghế A$number,') == true,
        ),
      );
      expect(semantics.properties.enabled, isFalse);
      expect(
        tester.getSize(seat),
        tester.getSize(find.byKey(const ValueKey('seat-9001'))),
      );
    }
    expect(
      tester.widget<InkWell>(find.byKey(const ValueKey('seat-9001'))).onTap,
      isNotNull,
    );
  });

  testWidgets('seat map zoom controls update scale and reset it', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      initialLocation: AppRoutes.seatSelection(1002),
      size: const Size(390, 844),
      providerOverrides: [
        seatMapProvider.overrideWith(
          (ref, id) => _WideCatalog().getSeatMap(id),
        ),
      ],
    );
    final viewer = tester.widget<InteractiveViewer>(
      find.byKey(const ValueKey('seat-map-interactive')),
    );
    final controller = viewer.transformationController!;
    await tester.ensureVisible(find.byKey(const ValueKey('seat-zoom-in')));
    await tester.tap(find.byKey(const ValueKey('seat-zoom-in')));
    await tester.pump();
    expect(controller.value.getMaxScaleOnAxis(), closeTo(1.25, 0.01));
    await tester.tap(find.byKey(const ValueKey('seat-zoom-out')));
    await tester.pump();
    expect(controller.value.getMaxScaleOnAxis(), closeTo(1, 0.01));
    await tester.tap(find.byKey(const ValueKey('seat-zoom-in')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('seat-zoom-reset')));
    await tester.pump();
    expect(controller.value.getMaxScaleOnAxis(), closeTo(1, 0.01));
  });

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
