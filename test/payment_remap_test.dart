import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/routing/app_router.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/core/theme/app_theme.dart';
import 'package:mss301_mobile/features/booking/application/booking_completion_controller.dart';
import 'package:mss301_mobile/features/booking/presentation/pages/payment_result_page.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_dto.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_enums.dart';
import 'package:mss301_mobile/features/payment/data/models/payment_dto.dart';
import 'package:mss301_mobile/features/payment/data/models/payment_enums.dart';
import 'package:mss301_mobile/shared/widgets/app_button.dart';

import 'support/pump_test_app.dart';

final _booking = BookingDto.fromJson({
  'id': 7419,
  'bookingCode': 'BK-7419-REFERENCE-WITH-LONG-IDENTITY',
  'userId': 19,
  'showtimeId': 1124,
  'movieId': 912,
  'movieTitleSnapshot': 'Tên phim được cung cấp rất dài cần hiển thị đầy đủ',
  'cinemaNameSnapshot': 'Rạp chiếu phim từ booking đang thanh toán',
  'roomNameSnapshot': 'Phòng chiếu được cung cấp',
  'showtimeStartSnapshot': '2026-10-10T20:30:00',
  'subtotal': 234000,
  'totalAmount': 234000,
  'discountAmount': 0,
  'loyaltyPointsRedeemed': 0,
  'status': 'PENDING_PAYMENT',
  'seats': [
    {
      'id': 3,
      'seatId': 9402,
      'showtimeId': 1124,
      'seatLabel': 'A2',
      'unitPrice': 234000,
    },
  ],
  'foods': [
    {
      'id': 43,
      'productId': 713,
      'productName': 'Bắp nước đã gắn với booking',
      'quantity': 2,
      'unitPrice': 30000,
      'lineTotal': 60000,
    },
  ],
  'createdAt': '2026-10-10T20:00:00',
});

PaymentDto _payment({
  int id = 8317,
  PaymentStatus status = PaymentStatus.pending,
  String? url = 'https://payment.test/vnpay?reference=8317',
}) => PaymentDto.fromJson({
  'id': id,
  'bookingId': _booking.id,
  'userId': 19,
  'provider': 'VNPAY',
  'amount': 7654321,
  'status': status.wireValue,
  'paymentUrl': url,
  'transactionId': 'TXN-8317-AUTHORITATIVE-REFERENCE',
  'refundAmount': 0,
  'createdAt': '2026-10-10T20:01:00',
});

BookingCompletionState _state({
  BookingCompletionPhase phase = BookingCompletionPhase.paymentPending,
  PaymentDto? payment,
  BookingDto? booking,
  String? message,
}) => BookingCompletionState(
  phase: phase,
  payment: payment ?? _payment(),
  booking: booking ?? _booking,
  message: message,
);

class _PaymentController extends BookingCompletionController {
  _PaymentController(this.initial);
  final BookingCompletionState initial;
  final attachedIds = <int>[];
  final refreshedIds = <int>[];
  final retriedBookingIds = <int>[];
  Completer<bool>? refreshResult;

  @override
  BookingCompletionState build() => initial;

  @override
  Future<void> attachPayment(int paymentId) async => attachedIds.add(paymentId);

  @override
  Future<bool> refreshPaymentStatus() async {
    refreshedIds.add(state.payment!.id);
    return refreshResult == null ? false : await refreshResult!.future;
  }

  @override
  Future<PaymentDto?> retryPayment() async {
    retriedBookingIds.add(state.booking!.id);
    final next = _payment(id: 8318);
    state = state.copyWith(
      phase: BookingCompletionPhase.paymentPending,
      payment: next,
    );
    return next;
  }
}

Future<ProviderContainer> _open(
  WidgetTester tester,
  _PaymentController controller, {
  Size size = const Size(430, 844),
}) => pumpTestApp(
  tester,
  initialLocation: AppRoutes.payment(8317),
  size: size,
  providerOverrides: [bookingCompletionProvider.overrideWith(() => controller)],
);

Future<void> _reveal(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'payment displays the supplied payable amount, not booking total',
    (tester) async {
      final controller = _PaymentController(_state());
      await _open(tester, controller);
      expect(find.text('7.654.321đ'), findsOneWidget);
      expect(find.text('234.000đ'), findsNothing);
      expect(controller.attachedIds, [8317]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'payment context keeps the supplied identifiers and booking data',
    (tester) async {
      await _open(tester, _PaymentController(_state()));
      expect(find.text(_booking.bookingCode), findsOneWidget);
      expect(find.text(_booking.movieTitleSnapshot!), findsOneWidget);
      expect(find.textContaining('A2'), findsOneWidget);
      expect(find.textContaining('8317'), findsWidgets);
      expect(find.text(_payment().transactionId!), findsOneWidget);
      expect(
        find.textContaining('Bắp nước đã gắn với booking'),
        findsOneWidget,
      );
      expect(find.textContaining('Hoàn tiền'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('browser launch and app resume do not mark payment successful', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      return true;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final controller = _PaymentController(_state());
    final container = await _open(tester, controller);
    final launch = find.byKey(const ValueKey('payment-launch'));
    await _reveal(tester, launch);
    await tester.tap(launch);
    await tester.pumpAndSettle();
    final call = calls.singleWhere((call) => call.method == 'launch');
    final arguments = call.arguments as Map;
    expect(arguments['url'], _payment().paymentUrl);
    expect(arguments['useWebView'], isFalse);
    expect(arguments['useSafariVC'], isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(
      container.read(bookingCompletionProvider).phase,
      BookingCompletionPhase.paymentPending,
    );
    expect(find.text('Booking đã được xác nhận'), findsNothing);
    expect(find.byKey(const ValueKey('open-ticket')), findsNothing);
    expect(find.byKey(const ValueKey('payment-success')), findsNothing);
    expect(find.byKey(const ValueKey('payment-failure')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'refresh CTA checks the existing payment instead of inventing success',
    (tester) async {
      final pending = Completer<bool>();
      final controller = _PaymentController(_state())..refreshResult = pending;
      final container = await _open(tester, controller);
      final refresh = find.byKey(const ValueKey('payment-refresh'));
      await _reveal(tester, refresh);
      await tester.tap(refresh);
      await tester.pump();
      expect(controller.refreshedIds, [8317]);
      expect(find.byKey(const ValueKey('open-ticket')), findsNothing);
      pending.complete(false);
      await tester.pumpAndSettle();
      expect(
        container.read(bookingCompletionProvider).phase,
        BookingCompletionPhase.paymentPending,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed payment exposes only its existing retry and exact next ID',
    (tester) async {
      final controller = _PaymentController(
        _state(
          phase: BookingCompletionPhase.paymentFailed,
          payment: _payment(status: PaymentStatus.failed),
          message: 'Giao dịch bị từ chối từ hệ thống.',
        ),
      );
      await _open(tester, controller);
      expect(find.text('Thanh toán thất bại'), findsOneWidget);
      expect(find.text('Giao dịch bị từ chối từ hệ thống.'), findsOneWidget);
      expect(find.byKey(const ValueKey('payment-launch')), findsNothing);
      expect(find.byKey(const ValueKey('payment-refresh')), findsNothing);
      final retry = find.byKey(const ValueKey('payment-retry'));
      await _reveal(tester, retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(controller.retriedBookingIds, [_booking.id]);
      expect(
        appRouter.routeInformationProvider.value.uri.toString(),
        AppRoutes.payment(8318),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'SUCCESS payment alone still requires existing booking verification',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = _PaymentController(
        _state(
          phase: BookingCompletionPhase.verifyingBooking,
          payment: _payment(status: PaymentStatus.success),
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [bookingCompletionProvider.overrideWith(() => controller)],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const PaymentResultPage(paymentId: 8317),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Đang xác minh booking'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const ValueKey('open-ticket')), findsNothing);
      expect(find.text('Booking đã được xác nhận'), findsNothing);
      expect(controller.attachedIds, [8317]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'verified ticketReady keeps the exact booking ticket destination',
    (tester) async {
      await _open(
        tester,
        _PaymentController(
          _state(
            phase: BookingCompletionPhase.ticketReady,
            payment: _payment(status: PaymentStatus.success),
            booking: _booking.copyWith(status: BookingStatus.paid),
          ),
        ),
      );
      expect(find.text('Booking đã được xác nhận'), findsOneWidget);
      expect(find.byKey(const ValueKey('payment-launch')), findsNothing);
      expect(find.byKey(const ValueKey('payment-refresh')), findsNothing);
      final ticket = find.byKey(const ValueKey('open-ticket'));
      await _reveal(tester, ticket);
      await tester.tap(ticket);
      await tester.pumpAndSettle();
      expect(
        appRouter.routeInformationProvider.value.uri.toString(),
        AppRoutes.ticket(_booking.id),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'expired payment retains showtime recovery without new refund action',
    (tester) async {
      await _open(
        tester,
        _PaymentController(
          _state(
            phase: BookingCompletionPhase.expired,
            message: 'Phiên giữ ghế đã hết.',
          ),
        ),
      );
      expect(find.text('Phiên giữ ghế đã hết'), findsOneWidget);
      expect(find.byKey(const ValueKey('payment-retry')), findsNothing);
      expect(find.byKey(const ValueKey('payment-launch')), findsNothing);
      expect(find.textContaining('Hoàn tiền'), findsNothing);
      final recover = find.text('Chọn lại suất chiếu');
      await _reveal(tester, recover);
      await tester.tap(recover);
      await tester.pumpAndSettle();
      expect(
        appRouter.routeInformationProvider.value.uri.toString(),
        AppRoutes.showtimes,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('API error keeps the exact recoverable error message', (
    tester,
  ) async {
    const error = 'Không thể lấy trạng thái giao dịch từ hệ thống.';
    await _open(
      tester,
      _PaymentController(
        _state(phase: BookingCompletionPhase.error, message: error),
      ),
    );
    expect(find.text(error), findsOneWidget);
    expect(find.byKey(const ValueKey('open-ticket')), findsNothing);
    expect(find.byKey(const ValueKey('payment-refresh')), findsOneWidget);
    expect(find.byKey(const ValueKey('payment-retry')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 430.0, 768.0]) {
    testWidgets('payment long references and amount fit at $width px', (
      tester,
    ) async {
      await _open(tester, _PaymentController(_state()), size: Size(width, 844));
      expect(find.text('7.654.321đ'), findsOneWidget);
      expect(find.text(_booking.movieTitleSnapshot!), findsOneWidget);
      final action = find.byKey(const ValueKey('payment-refresh'));
      await _reveal(tester, action);
      expect(action.hitTestable(), findsOneWidget);
      expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('payment keeps actions usable with 200 percent text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final controller = _PaymentController(_state());
    await _open(tester, controller, size: const Size(320, 844));
    final refresh = find.byKey(const ValueKey('payment-refresh'));
    await _reveal(tester, refresh);
    await tester.tap(refresh);
    await tester.pumpAndSettle();
    expect(controller.refreshedIds, [8317]);
    expect(tester.widget<AppButton>(refresh).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'legacy mock launcher returns to pending without automatic success',
    (tester) async {
      final controller = _PaymentController(
        _state(payment: _payment(url: 'mock://vnpay/8317')),
      );
      final container = await _open(tester, controller);
      expect(find.byKey(const ValueKey('payment-launch')), findsNothing);
      final launch = find.byKey(const ValueKey('payment-open-webview'));
      await _reveal(tester, launch);
      await tester.tap(launch);
      await tester.pumpAndSettle();
      expect(
        container.read(bookingCompletionProvider).phase,
        BookingCompletionPhase.paymentPending,
      );
      expect(find.textContaining('Đã mở VNPay Mock'), findsOneWidget);
      expect(find.byKey(const ValueKey('open-ticket')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
