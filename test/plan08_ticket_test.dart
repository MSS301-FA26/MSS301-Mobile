import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mss301_mobile/features/orders/data/repositories/booking_providers.dart';
import 'package:mss301_mobile/features/orders/data/repositories/remote_booking_repository.dart';
import 'package:mss301_mobile/features/orders/presentation/providers/orders_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/features/auth/application/auth_session.dart';
import 'package:mss301_mobile/features/auth/data/auth_models.dart';
import 'package:mss301_mobile/features/booking/application/booking_completion_controller.dart';
import 'package:mss301_mobile/features/booking/application/ticket_export_service.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_dto.dart';
import 'package:mss301_mobile/features/seat/data/repositories/seat_hold_providers.dart';
import 'package:mss301_mobile/features/seat/data/repositories/seat_hold_repository.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/features/booking/presentation/pages/ticket_page.dart';

import 'support/fake_auth_session.dart';

import 'package:mss301_mobile/app/app.dart';
import 'package:mss301_mobile/core/routing/app_router.dart';

BookingDto plan08Booking({
  String status = 'PAID',
  int owner = 5101,
  String? qr = 'CINEMA:QA-ONLY:42',
}) => BookingDto.fromJson({
  'id': 42,
  'bookingCode': 'QA-ONLY',
  'userId': owner,
  'movieId': 2,
  'showtimeId': 1,
  'movieTitleSnapshot': 'Phim kiểm thử',
  'cinemaNameSnapshot': 'Rạp kiểm thử',
  'roomNameSnapshot': 'Phòng 1',
  'showtimeStartSnapshot': '2026-10-15T10:00:00',
  'subtotal': 100000,
  'discountAmount': 0,
  'totalAmount': 100000,
  'status': status,
  'qrCode': qr,
  'createdAt': '2026-10-13T06:00:00Z',
  'seats': [
    {
      'id': 1,
      'seatId': 11,
      'showtimeId': 1,
      'rowLabel': 'A',
      'seatNumber': 1,
      'seatLabel': 'A1',
      'seatType': 'STANDARD',
      'unitPrice': 100000,
      'status': 'BOOKED',
    },
  ],
  'tickets': [],
  'foods': [],
});

class _Auth extends FakeAuthSessionController {
  _Auth() : super(authenticatedCustomerState());
  void changeUser(int id) => state = AuthState(
    status: AuthStatus.authenticated,
    session: AuthSession(
      accessToken: 'test',
      refreshToken: 'test',
      tokenType: 'Bearer',
      expiresInMs: 1,
      roles: const ['CUSTOMER'],
      user: AuthUser(
        id: id,
        email: 'test@example.test',
        fullName: 'Test',
        roles: const ['CUSTOMER'],
      ),
    ),
  );
}

class Plan08SeatRepository implements SeatHoldRepository {
  Plan08SeatRepository(this.booking);
  BookingDto booking;
  int calls = 0;
  @override
  bool get canEnterMockCheckout => false;
  @override
  Future<BookingDto> getBooking(int id) async {
    calls++;
    return booking;
  }

  @override
  Future<BookingDto> hold(HoldSeatsRequestDto request) =>
      throw UnimplementedError();
  @override
  Future<BookingDto> cancel(int id) => throw UnimplementedError();
}

class _Exporter implements TicketExportService {
  bool fails = false;
  int calls = 0;
  @override
  Future<TicketExportResult> save(TicketDocument document) async {
    calls++;
    if (fails) throw StateError('Device denied');
    return TicketExportResult.cancelled;
  }

  @override
  Future<TicketExportResult> share(TicketDocument document, Rect origin) =>
      save(document);
}

class _HistoryAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode({
      'success': true,
      'data': {
        'content': [
          for (final uid in [5101, 5102])
            {
              'id': uid,
              'bookingCode': 'QA-$uid',
              'userId': uid,
              'movieId': 2,
              'showtimeId': 1,
              'subtotal': 0,
              'discountAmount': 0,
              'totalAmount': 0,
              'status': 'PAID',
              'createdAt': '2026-10-13T06:00:00Z',
            },
        ],
        'totalPages': 1,
      },
    }),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'ticket cache cannot reveal account A ticket to account B or guest',
    () async {
      final repository = Plan08SeatRepository(plan08Booking());
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(_Auth.new),
          seatHoldRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final listener = container.listen(ticketBookingProvider(42), (_, _) {});
      addTearDown(listener.close);
      expect(
        (await container.read(ticketBookingProvider(42).future))!.userId,
        5101,
      );
      (container.read(authSessionProvider.notifier) as _Auth).changeUser(5102);
      expect(await container.read(ticketBookingProvider(42).future), isNull);
      repository.booking = plan08Booking(owner: 5102);
      container.invalidate(ticketBookingProvider(42));
      expect(
        (await container.read(ticketBookingProvider(42).future))!.userId,
        5102,
      );
      final calls = repository.calls;
      await container.read(authSessionProvider.notifier).logout();
      expect(await container.read(ticketBookingProvider(42).future), isNull);
      expect(repository.calls, calls);
    },
  );

  test(
    'history switches account and clears on logout without mixing users',
    () async {
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(_Auth.new),
          bookingRepositoryProvider.overrideWithValue(
            RemoteBookingRepository(
              Dio()..httpClientAdapter = _HistoryAdapter(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final listener = container.listen(ordersProvider, (_, _) {});
      addTearDown(listener.close);
      expect((await container.read(ordersProvider.future)).single.id, 5101);
      (container.read(authSessionProvider.notifier) as _Auth).changeUser(5102);
      expect((await container.read(ordersProvider.future)).single.id, 5102);
      await container.read(authSessionProvider.notifier).logout();
      expect(await container.read(ordersProvider.future), isEmpty);
    },
  );

  test(
    'PDF exports PAID payload, USED history and rejects unissued tickets',
    () async {
      final builder = TicketDocumentBuilder();
      final output = Directory('build/qa/plan08')..createSync(recursive: true);
      for (final status in ['PAID', 'USED']) {
        final document = await builder.build(plan08Booking(status: status));
        expect(document.bytes.take(4), [37, 80, 68, 70]);
        File('${output.path}/$status.pdf').writeAsBytesSync(document.bytes);
      }
      for (final status in [
        'HOLDING',
        'PENDING_PAYMENT',
        'CANCELLED',
        'EXPIRED',
        'REFUNDED',
      ]) {
        await expectLater(
          builder.build(plan08Booking(status: status)),
          throwsStateError,
        );
      }
      await expectLater(
        builder.build(plan08Booking(qr: null)),
        throwsStateError,
      );
    },
  );

  testWidgets('all booking statuses expose only valid QR and actions', (
    tester,
  ) async {
    final repository = Plan08SeatRepository(plan08Booking());
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    appRouter.go(AppRoutes.ticket(42));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(_Auth.new),
          seatHoldRepositoryProvider.overrideWithValue(repository),
        ],
        child: const CinePremierApp(),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TicketPage)),
    );
    for (final status in [
      'HOLDING',
      'PENDING_PAYMENT',
      'PAID',
      'USED',
      'CANCELLED',
      'EXPIRED',
      'REFUNDED',
    ]) {
      repository.booking = plan08Booking(status: status);
      container.invalidate(ticketBookingProvider(42));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('ticket-qr')),
        status == 'PAID' ? findsOneWidget : findsNothing,
      );
      expect(
        find.byKey(const ValueKey('ticket-save')),
        ['PAID', 'USED'].contains(status) ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Tiếp tục đặt vé'),
        ['HOLDING', 'PENDING_PAYMENT'].contains(status)
            ? findsOneWidget
            : findsNothing,
      );
    }
    repository.booking = plan08Booking(qr: null);
    container.invalidate(ticketBookingProvider(42));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ticket-save')), findsNothing);
    expect(find.textContaining('Mã QR chưa được cập nhật'), findsOneWidget);
  });

  testWidgets(
    'export revalidates USED status and handles save failure without fake success',
    (tester) async {
      final repository = Plan08SeatRepository(plan08Booking());
      final exporter = _Exporter();
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      appRouter.go(AppRoutes.ticket(42));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_Auth.new),
            seatHoldRepositoryProvider.overrideWithValue(repository),
            ticketExportServiceProvider.overrideWithValue(exporter),
          ],
          child: const CinePremierApp(),
        ),
      );
      await tester.pumpAndSettle();
      repository.booking = plan08Booking(status: 'EXPIRED');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('ticket-save')),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('ticket-save')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ticket-save')));
      await tester.pumpAndSettle();
      expect(exporter.calls, 0);
      expect(find.byKey(const ValueKey('ticket-qr')), findsNothing);
      repository.booking = plan08Booking(status: 'USED');
      await tester.tap(find.text('Tải lại đơn'));
      await tester.pumpAndSettle();
      expect(find.text('Vé đã được sử dụng'), findsOneWidget);
      expect(find.byKey(const ValueKey('ticket-qr')), findsNothing);
      exporter.fails = true;
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('ticket-save')),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('ticket-save')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ticket-save')));
      await tester.pumpAndSettle();
      expect(exporter.calls, 1);
      expect(find.textContaining('Không thể lưu/chia sẻ vé.'), findsOneWidget);
      expect(find.text('Đã lưu vé PDF.'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
