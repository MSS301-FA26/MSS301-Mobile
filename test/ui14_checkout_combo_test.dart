import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/features/booking/application/booking_completion_controller.dart';
import 'package:mss301_mobile/features/booking/presentation/pages/checkout_page.dart';
import 'package:mss301_mobile/shared/widgets/checkout_summary.dart';

import 'support/pump_test_app.dart';
import 'ui13_checkout_summary_test.dart' as fixture;

class EditableCheckout extends fixture.Completion {
  EditableCheckout(super.initial);
  int edits = 0;
  void makeBusy() =>
      state = state.copyWith(phase: BookingCompletionPhase.preparingCheckout);
  @override
  Future<void> changeCheckoutQuantity(
    int id,
    int delta, {
    bool isCombo = false,
  }) async {
    edits++;
    final key = '${isCombo ? 'combo' : 'item'}:$id';
    state = state.copyWith(
      quantities: {
        ...state.quantities,
        key: (state.quantities[key] ?? 0) + delta,
      },
      quoteNeedsRefresh: true,
    );
  }
}

Future<void> showCheckout(
  WidgetTester tester,
  double width, {
  bool stale = false,
  bool busy = false,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = 1.6;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final state = fixture.order().copyWith(
    quantities: const {'combo:7': 1},
    quoteNeedsRefresh: stale,
    phase: busy
        ? BookingCompletionPhase.preparingCheckout
        : BookingCompletionPhase.checkout,
  );
  await pumpTestApp(
    tester,
    initialLocation: AppRoutes.checkout(42),
    size: Size(width, 1000),
    providerOverrides: [
      bookingCompletionProvider.overrideWith(() => EditableCheckout(state)),
      checkoutMovieMetadataProvider(11).overrideWith((ref) async => null),
    ],
  );
}

void main() {
  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    testWidgets('UI14 combos and fixed payment at $width large text', (
      tester,
    ) async {
      await showCheckout(tester, width);
      final combo = find.byKey(const ValueKey('checkout-combo-7'));
      await fixture.reveal(tester, combo);
      expect(
        find.byKey(const ValueKey('checkout-pay')).hitTestable(),
        findsOneWidget,
      );
      final add = find.byKey(const ValueKey('checkout-plus-combo:7'));
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      final scope = ProviderScope.containerOf(tester.element(add));
      expect(
        (scope.read(
          bookingCompletionProvider.notifier,
        ) as EditableCheckout).edits,
        1,
      );
      expect(scope.read(bookingCompletionProvider).quantities['combo:7'], 2);
      expect(
        tester
            .widget<PaymentActionBar>(find.byType(PaymentActionBar))
            .onPressed,
        isNull,
      );
      expect(
        find.byKey(const ValueKey('checkout-refresh-quote')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'UI14 all-food sheet keeps deadline and total visible, uses typed product keys',
    (tester) async {
      await showCheckout(tester, 320);
      final all = find.byKey(const ValueKey('checkout-all-food'));
      await fixture.reveal(tester, all);
      await tester.tap(all);
      await tester.pumpAndSettle();
      expect(find.text('Combo & bắp nước'), findsOneWidget);
      expect(find.textContaining('Tổng thanh toán:'), findsOneWidget);
      expect(
        find.text('Hoàn tất • Kiểm tra đơn').hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('booking-hold-countdown')).hitTestable(),
        findsWidgets,
      );
      final row = find.byKey(const ValueKey('food-card-combo:7'));
      await tester.scrollUntilVisible(
        row,
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.byKey(const ValueKey('food-plus-combo:7')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Hoàn tất • Kiểm tra đơn'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('UI14 busy cart locks quantity and payment', (tester) async {
    await showCheckout(tester, 390, stale: true);
    await fixture.reveal(
      tester,
      find.byKey(const ValueKey('checkout-combo-7')),
    );
    final scope = ProviderScope.containerOf(
      tester.element(find.byKey(const ValueKey('checkout-combo-7'))),
    );
    (scope.read(bookingCompletionProvider.notifier) as EditableCheckout)
        .makeBusy();
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey('checkout-plus-combo:7')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey('checkout-minus-combo:7')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester.widget<PaymentActionBar>(find.byType(PaymentActionBar)).onPressed,
      isNull,
    );
    expect(
      find.textContaining('Tổng bên dưới chưa được xác nhận'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
