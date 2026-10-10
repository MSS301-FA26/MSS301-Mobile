import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/money/vnd_money.dart';
import 'package:mss301_mobile/core/routing/app_router.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/core/theme/app_theme.dart';
import 'package:mss301_mobile/features/booking/application/booking_completion_controller.dart';
import 'package:mss301_mobile/features/booking/presentation/pages/concessions_page.dart';
import 'package:mss301_mobile/features/booking/presentation/pages/checkout_page.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';
import 'package:mss301_mobile/features/movie/data/models/food_quote_dto.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_dto.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_enums.dart';
import 'package:mss301_mobile/shared/widgets/app_button.dart';
import 'package:mss301_mobile/shared/widgets/app_image.dart';

import 'support/pump_test_app.dart';

const _bookingId = 6109;
const _combo = FoodProductDto(
  id: 771,
  name: 'Combo bắp nước với tên đầy đủ dành cho một buổi xem phim thật dài',
  description: 'Mô tả thực tế được cung cấp cho sản phẩm, với thông tin đầy đủ cần đọc trước khi lựa chọn.',
  imageUrl: 'https://catalog.test/foods/771.jpg',
  price: VndMoney(123000),
  status: FoodItemStatus.active,
  isCombo: true,
);
const _drink = FoodProductDto(
  id: 772,
  name: 'Nước uống có tên đầy đủ được cung cấp từ danh mục hiện tại',
  description: 'Mô tả nước uống theo dữ liệu được cung cấp.',
  price: VndMoney(45000),
  status: FoodItemStatus.active,
  isCombo: false,
);
final _booking = BookingDto(
  id: _bookingId,
  bookingCode: 'BK-6109-SUPPLIED',
  userId: 5101,
  showtimeId: 1002,
  movieId: 2,
  movieTitle: 'Tên phim thật trong booking hiện tại',
  cinemaName: 'Rạp từ booking được cung cấp',
  roomName: 'Phòng số 3 được cung cấp',
  showtimeStart: DateTime(2026, 10, 10, 20, 30),
  subtotal: const VndMoney(110000),
  discountAmount: VndMoney.zero,
  loyaltyPointsRedeemed: 0,
  totalAmount: const VndMoney(110000),
  status: BookingStatus.holding,
  seats: const [
    BookingSeatDto(
      id: 901,
      seatId: 3004,
      showtimeId: 1002,
      rowLabel: 'C',
      seatNumber: 4,
      seatLabel: 'C4',
      seatType: BookingSeatType.standard,
      unitPrice: VndMoney(110000),
      status: BookingSeatStatus.holding,
      ticketType: TicketType.adult,
    ),
  ],
  tickets: const [
    BookingTicketDto(
      id: 902,
      seatId: 3004,
      ticketType: TicketType.adult,
      quantity: 1,
      unitPrice: VndMoney(110000),
      lineTotal: VndMoney(110000),
    ),
  ],
  foods: const [],
  createdAt: DateTime(2026, 10, 10, 20),
);

BookingCompletionState _foodState({
  List<FoodProductDto> products = const [_combo, _drink],
  Map<int, int> quantities = const {},
  BookingCompletionPhase phase = BookingCompletionPhase.choosingFood,
  BookingDto? booking,
  String? message,
}) => BookingCompletionState(
  phase: phase,
  booking: booking ?? _booking,
  products: products,
  quantities: quantities,
  message: message,
);

Future<ProviderContainer> _open(
  WidgetTester tester,
  _TestCompletionController controller, {
  Size size = const Size(430, 844),
}) => pumpTestApp(
  tester,
  initialLocation: AppRoutes.concessions(_bookingId),
  size: size,
  providerOverrides: [bookingCompletionProvider.overrideWith(() => controller)],
);

Finder _card(int productId) => find.byKey(ValueKey('food-card-$productId'));

Future<void> _reveal(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    final scrollable = find
        .descendant(
          of: find.byType(ConcessionsPage),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          ),
        )
        .first;
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pump();
    await tester.scrollUntilVisible(target, 180, scrollable: scrollable);
  } else {
    await tester.ensureVisible(target);
  }
  await tester.pumpAndSettle();
}

Future<void> _tapQuantity(WidgetTester tester, int productId, int delta) async {
  final button = find.byKey(
    ValueKey('food-${delta > 0 ? 'plus' : 'minus'}-$productId'),
  );
  await _reveal(tester, button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

FoodProductDto _item({
  int id = 773,
  FoodItemStatus status = FoodItemStatus.active,
  String? imageUrl,
}) => FoodProductDto(
  id: id,
  name: 'Sản phẩm được cung cấp $id',
  description: 'Mô tả sản phẩm $id từ danh mục.',
  price: const VndMoney(35000),
  status: status,
  isCombo: false,
  imageUrl: imageUrl,
);

AppButton _continue(WidgetTester tester) => tester.widget<AppButton>(
  find.byKey(const ValueKey('concessions-continue')),
);

Text _subtotal(WidgetTester tester) => tester.widget<Text>(
  find.byKey(const ValueKey('concessions-food-subtotal')),
);

void main() {
  testWidgets('renders the supplied food image instead of a generic icon', (
    tester,
  ) async {
    await _open(tester, _TestCompletionController(_foodState()));
    final image = find.byWidgetPredicate(
      (widget) => widget is AppImage && widget.asset == _combo.imageUrl,
    );
    expect(image, findsOneWidget);
    expect(tester.widget<AppImage>(image).aspectRatio, isNotNull);
    expect(find.text(_combo.name), findsOneWidget);
    expect(find.text(_combo.description!), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'renders supplied names, descriptions, prices and product types',
    (tester) async {
      final controller = _TestCompletionController(_foodState());
      await _open(tester, controller);
      for (final product in [_combo, _drink]) {
        await _reveal(tester, _card(product.id));
        expect(
          find.descendant(
            of: _card(product.id),
            matching: find.text(product.name),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: _card(product.id),
            matching: find.text(product.description!),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: _card(product.id),
            matching: find.text(product.price.format()),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: _card(product.id),
            matching: find.text(product.isCombo ? 'Combo' : 'Món lẻ'),
          ),
          findsOneWidget,
        );
      }
      for (final fictional in [
        'Giảm giá',
        'Tiết kiệm',
        'calo',
        'kcal',
        'Bán chạy',
      ]) {
        expect(find.textContaining(fictional), findsNothing);
      }
      expect(controller.loadRequests, [_bookingId]);
      expect(tester.takeException(), isNull);
    },
  );

  for (final imageUrl in <String?>[null, '', '   ']) {
    testWidgets('missing food image "$imageUrl" uses a neutral icon', (
      tester,
    ) async {
      final product = _item(imageUrl: imageUrl);
      await _open(
        tester,
        _TestCompletionController(_foodState(products: [product])),
      );
      expect(
        find.descendant(of: _card(product.id), matching: find.byType(AppImage)),
        findsNothing,
      );
      expect(
        find.descendant(of: _card(product.id), matching: find.byType(Icon)),
        findsAtLeastNWidgets(3),
      );
      expect(find.text(product.name), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'quantity buttons preserve exact IDs, unit deltas, min 0 and max 8',
    (tester) async {
      final controller = _TestCompletionController(_foodState());
      final container = await _open(tester, controller);
      final minus = find.byKey(const ValueKey('food-minus-771'));
      final plus = find.byKey(const ValueKey('food-plus-771'));
      expect(tester.widget<IconButton>(minus).onPressed, isNull);

      for (var quantity = 1; quantity <= 8; quantity++) {
        await _tapQuantity(tester, 771, 1);
        expect(container.read(bookingCompletionProvider).quantities, {
          771: quantity,
        });
        expect(
          _subtotal(tester).data,
          _combo.price.multiply(quantity).format(),
        );
      }
      expect(tester.widget<IconButton>(plus).onPressed, isNull);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('food-quantity-771')),
          matching: find.text('8'),
        ),
        findsOneWidget,
      );

      for (var quantity = 7; quantity >= 0; quantity--) {
        await _tapQuantity(tester, 771, -1);
        expect(
          container.read(bookingCompletionProvider).quantities,
          quantity == 0 ? <int, int>{} : {771: quantity},
        );
      }
      expect(tester.widget<IconButton>(minus).onPressed, isNull);
      expect(_subtotal(tester).data, '0đ');
      expect(find.text('Bỏ qua bắp nước'), findsOneWidget);

      await _tapQuantity(tester, 772, 1);
      expect(container.read(bookingCompletionProvider).quantities, {772: 1});
      expect(controller.checkoutBookingIds, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keyboard activates the existing quantity buttons', (
    tester,
  ) async {
    final container = await _open(
      tester,
      _TestCompletionController(_foodState(products: [_combo])),
    );
    final plus = find.byKey(const ValueKey('food-plus-771'));
    await _reveal(tester, plus);
    final plusIcon = find.descendant(
      of: plus,
      matching: find.byIcon(Icons.add_circle_outline),
    );
    final plusFocus = Focus.of(tester.element(plusIcon));
    plusFocus.requestFocus();
    await tester.pump();
    expect(plusFocus.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(container.read(bookingCompletionProvider).quantities, {771: 1});

    final minusIcon = find.descendant(
      of: find.byKey(const ValueKey('food-minus-771')),
      matching: find.byIcon(Icons.remove_circle_outline),
    );
    Focus.of(tester.element(minusIcon)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(container.read(bookingCompletionProvider).quantities, isEmpty);
    expect(_subtotal(tester).data, '0đ');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'unavailable items block additions and retain selected decrements',
    (tester) async {
      final inactive = _item(id: 773, status: FoodItemStatus.inactive);
      final outOfStock = _item(id: 774, status: FoodItemStatus.outOfStock);
      final controller = _TestCompletionController(
        _foodState(
          products: [inactive, outOfStock],
          quantities: {773: 2, 774: 1},
        ),
      );
      final container = await _open(tester, controller);

      for (final product in [inactive, outOfStock]) {
        await _reveal(tester, _card(product.id));
        expect(
          tester
              .widget<IconButton>(
                find.byKey(ValueKey('food-plus-${product.id}')),
              )
              .onPressed,
          isNull,
        );
        expect(
          tester
              .widget<IconButton>(
                find.byKey(ValueKey('food-minus-${product.id}')),
              )
              .onPressed,
          isNotNull,
        );
        expect(
          find.descendant(
            of: _card(product.id),
            matching: find.text(product.price.format()),
          ),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(of: _card(773), matching: find.text('Ngừng bán')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _card(774), matching: find.text('Tạm hết hàng')),
        findsOneWidget,
      );
      await _tapQuantity(tester, 773, -1);
      expect(container.read(bookingCompletionProvider).quantities, {
        773: 1,
        774: 1,
      });
      await _tapQuantity(tester, 774, -1);
      expect(container.read(bookingCompletionProvider).quantities, {773: 1});
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('food-minus-774')))
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final status in [FoodItemStatus.unknown, FoodItemStatus.lowStock]) {
    testWidgets('${status.name} availability remains selectable', (
      tester,
    ) async {
      final product = _item(status: status);
      final container = await _open(
        tester,
        _TestCompletionController(_foodState(products: [product])),
      );
      expect(
        tester
            .widget<IconButton>(find.byKey(ValueKey('food-plus-${product.id}')))
            .onPressed,
        isNotNull,
      );
      await _tapQuantity(tester, product.id, 1);
      expect(container.read(bookingCompletionProvider).quantities, {
        product.id: 1,
      });
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'selected cards and summary use the current controller quantities',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final container = await _open(
          tester,
          _TestCompletionController(_foodState(quantities: {771: 2, 772: 1})),
        );
        for (final (id, quantity) in [(771, 2), (772, 1)]) {
          await _reveal(tester, _card(id));
          expect(
            find.descendant(
              of: _card(id),
              matching: find.textContaining('Đã chọn'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byKey(ValueKey('food-quantity-$id')),
              matching: find.text('$quantity'),
            ),
            findsOneWidget,
          );
          expect(
            tester
                .getSemantics(_card(id))
                .getSemanticsData()
                .flagsCollection
                .isSelected
                .toBoolOrNull(),
            isTrue,
          );
          expect(
            tester
                .getSemantics(find.byKey(ValueKey('food-quantity-$id')))
                .getSemanticsData()
                .label,
            contains(': $quantity'),
          );
        }
        final summary = find.byKey(const ValueKey('concessions-summary'));
        expect(_subtotal(tester).data, '291.000đ');
        expect(
          find.descendant(
            of: summary,
            matching: find.textContaining('2 sản phẩm'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: summary,
            matching: find.textContaining(
              RegExp(r'\b3\s+(sản phẩm|món|phần)\b'),
            ),
          ),
          findsOneWidget,
        );
        expect(container.read(bookingCompletionProvider).quantities, {
          771: 2,
          772: 1,
        });
        expect(container.read(bookingCompletionProvider).quote, isNull);
        await _tapQuantity(tester, 771, -1);
        expect(_subtotal(tester).data, '168.000đ');
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'booking context uses supplied booking metadata without new data',
    (tester) async {
      final controller = _TestCompletionController(_foodState());
      await _open(tester, controller);
      expect(find.textContaining(_booking.bookingCode), findsOneWidget);
      expect(find.text(_booking.movieTitle!), findsOneWidget);
      expect(find.textContaining('C4'), findsWidgets);
      expect(controller.loadRequests, [_bookingId]);
      expect(
        tester.widget<ConcessionsPage>(find.byType(ConcessionsPage)).bookingId,
        _bookingId,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('ready checkout keeps booking ID and the selected food state', (
    tester,
  ) async {
    final controller = _TestCompletionController(
      _foodState(quantities: {771: 2, 772: 1}),
    );
    final container = await _open(tester, controller);
    await tester.tap(find.byKey(const ValueKey('concessions-continue')));
    await tester.pumpAndSettle();

    expect(controller.checkoutBookingIds, [_bookingId]);
    expect(controller.checkoutQuantities, [
      {771: 2, 772: 1},
    ]);
    expect(find.byType(CheckoutPage), findsOneWidget);
    expect(
      tester.widget<CheckoutPage>(find.byType(CheckoutPage)).bookingId,
      _bookingId,
    );
    expect(
      appRouter.routeInformationProvider.value.uri.toString(),
      AppRoutes.checkout(_bookingId),
    );
    expect(container.read(bookingCompletionProvider).quantities, {
      771: 2,
      772: 1,
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed checkout preparation remains on the same concessions route',
    (tester) async {
      final controller = _TestCompletionController(_foodState())
        ..checkoutReady = false;
      await _open(tester, controller);
      await tester.tap(find.byKey(const ValueKey('concessions-continue')));
      await tester.pumpAndSettle();
      expect(controller.checkoutBookingIds, [_bookingId]);
      expect(find.byType(ConcessionsPage), findsOneWidget);
      expect(
        appRouter.routeInformationProvider.value.uri.toString(),
        AppRoutes.concessions(_bookingId),
      );
    },
  );

  testWidgets('back retains the booking showtime route', (tester) async {
    await _open(tester, _TestCompletionController(_foodState()));
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(
      appRouter.routeInformationProvider.value.uri.toString(),
      AppRoutes.seatSelection(_booking.showtimeId),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'missing booking disables continue and back returns to showtimes',
    (tester) async {
      await _open(
        tester,
        _TestCompletionController(
          const BookingCompletionState(
            phase: BookingCompletionPhase.choosingFood,
            products: [_combo, _drink],
          ),
        ),
      );
      expect(_continue(tester).onPressed, isNull);
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(
        appRouter.routeInformationProvider.value.uri.toString(),
        AppRoutes.showtimes,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pending load preserves loading and exact booking ID', (
    tester,
  ) async {
    final pending = Completer<BookingCompletionState>();
    final controller = _TestCompletionController(
      const BookingCompletionState(phase: BookingCompletionPhase.loading),
    )..loadResult = pending.future;
    await tester.binding.setSurfaceSize(const Size(430, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [bookingCompletionProvider.overrideWith(() => controller)],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const ConcessionsPage(bookingId: _bookingId),
        ),
      ),
    );
    await tester.pump();
    expect(controller.loadRequests, [_bookingId]);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(_continue(tester).onPressed, isNull);
    expect(_card(771), findsNothing);

    pending.complete(_foodState());
    await tester.pumpAndSettle();
    expect(_card(771), findsOneWidget);
    expect(_continue(tester).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'empty catalog remains empty and permits continuing without food',
    (tester) async {
      final controller = _TestCompletionController(_foodState(products: []));
      await _open(tester, controller);
      expect(
        find.textContaining(
          RegExp('(chưa|không).*(sản phẩm|bắp nước)', caseSensitive: false),
        ),
        findsWidgets,
      );
      expect(_card(771), findsNothing);
      expect(_subtotal(tester).data, '0đ');
      expect(_continue(tester).onPressed, isNotNull);
      await tester.tap(find.byKey(const ValueKey('concessions-continue')));
      await tester.pumpAndSettle();
      expect(controller.checkoutQuantities, [<int, int>{}]);
      expect(find.byType(CheckoutPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'error remains an error with its existing return-to-showtimes action',
    (tester) async {
      const message = 'Không thể tải danh mục từ hệ thống hiện tại.';
      await _open(
        tester,
        _TestCompletionController(
          const BookingCompletionState(
            phase: BookingCompletionPhase.error,
            message: message,
          ),
        ),
      );
      expect(find.text(message), findsOneWidget);
      expect(find.text('Thử lại'), findsNothing);
      expect(_continue(tester).onPressed, isNull);
      expect(_card(771), findsNothing);
      await tester.tap(find.text('Về lịch chiếu'));
      await tester.pumpAndSettle();
      expect(
        appRouter.routeInformationProvider.value.uri.toString(),
        AppRoutes.showtimes,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'expired booking keeps message, return action and existing CTA gate',
    (tester) async {
      const message = 'Thời gian giữ ghế đã hết.';
      await _open(
        tester,
        _TestCompletionController(
          _foodState(
            phase: BookingCompletionPhase.expired,
            booking: _booking.copyWith(status: BookingStatus.expired),
            message: message,
          ),
        ),
      );
      expect(find.text(message), findsOneWidget);
      expect(_card(771), findsNothing);
      expect(_continue(tester).onPressed, isNotNull);
      await tester.tap(find.text('Về lịch chiếu'));
      await tester.pumpAndSettle();
      expect(
        appRouter.routeInformationProvider.value.uri.toString(),
        AppRoutes.showtimes,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'busy preparation blocks repeat continue and inherited quantity edits',
    (tester) async {
      final pending = Completer<bool>();
      final controller = _TestCompletionController(
        _foodState(products: [_combo], quantities: {771: 1}),
      )..checkoutResult = pending.future;
      final container = await _open(tester, controller);
      await _reveal(tester, find.byKey(const ValueKey('food-plus-771')));
      await tester.tap(find.byKey(const ValueKey('concessions-continue')));
      await tester.pump();

      expect(container.read(bookingCompletionProvider).isBusy, isTrue);
      expect(_continue(tester).onPressed, isNull);
      expect(find.text('Đang cập nhật…'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('food-plus-771')))
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(const ValueKey('food-plus-771')));
      await tester.pump();
      expect(container.read(bookingCompletionProvider).quantities, {771: 1});
      expect(controller.checkoutBookingIds, [_bookingId]);

      pending.complete(false);
      await tester.pumpAndSettle();
      expect(find.byType(ConcessionsPage), findsOneWidget);
      expect(_continue(tester).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 430.0, 768.0]) {
    testWidgets('long food data and quantity controls fit at $width px', (
      tester,
    ) async {
      await _open(
        tester,
        _TestCompletionController(_foodState()),
        size: Size(width, 844),
      );
      await _tapQuantity(tester, 771, 1);
      await _reveal(tester, _card(772));
      expect(find.text(_drink.name), findsOneWidget);
      final button = find.byKey(const ValueKey('food-plus-772'));
      expect(tester.getSize(button).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
      final continueButton = find.byKey(const ValueKey('concessions-continue'));
      expect(continueButton.hitTestable(), findsOneWidget);
      expect(
        tester.getSize(continueButton).width,
        greaterThanOrEqualTo(width - 40),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('200 percent text keeps supplied data and controls usable', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _open(
      tester,
      _TestCompletionController(_foodState()),
      size: const Size(320, 844),
    );
    await _tapQuantity(tester, 771, 1);
    await _reveal(tester, _card(772));
    expect(find.text(_drink.name), findsOneWidget);
    expect(
      MediaQuery.textScalerOf(tester.element(_card(772))).scale(14),
      closeTo(28, 0.001),
    );
    expect(
      find.byKey(const ValueKey('concessions-continue')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  for (final selected in [false, true]) {
    testWidgets(
      'short landscape with selected=$selected keeps food and CTA usable',
      (tester) async {
        await _open(
          tester,
          _TestCompletionController(_foodState()),
          size: const Size(844, 320),
        );
        expect(tester.takeException(), isNull);
        await _reveal(tester, find.byKey(const ValueKey('food-plus-771')));
        if (selected) await _tapQuantity(tester, 771, 1);
        expect(
          find.byKey(const ValueKey('food-plus-771')).hitTestable(),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('concessions-continue')).hitTestable(),
          findsOneWidget,
        );
        expect(_subtotal(tester).data, selected ? '123.000đ' : '0đ');
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _TestCompletionController extends BookingCompletionController {
  _TestCompletionController(this.initialState);

  final BookingCompletionState initialState;
  final loadRequests = <int>[];
  final checkoutBookingIds = <int?>[];
  final checkoutQuantities = <Map<int, int>>[];
  Future<BookingCompletionState>? loadResult;
  Future<bool>? checkoutResult;
  bool checkoutReady = true;

  @override
  BookingCompletionState build() => initialState;

  @override
  Future<void> load(int bookingId) async {
    loadRequests.add(bookingId);
    if (loadResult != null) state = await loadResult!;
  }

  @override
  Future<bool> prepareCheckout() async {
    checkoutBookingIds.add(state.booking?.id);
    checkoutQuantities.add(Map<int, int>.from(state.quantities));
    if (checkoutResult == null) return checkoutReady;
    state = state.copyWith(phase: BookingCompletionPhase.preparingCheckout);
    final ready = await checkoutResult!;
    if (!ready) {
      state = state.copyWith(phase: BookingCompletionPhase.choosingFood);
    }
    return ready;
  }
}
