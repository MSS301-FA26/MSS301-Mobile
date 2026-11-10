import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mss301_mobile/core/money/vnd_money.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_enums.dart';
import 'package:mss301_mobile/features/orders/presentation/models/ticket_order.dart';
import 'package:mss301_mobile/features/orders/presentation/widgets/order_card.dart';
import 'package:mss301_mobile/features/food/presentation/widgets/food_order_card.dart';
import 'package:mss301_mobile/features/food/data/models/food_order_dto.dart';
import 'package:mss301_mobile/features/booking/application/booking_completion_controller.dart';
import 'package:mss301_mobile/shared/widgets/app_button.dart';

import 'plan08_ticket_test.dart' as fixtures;
import 'support/pump_test_app.dart';

TicketOrder order(BookingStatus status) => TicketOrder(
  id: 42,
  ticketCode: 'BK-20261015-VERY-LONG-ORDER-CODE-1234567890',
  movieId: 1,
  movieTitle: 'Một bộ phim với tên dài dành cho kiểm tra danh sách đơn hàng',
  moviePoster: '',
  ageRating: 'T18',
  format: '2D Phụ đề Anh và Việt',
  cinemaLocation: 'Cinema Central với tên rạp và phòng rất dài',
  roomName: 'Phòng 03',
  showtimeAt: DateTime.utc(2026, 10, 16, 3),
  seats: const ['A01', 'A02', 'A03', 'A04', 'A05', 'A06', 'A07', 'A08'],
  seatsTypeLabel: '8 vé người lớn',
  concessionsSummary: 'Combo bắp nước dành cho gia đình × 8',
  totalPrice: const VndMoney(12345678),
  status: status,
);

void main() {
  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    testWidgets('long booking and food orders fit $width at large text', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 1000),
              textScaler: const TextScaler.linear(1.6),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    UpcomingOrderCard(
                      order: order(BookingStatus.paid),
                      onCancel: () {},
                      onOpenTicket: () {},
                    ),
                    CompletedOrderCard(
                      order: order(BookingStatus.used),
                      onBookAgain: () {},
                      onRate: () {},
                    ),
                    FoodOrderCard(
                      order: FoodOrderDto(
                        id: 7,
                        orderCode: 'FO-20261015-LONG-ORDER-CODE-1234567890',
                        status: FoodOrderStatus.pickedUp,
                        totalAmount: const VndMoney(12345678),
                        createdAt: DateTime.utc(2026, 10, 15),
                        items: const [],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.text('Mã đơn: ${order(BookingStatus.paid).ticketCode}'),
        findsNWidgets(2),
      );
      expect(find.text('Đã nhận hàng'), findsOneWidget);
    });
  }

  testWidgets('unknown booking cannot resume and only USED offers rating', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                UpcomingOrderCard(
                  order: order(BookingStatus.unknown),
                  onCancel: () {},
                  onOpenTicket: () {},
                ),
                CompletedOrderCard(
                  order: order(BookingStatus.cancelled),
                  onBookAgain: () {},
                  onRate: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final action = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Tiếp tục đặt vé'),
    );
    expect(action.onPressed, isNull);
    expect(find.text('Hoàn / Đổi vé'), findsNothing);
    expect(find.text('Xem đánh giá'), findsNothing);
    expect(find.textContaining('mock'), findsNothing);
  });

  testWidgets(
    'paid QR preserves server payload, quiet zone and fits narrow ticket',
    (tester) async {
      const payload = 'CINEMA:QA-ONLY:42';
      await pumpTestApp(
        tester,
        initialLocation: AppRoutes.ticket(42),
        size: const Size(320, 850),
        providerOverrides: [
          ticketBookingProvider(42)
              .overrideWith((ref) async => fixtures.plan08Booking(qr: payload)),
        ],
      );
      final qr = tester.widget<QrImageView>(
        find.byKey(const ValueKey('ticket-qr')),
      );
      final painter = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byKey(const ValueKey('ticket-qr')),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((widget) => widget.painter)
          .whereType<QrPainter>()
          .single;
      final expected = QrPainter(
        data: payload,
        version: QrVersions.auto,
        gapless: qr.gapless,
        eyeStyle: qr.eyeStyle,
        dataModuleStyle: qr.dataModuleStyle,
      );
      await tester.runAsync(() async {
        final actualImage = await painter.toImageData(200);
        final expectedImage = await expected.toImageData(200);
        expect(
          actualImage!.buffer.asUint8List(),
          expectedImage!.buffer.asUint8List(),
        );
      });
      expect(qr.backgroundColor, Colors.white);
      final count = QrValidator.validate(
        data: payload,
        version: QrVersions.auto,
        errorCorrectionLevel: qr.errorCorrectionLevel,
      ).qrCode!.moduleCount;
      final moduleSize = (qr.size! - qr.padding.horizontal) / count;
      expect(qr.padding.left / moduleSize, closeTo(4, .001));
      expect(
        tester.getSize(find.byKey(const ValueKey('ticket-qr'))).width,
        lessThanOrEqualTo(240),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
