import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mss301_mobile/core/money/vnd_money.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/features/booking/application/booking_completion_controller.dart';
import 'package:mss301_mobile/features/booking/presentation/pages/checkout_page.dart';
import 'package:mss301_mobile/features/booking/presentation/widgets/checkout_order_summary.dart';
import 'package:mss301_mobile/features/food/data/models/food_order_dto.dart';
import 'package:mss301_mobile/features/food/data/repositories/standalone_food_repository.dart';
import 'package:mss301_mobile/features/food/presentation/widgets/checkout_food_images_provider.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';
import 'package:mss301_mobile/features/movie/data/models/food_quote_dto.dart';
import 'package:mss301_mobile/features/movie/data/models/movie_dto.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_dto.dart';
import 'package:mss301_mobile/shared/widgets/app_image.dart';
import 'package:mss301_mobile/shared/widgets/checkout_summary.dart';

import 'support/pump_test_app.dart';
import 'quick_action_api_test.dart' as api;

BookingCompletionState order({
  bool metadata = true,
  bool missingSeat = false,
  bool aliasFoods = false,
}) {
  final expiry = DateTime.now()
      .toUtc()
      .add(const Duration(minutes: 3))
      .toIso8601String();
  final foods = [
    {
      'productId': 7,
      'isCombo': false,
      'productName': 'Nước theo snapshot đơn hàng',
      'quantity': 2,
      'unitPrice': 50000,
      'lineTotal': 100000,
    },
    {
      'productId': 7,
      'isCombo': true,
      'productName': 'Combo theo snapshot đơn hàng',
      'quantity': 1,
      'unitPrice': 75000,
      'lineTotal': 75000,
    },
  ];
  return BookingCompletionState(
    phase: BookingCompletionPhase.checkout,
    message: 'Giá mới, vui lòng xác nhận lại.',
    booking: BookingDto.fromJson({
      'id': 42,
      'bookingCode': 'QA',
      'userId': 5101,
      'showtimeId': 1002,
      'movieId': 11,
      'status': 'HOLDING',
      'movieTitleSnapshot': 'Tên booking gốc',
      'cinemaNameSnapshot': 'Rạp booking gốc',
      'totalAmount': 2702000,
      'subtotal': 2679000,
      'createdAt': DateTime.now().toIso8601String(),
      'holdExpiresAt': expiry,
    }),
    quote: CheckoutQuoteDto.fromJson({
      'quoteId': 'snapshot',
      'validUntil': expiry,
      'showtime': {
        'showtimeId': 1002,
        'movieId': 11,
        'movieTitle': 'Tên phim snapshot từ suất chiếu',
        'cinemaName': 'Rạp trong báo giá',
        'roomName': 'Phòng VIP',
        'startTime': '2026-10-17T02:50:00+07:00',
      },
      if (metadata)
        'movie': {
          'id': 11,
          'title':
              'Tên phim rất dài trong snapshot để kiểm tra đầy đủ tên phim',
          'posterUrl': 'assets/mock/movies/inception-banner.jpg',
          'ageRating': 'T18',
          'durationMinutes': 169,
        },
      if (metadata)
        'cinema': {
          'id': 1,
          'name': 'Rạp snapshot',
          'address': 'Địa chỉ rạp dài từ snapshot đơn hiện tại',
          'roomName': 'Phòng snapshot',
        },
      'seats': [
        for (var i = 1; i <= 8; i++)
          if (!missingSeat || i != 8)
            {
              'seatId': i,
              'seatLabel': 'A0$i',
              'seatType': i >= 7 ? 'COUPLE' : 'STANDARD',
              'unitPrice': 313000,
            },
      ],
      'tickets': [
        for (var i = 1; i <= 8; i++)
          {
            'seatId': i,
            'ticketType': i >= 5 ? 'STUDENT' : 'ADULT',
            'quantity': 1,
            'unitPrice': 313000,
            'lineTotal': 313000,
          },
      ],
      aliasFoods ? 'foodItems' : 'foods': foods,
      'ticketSubtotal': 2504000,
      'foodSubtotal': 175000,
      'subtotal': 2679000,
      'fees': 10000,
      'tax': 20000,
      'discount': 5000,
      'cinePointsDiscount': 2000,
      'total': 2702000,
    }),
    products: const [
      FoodProductDto(
        id: 7,
        name: 'Tên catalog mới',
        price: VndMoney(9999999),
        status: FoodItemStatus.active,
        isCombo: false,
        imageUrl: 'https://example.test/item.jpg',
      ),
      FoodProductDto(
        id: 7,
        name: 'Combo catalog mới',
        price: VndMoney(9999999),
        status: FoodItemStatus.active,
        isCombo: true,
        imageUrl: 'https://example.test/combo.jpg',
      ),
    ],
  );
}

class Completion extends BookingCompletionController {
  Completion(this.initial);
  final BookingCompletionState initial;
  @override
  BookingCompletionState build() => initial;
  @override
  Future<void> load(int bookingId) async {}
}

Future<void> open(
  WidgetTester tester,
  BookingCompletionState state, {
  double width = 390,
  double scale = 1,
  MovieDto? extra,
  bool error = false,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await pumpTestApp(
    tester,
    initialLocation: AppRoutes.checkout(42),
    size: Size(width, 1000),
    providerOverrides: [
      bookingCompletionProvider.overrideWith(() => Completion(state)),
      checkoutMovieMetadataProvider(11).overrideWith((ref) async {
        if (error) throw Exception('catalog unavailable');
        return extra;
      }),
    ],
  );
}

Future<void> reveal(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      250,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  } else {
    await tester.ensureVisible(target);
  }
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    testWidgets(
      '8 seats and mixed tickets, food, immutable total and fixed CTA at $width large text',
      (tester) async {
        final state = order();
        await open(tester, state, width: width, scale: 1.6);
        expect(
          find.byKey(const ValueKey('checkout-movie-title')),
          findsOneWidget,
        );
        expect(find.textContaining('từ đủ 18 tuổi'), findsOneWidget);
        expect(find.text('02:50 • 17/10/2026'), findsOneWidget);
        for (var i = 1; i <= 8; i++) {
          final row = find.byKey(ValueKey('checkout-ticket-$i'));
          await reveal(tester, row);
          expect(
            find.descendant(of: row, matching: find.text('A0$i')),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: row,
              matching: find.text(i >= 5 ? 'Vé sinh viên' : 'Vé người lớn'),
            ),
            findsOneWidget,
          );
        }
        await reveal(
          tester,
          find.byKey(const ValueKey('checkout-food-combo:7')),
        );
        expect(
          find.byKey(const ValueKey('checkout-pay')).hitTestable(),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('booking-hold-countdown')).hitTestable(),
          findsOneWidget,
        );
        expect(
          find.text('Giá mới, vui lòng xác nhận lại.').hitTestable(),
          findsOneWidget,
        );
        final bar = tester.widget<PaymentActionBar>(
          find.byType(PaymentActionBar),
        );
        expect(bar.total.amount, 2702000);
        expect(find.text('Tên catalog mới'), findsNothing);
        expect(find.text(const VndMoney(9999999).format()), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'matching item/combo images never replace names, quantities or quote money',
    (tester) async {
      await open(tester, order());
      for (final entry in ['item', 'combo']) {
        final target = find.byKey(ValueKey('checkout-food-$entry:7'));
        await reveal(tester, target);
        final line = tester.widget<CheckoutFoodSummaryLine>(target);
        expect(line.imageUrl, 'https://example.test/$entry.jpg');
        expect(line.unitPrice.amount, entry == 'item' ? 50000 : 75000);
        expect(line.quantity, entry == 'item' ? 2 : 1);
      }
      await reveal(tester, find.text('Phương thức'));
      final amounts = tester.widgetList<CheckoutLine>(
        find.byType(CheckoutLine),
      );
      expect(
        amounts.any((line) => line.label == 'Phí' && line.value == '10.000đ'),
        isTrue,
      );
      expect(
        amounts.any((line) => line.label == 'Thuế' && line.value == '20.000đ'),
        isTrue,
      );
      expect(
        amounts.any(
          (line) => line.label == 'Giảm giá' && line.value == '-5.000đ',
        ),
        isTrue,
      );
      expect(
        tester
            .widget<PaymentActionBar>(find.byType(PaymentActionBar))
            .total
            .amount,
        2702000,
      );
    },
  );

  testWidgets(
    'missing seat label and metadata do not crash, optional catalog failure never blocks pay',
    (tester) async {
      await open(
        tester,
        order(metadata: false, missingSeat: true),
        error: true,
      );
      await reveal(tester, find.byKey(const ValueKey('checkout-ticket-8')));
      expect(find.text('Ghế #8'), findsOneWidget);
      expect(
        tester
            .widget<PaymentActionBar>(find.byType(PaymentActionBar))
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'catalog metadata enriches only missing fields and cannot replace snapshot title or price',
    (tester) async {
      await open(
        tester,
        order(metadata: false),
        extra: MovieDto.fromJson({
          'id': 11,
          'title': 'New catalog title',
          'status': 'NOW_SHOWING',
          'posterUrl': 'assets/missing.jpg',
          'ageRating': 'T16',
          'durationMinutes': 140,
        }),
      );
      expect(find.text('Tên phim snapshot từ suất chiếu'), findsOneWidget);
      expect(find.text('New catalog title'), findsNothing);
      expect(find.textContaining('từ đủ 16 tuổi'), findsOneWidget);
      expect(
        tester
            .widget<AppImage>(
              find.byKey(const ValueKey('checkout-movie-poster')),
            )
            .asset,
        'assets/missing.jpg',
      );
      expect(
        tester
            .widget<PaymentActionBar>(find.byType(PaymentActionBar))
            .total
            .amount,
        2702000,
      );
    },
  );

  testWidgets(
    'foodItems alias is shown once and editing food preserves booking deadline',
    (tester) async {
      final state = order(aliasFoods: true);
      await open(tester, state);
      final button = find.byKey(const ValueKey('checkout-edit-food'));
      await reveal(tester, button);
      expect(
        find.byKey(const ValueKey('checkout-food-combo:7')),
        findsOneWidget,
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('concessions-continue')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('booking-hold-countdown')),
        findsOneWidget,
      );
      final current = ProviderScope.containerOf(
        tester.element(find.byKey(const ValueKey('booking-hold-countdown'))),
      ).read(bookingCompletionProvider);
      expect(current.booking?.id, state.booking?.id);
      expect(current.booking?.holdExpiresAt, state.booking?.holdExpiresAt);
      expect(tester.takeException(), isNull);
    },
  );

  test('standalone pickup fields map from BE snapshot, absence stays null', () {
    final data = api.order()
      ..addAll({
        'cinemaId': 9,
        'cinemaName': 'Snapshot Pickup',
        'cinemaAddress': 'Snapshot Address',
      });
    final value = FoodOrderDto.fromJson(data);
    expect(value.cinemaId, 9);
    expect(value.cinemaName, 'Snapshot Pickup');
    expect(value.cinemaAddress, 'Snapshot Address');
    expect(FoodOrderDto.fromJson(api.order()).cinemaName, isNull);
  });

  for (final location in [false, true]) {
    testWidgets(
      'standalone location=$location renders order context when catalog images fail',
      (tester) async {
        final data = api.order(status: 'EXPIRED')
          ..addAll({
            if (location) 'cinemaName': 'Snapshot Pickup',
            if (location) 'cinemaAddress': 'Snapshot Address',
            'items': [
              {
                'id': 1,
                'productId': 7,
                'isCombo': true,
                'productName': 'Snapshot combo',
                'quantity': 2,
                'unitPrice': 60000,
                'lineTotal': 120000,
              },
            ],
          });
        await pumpTestApp(
          tester,
          initialLocation: AppRoutes.foodOrderDetail(9),
          size: const Size(320, 950),
          providerOverrides: [
            standaloneFoodRepositoryProvider.overrideWithValue(
              StandaloneFoodRepository(
                api.responding((_) => api.envelope(data)),
              ),
            ),
            checkoutFoodImagesProvider.overrideWith((ref) async => {}),
          ],
        );
        expect(
          find.text('Snapshot Pickup'),
          location ? findsOneWidget : findsNothing,
        );
        expect(find.text('Thông tin suất chiếu'), findsNothing);
        expect(
          find.byKey(const ValueKey('checkout-movie-poster')),
          findsNothing,
        );
        expect(
          tester
              .widget<PaymentActionBar>(find.byType(PaymentActionBar))
              .total
              .amount,
          120000,
        );
        await reveal(tester, find.text('Snapshot combo'));
        expect(find.text('Snapshot combo'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
