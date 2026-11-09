import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/money/vnd_money.dart';
import 'package:mss301_mobile/core/routing/app_router.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/features/food/data/models/food_order_dto.dart';
import 'package:mss301_mobile/features/food/data/repositories/food_order_providers.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_enums.dart';
import 'package:mss301_mobile/features/orders/presentation/models/ticket_order.dart';
import 'package:mss301_mobile/features/orders/presentation/providers/orders_provider.dart';

import 'support/pump_test_app.dart';

TicketOrder _ticket(int id, BookingStatus status) => TicketOrder(
  id: id,
  ticketCode: 'BK-$id',
  movieId: 1,
  movieTitle: 'Phim $id',
  moviePoster: '',
  ageRating: 'T13',
  format: '2D',
  cinemaLocation: 'CinePremier',
  roomName: 'Phòng 1',
  showtimeAt: DateTime.utc(2026, 11, 5),
  seats: const ['A01'],
  seatsTypeLabel: '1 vé người lớn',
  concessionsSummary: 'Không kèm F&B',
  totalPrice: const VndMoney(100000),
  status: status,
);

FoodOrderDto _foodOrder(int id, FoodOrderStatus status) => FoodOrderDto(
  id: id,
  orderCode: 'FO-$id',
  bookingId: id.isEven ? 100 + id : null,
  bookingCode: id.isEven ? 'BK-${100 + id}' : null,
  status: status,
  totalAmount: const VndMoney(50000),
  createdAt: DateTime.utc(2026, 11, id),
  items: const [],
);

void main() {
  testWidgets('ticket and food order tabs filter outcomes independently', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      initialLocation: AppRoutes.orders,
      size: const Size(390, 844),
      providerOverrides: [
        ordersProvider.overrideWith(
          (ref) async => [
            _ticket(1, BookingStatus.paid),
            _ticket(2, BookingStatus.cancelled),
          ],
        ),
        myFoodOrdersProvider.overrideWith(
          (ref) async => [
            _foodOrder(3, FoodOrderStatus.paid),
            _foodOrder(4, FoodOrderStatus.cancelled),
          ],
        ),
      ],
    );

    expect(find.text('Lịch sử vé'), findsOneWidget);
    expect(find.text('Sắp chiếu'), findsNothing);
    expect(find.byKey(const ValueKey('order-ticket-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('order-ticket-2')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('orders-filter-successful')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('order-ticket-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('order-ticket-2')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('orders-filter-unsuccessful')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('order-ticket-1')), findsNothing);
    expect(find.byKey(const ValueKey('order-ticket-2')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('orders-tab-food')));
    await tester.pumpAndSettle();
    expect(find.text('Đơn bắp nước'), findsOneWidget);
    expect(find.text('FO-3'), findsOneWidget);
    expect(find.text('FO-4'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('FO-4')).dy,
      lessThan(tester.getTopLeft(find.text('FO-3')).dy),
    );

    await tester.tap(find.byKey(const ValueKey('food-filter-standalone')));
    await tester.pumpAndSettle();
    expect(find.text('FO-3'), findsOneWidget);
    expect(find.text('FO-4'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('food-filter-with-ticket')));
    await tester.pumpAndSettle();
    expect(find.text('FO-3'), findsNothing);
    expect(find.text('FO-4'), findsOneWidget);
    expect(appRouter.routeInformationProvider.value.uri.path, AppRoutes.orders);
  });
}
