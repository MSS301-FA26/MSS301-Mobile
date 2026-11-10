import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/money/vnd_money.dart';
import 'package:mss301_mobile/core/network/api_exception.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/features/booking/application/booking_completion_controller.dart';
import 'package:mss301_mobile/features/food/data/models/food_order_dto.dart';
import 'package:mss301_mobile/features/food/data/repositories/standalone_food_repository.dart';
import 'package:mss301_mobile/features/food/presentation/pages/standalone_food_page.dart';
import 'package:mss301_mobile/features/food/presentation/widgets/food_catalog_groups.dart';
import 'package:mss301_mobile/features/food/presentation/widgets/food_product_card.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';
import 'package:mss301_mobile/features/movie/data/models/cinema_dto.dart';
import 'package:mss301_mobile/features/movie/data/models/food_quote_dto.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_dto.dart';
import 'package:mss301_mobile/shared/widgets/app_button.dart';

import 'support/pump_test_app.dart';
import 'ui05_concessions_test.dart' as fixtures;

FoodProductDto product({
  bool combo = false,
  FoodItemStatus status = FoodItemStatus.active,
  bool description = true,
}) => FoodProductDto(
  id: 7,
  name: combo
      ? 'Combo gia đình với tên rất dài để kiểm tra'
      : 'Nước và bắp lẻ với tên rất dài để kiểm tra',
  description: description
      ? List.filled(35, 'Mô tả thành phần chính xác do API cung cấp. ').join()
      : null,
  price: const VndMoney(1234567),
  isCombo: combo,
  status: status,
  imageUrl: 'https://invalid.example/image.jpg',
);

class PendingOrder extends StandaloneFoodRepository {
  PendingOrder() : super(Dio());
  final pending = Completer<FoodOrderDto>();
  int calls = 0;
  @override
  Future<FoodOrderDto> create(
    CinemaDto cinema,
    List<({FoodProductDto product, int quantity})> cart, {
    CancelToken? cancelToken,
  }) {
    calls++;
    return pending.future;
  }
}

class FixedBooking extends BookingCompletionController {
  FixedBooking(this.initial);
  final BookingCompletionState initial;
  @override
  BookingCompletionState build() => initial;
  @override
  void returnToFood() {}
  @override
  Future<void> load(int bookingId) async {}
}

Future<void> shop(
  WidgetTester tester,
  List<FoodProductDto> products, {
  double width = 390,
  double scale = 1,
  PendingOrder? order,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await pumpTestApp(
    tester,
    initialLocation: AppRoutes.foodShop,
    size: Size(width, 900),
    providerOverrides: [
      standaloneFoodCatalogProvider.overrideWith(
        (ref) async => (products: products, cinemas: fixtures.cinemas),
      ),
      if (order != null)
        standaloneFoodRepositoryProvider.overrideWithValue(order),
    ],
  );
}

Future<void> reveal(
  WidgetTester tester,
  Finder target, {
  bool up = false,
}) async {
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      up ? -240 : 240,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
  } else {
    await tester.ensureVisible(target);
  }
  await tester.pumpAndSettle();
}

Future<void> group(WidgetTester tester, FoodCatalogGroup value) async {
  final target = find.byKey(ValueKey('food-group-${value.name}'));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('detail sheet adds the selected combo to the cart', (
    tester,
  ) async {
    await shop(tester, [product(combo: true)]);
    final details = find.byKey(const ValueKey('food-details-combo:7'));
    await reveal(tester, details);
    await tester.tap(details);
    await tester.pumpAndSettle();

    final add = find.byKey(const ValueKey('food-details-add-combo:7'));
    expect(add.hitTestable(), findsOneWidget);
    await tester.tap(add);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('food-details-sheet-combo:7')),
      findsNothing,
    );
    expect(find.text('Đã chọn 1'), findsOneWidget);
  });

  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    testWidgets(
      'long food details sheet scrolls and closes at $width with large text',
      (tester) async {
        final item = product(combo: true);
        await shop(tester, [item], width: width, scale: 1.6);
        final details = find.byKey(const ValueKey('food-details-combo:7'));
        await reveal(tester, details);
        await tester.tap(details);
        await tester.pumpAndSettle();
        final sheet = find.byKey(const ValueKey('food-details-sheet-combo:7'));
        expect(
          find.descendant(of: sheet, matching: find.text(item.name)),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: sheet,
            matching: find.text(item.description!.trim()),
          ),
          findsOneWidget,
        );
        final body = find.descendant(
          of: sheet,
          matching: find.byType(SingleChildScrollView),
        );
        await tester.drag(body, const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('food-details-close')).hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('food-details-close')));
        await tester.pumpAndSettle();
        expect(sheet, findsNothing);
        expect(
          find.byKey(const ValueKey('food-create-order')).hitTestable(),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets(
    'grouping uses isCombo and preserves all quantities, total and pickup',
    (tester) async {
      await shop(tester, [product(), product(combo: true)]);
      await group(tester, FoodCatalogGroup.items);
      final plus = find.byKey(const ValueKey('food-plus-item:7'));
      await reveal(tester, plus);
      await tester.tap(plus);
      await tester.pump();
      await group(tester, FoodCatalogGroup.combos);
      expect(find.byKey(const ValueKey('food-card-item:7')), findsNothing);
      final comboPlus = find.byKey(const ValueKey('food-plus-combo:7'));
      await reveal(tester, comboPlus);
      await tester.tap(comboPlus);
      await tester.pump();
      expect(find.text('2 sản phẩm • Tạm tính'), findsOneWidget);
      expect(find.text(const VndMoney(2469134).format()), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('food-create-order')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('food-pickup-2')));
      await tester.pumpAndSettle();
      await group(tester, FoodCatalogGroup.items);
      expect(find.text('2 sản phẩm • Tạm tính'), findsOneWidget);
      expect(find.text('Riverside'), findsWidgets);
      await reveal(tester, find.byKey(const ValueKey('food-minus-item:7')));
      await tester.tap(find.byKey(const ValueKey('food-minus-item:7')));
      await tester.pump();
      expect(find.text('1 sản phẩm • Tạm tính'), findsOneWidget);
      await group(tester, FoodCatalogGroup.combos);
      await reveal(tester, find.byKey(const ValueKey('food-minus-combo:7')));
      await tester.tap(find.byKey(const ValueKey('food-minus-combo:7')));
      await tester.pump();
      expect(find.text('Chưa chọn bắp nước'), findsOneWidget);
      expect(
        tester
            .widget<AppButton>(find.byKey(const ValueKey('food-create-order')))
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'empty group does not hide selected cart and details do not invent contents',
    (tester) async {
      await shop(tester, [product(description: false)]);
      await reveal(tester, find.byKey(const ValueKey('food-plus-item:7')));
      await tester.tap(find.byKey(const ValueKey('food-plus-item:7')));
      await tester.pump();
      await group(tester, FoodCatalogGroup.combos);
      expect(find.text('Chưa có sản phẩm trong nhóm này'), findsOneWidget);
      expect(find.text('1 sản phẩm • Tạm tính'), findsOneWidget);
      await group(tester, FoodCatalogGroup.items);
      await reveal(tester, find.byKey(const ValueKey('food-details-item:7')));
      await tester.tap(find.byKey(const ValueKey('food-details-item:7')));
      await tester.pumpAndSettle();
      expect(
        find.text('Thông tin chi tiết đang được cập nhật.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'LOW_STOCK blocks adding but permits removing selected quantity',
    (tester) async {
      var delta = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FoodProductCard(
              product: product(status: FoodItemStatus.lowStock),
              quantity: 1,
              onChange: (value) => delta = value,
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('food-plus-item:7')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('food-minus-item:7')));
      expect(delta, -1);
    },
  );

  testWidgets(
    'pending standalone submit locks changes and duplicate submit, retains draft after rejection',
    (tester) async {
      final order = PendingOrder();
      await shop(tester, [product()], order: order);
      await reveal(tester, find.byKey(const ValueKey('food-plus-item:7')));
      await tester.tap(find.byKey(const ValueKey('food-plus-item:7')));
      await tester.pump();
      final submit = find.byKey(const ValueKey('food-create-order'));
      await tester.tap(submit);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('food-pickup-1')));
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(order.calls, 1);
      expect(tester.widget<AppButton>(submit).onPressed, isNull);
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('food-group-combos')),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('food-plus-item:7')))
            .onPressed,
        isNull,
      );
      order.pending.completeError(
        const ApiException(
          type: ApiErrorType.validation,
          message: 'Hàng đã hết',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 sản phẩm • Tạm tính'), findsOneWidget);
      expect(tester.widget<AppButton>(submit).onPressed, isNotNull);
    },
  );

  testWidgets(
    'booking group switch keeps deadline and separates server ticket subtotal from food estimate',
    (tester) async {
      final deadline = DateTime.now().toUtc().add(const Duration(minutes: 3));
      final booking = BookingDto.fromJson({
        'id': 42,
        'bookingCode': 'QA',
        'userId': 5101,
        'showtimeId': 1002,
        'movieId': 2,
        'movieTitle': 'Phim QA',
        'cinemaName': 'Rạp QA',
        'roomName': 'Phòng QA',
        'showtimeStart': '2026-10-17T10:00:00+07:00',
        'status': 'HOLDING',
        'subtotal': 70000,
        'totalAmount': 70000,
        'holdExpiresAt': deadline.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
        'tickets': [
          {
            'id': 1,
            'seatId': 1,
            'ticketType': 'ADULT',
            'quantity': 1,
            'unitPrice': 70000,
            'lineTotal': 70000,
          },
        ],
      });
      final controller = FixedBooking(
        BookingCompletionState(
          phase: BookingCompletionPhase.choosingFood,
          booking: booking,
          products: [product(), product(combo: true)],
        ),
      );
      final container = await pumpTestApp(
        tester,
        initialLocation: AppRoutes.concessions(42),
        size: const Size(320, 950),
        providerOverrides: [
          bookingCompletionProvider.overrideWith(() => controller),
        ],
      );
      expect(
        find.byKey(const ValueKey('concessions-booking-summary')),
        findsOneWidget,
      );
      expect(find.text('Phim QA'), findsOneWidget);
      expect(find.text('Tiền vé: 70.000đ'), findsOneWidget);
      await group(tester, FoodCatalogGroup.combos);
      await reveal(tester, find.byKey(const ValueKey('food-plus-combo:7')));
      await tester.tap(find.byKey(const ValueKey('food-plus-combo:7')));
      await tester.pump();
      await group(tester, FoodCatalogGroup.items);
      final state = container.read(bookingCompletionProvider);
      expect(state.quantities, {'combo:7': 1});
      expect(state.booking!.holdExpiresAt, deadline);
      expect(find.text('Tiền vé: 70.000đ'), findsOneWidget);
      expect(find.text('1 sản phẩm • Tạm tính'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('concessions-continue')).hitTestable(),
        findsOneWidget,
      );
    },
  );
}
