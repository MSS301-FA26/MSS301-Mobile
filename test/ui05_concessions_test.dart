import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/money/vnd_money.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/features/food/presentation/pages/standalone_food_page.dart';
import 'package:mss301_mobile/features/food/presentation/widgets/food_product_card.dart';
import 'package:mss301_mobile/features/food/presentation/widgets/food_cart_bar.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';
import 'package:mss301_mobile/features/movie/data/models/cinema_dto.dart';
import 'package:mss301_mobile/features/movie/data/models/food_quote_dto.dart';

import 'support/pump_test_app.dart';

FoodProductDto product({
  bool combo = false,
  FoodItemStatus status = FoodItemStatus.active,
  String? imageUrl,
}) => FoodProductDto(
  id: 7,
  name: 'Combo bắp caramel và nước ngọt kích cỡ lớn dành cho cả gia đình',
  description: 'Hai phần bắp, hai nước lớn và nhiều lựa chọn hương vị.',
  price: const VndMoney(1234567),
  isCombo: combo,
  status: status,
  imageUrl: imageUrl,
);

const cinemas = [
  CinemaDto(
    id: 1,
    name: 'Central',
    address: 'Address 1',
    city: 'HCM',
    active: true,
  ),
  CinemaDto(
    id: 2,
    name: 'Riverside',
    address: 'Address 2',
    city: 'HCM',
    active: true,
  ),
];

void main() {
  testWidgets(
    'cart CTA opens missing pickup selection without losing food or submitting order',
    (tester) async {
      await pumpTestApp(
        tester,
        initialLocation: AppRoutes.foodShop,
        size: const Size(390, 950),
        providerOverrides: [
          standaloneFoodCatalogProvider.overrideWith(
            (ref) async => (products: [product()], cinemas: cinemas),
          ),
        ],
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('food-plus-item:7')),
      );
      await tester.tap(find.byKey(const ValueKey('food-plus-item:7')));
      await tester.pump();
      expect(find.text('Chọn rạp nhận'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('food-create-order')));
      await tester.pumpAndSettle();
      expect(find.text('Chọn rạp nhận bắp nước'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('food-pickup-2')));
      await tester.pumpAndSettle();
      expect(find.text('Xác nhận đơn'), findsOneWidget);
      expect(find.text('1 sản phẩm • Tạm tính'), findsOneWidget);
      expect(find.text('Riverside\nAddress 2'), findsOneWidget);
      expect(find.byType(StandaloneFoodPage), findsOneWidget);
      final pickup = tester.widget<DropdownButtonFormField<int>>(
        find.byType(DropdownButtonFormField<int>),
      );
      expect(pickup.initialValue, 2);
    },
  );

  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    testWidgets(
      'food long names, large price and cart fit $width with large text',
      (tester) async {
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
                body: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: FoodProductCard(
                          product: product(),
                          quantity: 8,
                          onChange: (_) {},
                        ),
                      ),
                    ),
                    FoodCartBar(
                      total: const VndMoney(9876536),
                      quantity: 8,
                      detail: 'Cinema Central with a very long pickup location',
                      label: 'Xác nhận đơn',
                      buttonKey: const ValueKey('confirm'),
                      onContinue: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(
          tester
              .widget<IconButton>(
                find.byKey(const ValueKey('food-plus-item:7')),
              )
              .onPressed,
          isNull,
        );
        expect(
          tester
              .widget<IconButton>(
                find.byKey(const ValueKey('food-minus-item:7')),
              )
              .onPressed,
          isNotNull,
        );
        expect(
          find.byKey(const ValueKey('confirm')).hitTestable(),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('unavailable item can be removed while adding stays blocked', (
    tester,
  ) async {
    var delta = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FoodProductCard(
            product: product(status: FoodItemStatus.outOfStock),
            quantity: 2,
            onChange: (value) => delta = value,
          ),
        ),
      ),
    );
    expect(find.text('Tạm hết hàng'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('food-plus-item:7')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('food-minus-item:7')));
    expect(delta, -1);
  });

  testWidgets('broken image keeps the reserved frame and food fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FoodProductCard(
            product: product(imageUrl: 'https://invalid.example/missing.png'),
            quantity: 0,
            onChange: (_) {},
          ),
        ),
      ),
    );
    final frame = find.byKey(const ValueKey('food-image-item:7'));
    final before = tester.getSize(frame);
    await tester.pumpAndSettle();
    expect(tester.getSize(frame), before);
    expect(find.byIcon(Icons.local_drink_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'standalone cart preserves item/combo identity and quantity after pickup change',
    (tester) async {
      await pumpTestApp(
        tester,
        initialLocation: AppRoutes.foodShop,
        size: const Size(390, 950),
        providerOverrides: [
          standaloneFoodCatalogProvider.overrideWith(
            (ref) async =>
                (products: [product(), product(combo: true)], cinemas: cinemas),
          ),
        ],
      );
      for (var i = 0; i < 8; i++) {
        final plus = find.byKey(const ValueKey('food-plus-item:7'));
        await tester.ensureVisible(plus);
        await tester.tap(plus);
        await tester.pump();
      }
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('food-plus-item:7')))
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('food-plus-combo:7')),
      );
      await tester.tap(find.byKey(const ValueKey('food-plus-combo:7')));
      await tester.pump();
      expect(find.text('9 sản phẩm • Tạm tính'), findsOneWidget);
      final pickup = find.byType(DropdownButtonFormField<int>);
      await tester.ensureVisible(pickup);
      await tester.tap(pickup);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Central').last);
      await tester.pumpAndSettle();
      await tester.tap(pickup);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Riverside').last);
      await tester.pumpAndSettle();
      expect(find.text('9 sản phẩm • Tạm tính'), findsOneWidget);
      expect(find.text('Riverside\nAddress 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
