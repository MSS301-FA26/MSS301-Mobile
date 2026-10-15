import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/features/booking/application/booking_completion_controller.dart';
import 'package:mss301_mobile/features/movie/data/models/food_quote_dto.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_dto.dart';
import 'package:mss301_mobile/features/payment/data/models/payment_dto.dart';
import 'package:mss301_mobile/features/food/data/repositories/standalone_food_repository.dart';

import 'quick_action_api_test.dart' as fixtures;
import 'support/pump_test_app.dart';

BookingCompletionState snapshot(BookingCompletionPhase phase) {
  final expiry = DateTime.now()
      .toUtc()
      .add(const Duration(minutes: 3))
      .toIso8601String();
  return BookingCompletionState(
    phase: phase,
    message: phase == BookingCompletionPhase.checkout
        ? 'Giá đã được cập nhật. Vui lòng kiểm tra và xác nhận lại.'
        : null,
    booking: BookingDto.fromJson({
      'id': 42,
      'bookingCode': 'BOOKING-LONG',
      'userId': 1,
      'showtimeId': 83,
      'movieId': 11,
      'status': phase == BookingCompletionPhase.ticketReady
          ? 'PAID'
          : 'HOLDING',
      'subtotal': 1234567,
      'totalAmount': 1234567,
      'createdAt': DateTime.now().toIso8601String(),
      'holdExpiresAt': expiry,
    }),
    quote: CheckoutQuoteDto.fromJson({
      'quoteId': 'qa',
      'validUntil': expiry,
      'showtime': {
        'showtimeId': 83,
        'movieId': 11,
        'movieTitle':
            'Một bộ phim có tên rất dài để kiểm tra nội dung đơn hàng',
        'cinemaName': 'Cinema Central với tên rạp dài',
        'roomName': 'Phòng 03',
        'startTime': '2026-10-16T02:50:00',
      },
      'ticketSubtotal': 313000,
      'foodSubtotal': 921567,
      'total': 1234567,
      'foods': [
        for (var i = 0; i < 8; i++)
          {
            'productId': i + 1,
            'productName': 'Combo bắp nước tên dài dành cho gia đình $i',
            'isCombo': true,
            'quantity': 8,
            'unitPrice': 100000,
            'lineTotal': 800000,
          },
      ],
    }),
    payment: phase == BookingCompletionPhase.checkout
        ? null
        : PaymentDto.fromJson({
            'id': 9,
            'bookingId': 42,
            'userId': 1,
            'provider': 'VNPAY',
            'amount': 1234567,
            'status': 'PENDING',
            'paymentUrl': 'https://sandbox.vnpayment.vn/qa',
            'createdAt': DateTime.now().toIso8601String(),
          }),
  );
}

class _FixedCompletion extends BookingCompletionController {
  _FixedCompletion(this.initial);
  final BookingCompletionState initial;
  @override
  BookingCompletionState build() => initial;
  @override
  Future<void> attachPayment(int paymentId) async {}
}

void main() {
  for (final width in [320.0, 430.0]) {
    testWidgets(
      'checkout long order keeps price update and payment visible at $width',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpTestApp(
          tester,
          initialLocation: AppRoutes.checkout(42),
          size: Size(width, 1000),
          providerOverrides: [
            bookingCompletionProvider.overrideWith(
              () => _FixedCompletion(snapshot(BookingCompletionPhase.checkout)),
            ),
          ],
        );
        expect(
          find.byKey(const ValueKey('checkout-pay')).hitTestable(),
          findsOneWidget,
        );
        expect(
          find.textContaining('Giá đã được cập nhật').hitTestable(),
          findsOneWidget,
        );
        await tester.drag(find.byType(ListView).first, const Offset(0, -700));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('checkout-pay')).hitTestable(),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('booking-hold-countdown')).hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final phase in [
    BookingCompletionPhase.paymentPending,
    BookingCompletionPhase.verifyingBooking,
    BookingCompletionPhase.error,
    BookingCompletionPhase.paymentFailed,
    BookingCompletionPhase.ticketReady,
  ]) {
    testWidgets(
      'payment $phase exposes QR action only after booking confirmation',
      (tester) async {
        await pumpTestApp(
          tester,
          initialLocation: AppRoutes.payment(9),
          size: const Size(390, 950),
          providerOverrides: [
            bookingCompletionProvider.overrideWith(
              () => _FixedCompletion(snapshot(phase)),
            ),
          ],
        );
        expect(
          find.byKey(const ValueKey('open-ticket')),
          phase == BookingCompletionPhase.ticketReady
              ? findsOneWidget
              : findsNothing,
        );
        if (phase == BookingCompletionPhase.error) {
          expect(find.text('Chưa xác định kết quả'), findsOneWidget);
          expect(find.text('Thanh toán thất bại'), findsNothing);
        }
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'expired food deadline keeps status pending and offers checking instead of payment',
    (tester) async {
      final data = fixtures.order();
      data['expiresAt'] = '2000-01-01T00:00:00Z';
      await pumpTestApp(
        tester,
        initialLocation: AppRoutes.foodOrderDetail(9),
        providerOverrides: [
          standaloneFoodRepositoryProvider.overrideWithValue(
            StandaloneFoodRepository(
              fixtures.responding((_) => fixtures.envelope(data)),
            ),
          ),
        ],
      );
      expect(find.text('Chờ thanh toán'), findsOneWidget);
      expect(find.byKey(const ValueKey('food-pay')), findsNothing);
      expect(
        find.byKey(const ValueKey('food-refresh')).hitTestable(),
        findsOneWidget,
      );
      expect(find.text('Thanh toán thất bại'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
