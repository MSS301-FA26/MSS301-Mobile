import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mss301_mobile/core/money/vnd_money.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/core/theme/app_theme.dart';
import 'package:mss301_mobile/features/booking/application/booking_completion_controller.dart';
import 'package:mss301_mobile/features/booking/presentation/pages/ticket_page.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_dto.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_enums.dart';
import 'package:mss301_mobile/features/seat/data/repositories/seat_hold_providers.dart';
import 'package:mss301_mobile/features/seat/data/repositories/seat_hold_repository.dart';

const _id = 90817;
const _code = 'BK-90817-SUPPLIED';
const _payload =
    '{"bookingId":90817,"ticketCodes":["TC-C4-SUPPLIED","TC-D5-SUPPLIED","TC-E6-SUPPLIED"],"signature":"backend-payload-retained-exactly-without-shortening-or-regenerating"}';

BookingDto _booking({
  String bookingCode = _code,
  BookingStatus status = BookingStatus.paid,
  String? qrCode = _payload,
  bool snapshots = true,
  bool context = true,
  bool longText = false,
}) => BookingDto(
  id: _id,
  bookingCode: bookingCode,
  userId: 82,
  showtimeId: 4501,
  movieId: 912,
  movieTitle: context ? 'Live movie title' : null,
  movieTitleSnapshot: snapshots && context
      ? longText
            ? 'Tên bộ phim từ snapshot rất dài để kiểm tra nội dung vé không bị cắt mất khi dùng màn hình nhỏ và chữ lớn'
            : 'Movie snapshot supplied'
      : null,
  cinemaName: context ? 'Live cinema' : null,
  cinemaNameSnapshot: snapshots && context
      ? longText
            ? 'Rạp chiếu phim với tên rất dài được cung cấp bởi Backend'
            : 'Cinema snapshot supplied'
      : null,
  roomName: context ? 'Live room' : null,
  roomNameSnapshot: snapshots && context ? 'Room snapshot supplied' : null,
  showtimeStart: context ? DateTime(2026, 10, 11, 9, 30) : null,
  showtimeStartSnapshot: snapshots && context
      ? DateTime(2026, 10, 12, 20, 15)
      : null,
  subtotal: const VndMoney(987654),
  discountAmount: const VndMoney(7654),
  loyaltyPointsRedeemed: 400,
  totalAmount: const VndMoney(980000),
  status: status,
  qrCode: qrCode,
  seats: [
    for (final (seatId, label, type) in [
      (34, 'C4', TicketType.adult),
      (45, 'D5', TicketType.student),
      (56, 'E6', TicketType.child),
    ])
      BookingSeatDto(
        id: seatId + 100,
        seatId: seatId,
        showtimeId: 4501,
        rowLabel: label[0],
        seatNumber: int.parse(label[1]),
        seatLabel: label,
        seatType: BookingSeatType.standard,
        unitPrice: const VndMoney(70000),
        status: BookingSeatStatus.booked,
        ticketType: type,
      ),
  ],
  tickets: [
    for (final (seatId, type) in [
      (34, TicketType.adult),
      (45, TicketType.student),
      (56, TicketType.child),
    ])
      BookingTicketDto(
        id: seatId + 200,
        seatId: seatId,
        ticketType: type,
        quantity: 1,
        unitPrice: const VndMoney(70000),
        lineTotal: const VndMoney(70000),
      ),
  ],
  foods: const [
    BookingFoodDto(
      id: 71,
      productId: 610,
      isCombo: true,
      productName: 'Combo supplied',
      quantity: 2,
      unitPrice: VndMoney(45678),
      lineTotal: VndMoney(91357),
    ),
  ],
  createdAt: DateTime(2026, 10, 10, 12),
);

class _TicketRepository implements SeatHoldRepository {
  _TicketRepository(this.fetch);

  final Future<BookingDto> Function(int id) fetch;
  final List<int> lookupIds = [];

  @override
  bool get canEnterMockCheckout => false;

  @override
  Future<BookingDto> getBooking(int bookingId) {
    lookupIds.add(bookingId);
    return fetch(bookingId);
  }

  @override
  Future<BookingDto> hold(HoldSeatsRequestDto request) =>
      throw StateError('Ticket must not create a hold');

  @override
  Future<BookingDto> cancel(int bookingId) =>
      throw StateError('Ticket must not cancel a booking');
}

Future<GoRouter> _pump(
  WidgetTester tester,
  _TicketRepository repository, {
  Size size = const Size(430, 844),
  double textScale = 1,
  bool settle = true,
  bool nullBooking = false,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '/ticket/$_id',
    routes: [
      GoRoute(
        path: '/ticket/:id',
        builder: (_, state) =>
            TicketPage(bookingId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: AppRoutes.orders,
        builder: (_, _) => const Scaffold(body: Text('Orders destination')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        seatHoldRepositoryProvider.overrideWithValue(repository),
        if (nullBooking)
          ticketBookingProvider(_id).overrideWith((ref) async => null),
      ],
      child: MaterialApp.router(
        theme: AppTheme.dark,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return router;
}

Future<void> _reveal(WidgetTester tester, Finder target) async {
  final list = find.descendant(
    of: find.byType(TicketPage),
    matching: find.byType(ListView),
  );
  final scrollable = find
      .descendant(of: list, matching: find.byType(Scrollable))
      .first;
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(target, 160, scrollable: scrollable);
  } else {
    await tester.ensureVisible(target);
  }
  await tester.pump();
}

void main() {
  testWidgets('complete backend payload is not truncated at 320 px', (
    tester,
  ) async {
    await _pump(
      tester,
      _TicketRepository((_) async => _booking()),
      size: const Size(320, 844),
    );
    final payload = find.byWidgetPredicate(
      (widget) =>
          widget is Text && widget.data == _payload ||
          widget is SelectableText && widget.data == _payload,
    );
    await _reveal(tester, payload);
    final widget = tester.widget(payload);
    final maxLines = widget is Text
        ? widget.maxLines
        : (widget as SelectableText).maxLines;
    expect(maxLines, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'exact booking lookup renders supplied snapshots and ticket types',
    (tester) async {
      final repo = _TicketRepository((_) async => _booking());
      await _pump(tester, repo);
      expect(repo.lookupIds, [_id]);
      expect(find.text('Movie snapshot supplied'), findsOneWidget);
      await _reveal(tester, find.text('Cinema snapshot supplied'));
      expect(find.text('Cinema snapshot supplied'), findsOneWidget);
      expect(find.text('Live cinema'), findsNothing);
      await _reveal(tester, find.text('Vé người lớn'));
      expect(find.text('C4'), findsOneWidget);
      expect(find.text('Vé sinh viên'), findsOneWidget);
      expect(find.text('D5'), findsOneWidget);
      expect(find.text('Vé trẻ em'), findsOneWidget);
      expect(find.text('E6'), findsOneWidget);
      await _reveal(tester, find.text('20:15 • 12/10/2026'));
      expect(find.text('20:15 • 12/10/2026'), findsOneWidget);
      await _reveal(tester, find.text(_payload));
      expect(find.byType(SelectableText), findsWidgets);
      expect(find.byType(GridView), findsNothing);
      expect(find.text('QR Check-in'), findsNothing);
      expect(find.text('Đặt thêm bắp nước'), findsNothing);
      expect(find.text('Hủy đặt vé'), findsNothing);
    },
  );

  testWidgets('live metadata remains fallback when snapshots absent', (
    tester,
  ) async {
    await _pump(
      tester,
      _TicketRepository((_) async => _booking(snapshots: false)),
    );
    expect(find.text('Live movie title'), findsOneWidget);
    await _reveal(tester, find.text('Live cinema'));
    expect(find.text('Live cinema'), findsOneWidget);
    expect(find.text('Live room'), findsOneWidget);
    await _reveal(tester, find.text('09:30 • 11/10/2026'));
    expect(find.text('09:30 • 11/10/2026'), findsOneWidget);
  });

  testWidgets(
    'missing metadata stays neutral and null QR uses exact booking code',
    (tester) async {
      await _pump(
        tester,
        _TicketRepository((_) async => _booking(qrCode: null, context: false)),
      );
      expect(find.text('Phim'), findsOneWidget);
      await _reveal(tester, find.byKey(const ValueKey('ticket-payload')));
      final payload = tester.widget<SelectableText>(
        find.byKey(const ValueKey('ticket-payload')),
      );
      expect(payload.data, _code);
      expect(find.text('CINEPREMIER VIP RẠP'), findsNothing);
      expect(find.text('QR Check-in'), findsNothing);
    },
  );

  testWidgets('empty supplied QR is retained, not replaced by booking code', (
    tester,
  ) async {
    await _pump(tester, _TicketRepository((_) async => _booking(qrCode: '')));
    await _reveal(tester, find.byKey(const ValueKey('ticket-payload')));
    expect(
      tester
          .widget<SelectableText>(find.byKey(const ValueKey('ticket-payload')))
          .data,
      '',
    );
  });

  testWidgets('attached food and amount use DTO totals without recalculation', (
    tester,
  ) async {
    await _pump(tester, _TicketRepository((_) async => _booking()));
    await _reveal(tester, find.text('Combo supplied × 2'));
    expect(find.text('Combo supplied × 2'), findsOneWidget);
    expect(find.text(const VndMoney(91357).format()), findsOneWidget);
    await _reveal(tester, find.text(const VndMoney(980000).format()));
    expect(find.text(const VndMoney(987654).format()), findsOneWidget);
    expect(find.text(const VndMoney(7654).format()), findsOneWidget);
    expect(find.text(const VndMoney(980000).format()), findsOneWidget);
  });

  testWidgets('close retains orders destination', (tester) async {
    final router = await _pump(
      tester,
      _TicketRepository((_) async => _booking()),
    );
    await tester.tap(find.byTooltip('Đóng vé'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.orders);
    expect(find.text('Orders destination'), findsOneWidget);
  });

  testWidgets('paid status stays readable and is not a disabled action chip', (
    tester,
  ) async {
    await _pump(tester, _TicketRepository((_) async => _booking()));
    final status = find.text('Đã thanh toán');
    await _reveal(tester, status);
    expect(
      find.ancestor(of: status, matching: find.byType(ActionChip)),
      findsNothing,
    );
    expect(tester.widget<Text>(status).style?.color, AppColors.text);
    expect(
      find.ancestor(of: status, matching: find.byType(InkWell)),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  for (final status in BookingStatus.values.where(
    (status) => status != BookingStatus.paid,
  )) {
    testWidgets('${status.wireValue} cannot expose a paid ticket', (
      tester,
    ) async {
      final router = await _pump(
        tester,
        _TicketRepository((_) async => _booking(status: status)),
      );
      expect(
        find.text('Vé chỉ được phát hành khi booking đã PAID.'),
        findsOneWidget,
      );
      expect(find.text(_payload), findsNothing);
      expect(find.text('Đã thanh toán'), findsNothing);
      await tester.tap(find.text('Về Đơn của tôi'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.orders);
    });
  }

  testWidgets('null booking keeps unavailable gate', (tester) async {
    await _pump(
      tester,
      _TicketRepository((_) async => _booking()),
      nullBooking: true,
    );
    expect(
      find.text('Vé chỉ được phát hành khi booking đã PAID.'),
      findsOneWidget,
    );
    expect(find.text(_payload), findsNothing);
  });

  testWidgets('loading remains pending until provider completes', (
    tester,
  ) async {
    final pending = Completer<BookingDto>();
    final repo = _TicketRepository((_) => pending.future);
    await _pump(tester, repo, settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Đã thanh toán'), findsNothing);
    expect(repo.lookupIds, [_id]);
    pending.complete(_booking());
    await tester.pumpAndSettle();
    expect(find.text('Movie snapshot supplied'), findsOneWidget);
  });

  testWidgets('error retry invalidates lookup for the same booking ID', (
    tester,
  ) async {
    var calls = 0;
    final repo = _TicketRepository((_) async {
      calls++;
      if (calls == 1) throw StateError('Supplied lookup failure');
      return _booking();
    });
    await _pump(tester, repo);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text(_payload), findsNothing);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(repo.lookupIds, [_id, _id]);
    expect(find.text('Movie snapshot supplied'), findsOneWidget);
  });

  for (final width in [320.0, 430.0, 768.0]) {
    testWidgets('ticket at $width px is scrollable without clipped values', (
      tester,
    ) async {
      const longCode =
          'BK-SUPPLIED-LONG-IDENTIFIER-RETAINED-WITHOUT-CLIPPING-90817-90817-90817';
      final booking = _booking(longText: true, bookingCode: longCode);
      await _pump(
        tester,
        _TicketRepository((_) async => booking),
        size: Size(width, 844),
      );
      expect(find.text(booking.movieTitleSnapshot!), findsOneWidget);
      final code = tester.widget<SelectableText>(
        find.byWidgetPredicate(
          (widget) => widget is SelectableText && widget.data == longCode,
        ),
      );
      expect(code.data, longCode);
      expect(code.maxLines, isNull);
      final closeSize = tester.getSize(find.byTooltip('Đóng vé'));
      expect(closeSize.width, greaterThanOrEqualTo(48));
      expect(closeSize.height, greaterThanOrEqualTo(48));
      await _reveal(tester, find.byKey(const ValueKey('ticket-payload')));
      final payload = tester.widget<SelectableText>(
        find.byKey(const ValueKey('ticket-payload')),
      );
      expect(payload.data, _payload);
      expect(payload.maxLines, isNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('200 percent text at 320 px retains long metadata and payload', (
    tester,
  ) async {
    final booking = _booking(longText: true);
    await _pump(
      tester,
      _TicketRepository((_) async => booking),
      size: const Size(320, 844),
      textScale: 2,
    );
    expect(find.text(booking.movieTitleSnapshot!), findsOneWidget);
    await _reveal(tester, find.text(booking.cinemaNameSnapshot!));
    final cinema = tester.widget<Text>(find.text(booking.cinemaNameSnapshot!));
    expect(cinema.maxLines, isNull);
    await _reveal(tester, find.byKey(const ValueKey('ticket-payload')));
    expect(tester.takeException(), isNull);
  });
}
