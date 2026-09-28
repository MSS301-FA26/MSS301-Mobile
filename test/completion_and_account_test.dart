import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/app/app.dart';
import 'package:mss301_mobile/core/routing/app_router.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/features/auth/application/mock_auth_session.dart';
import 'package:mss301_mobile/features/booking/presentation/pages/concessions_page.dart';
import 'package:mss301_mobile/features/booking/presentation/pages/ticket_page.dart';

void main() {
  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    appRouter.go(AppRoutes.home);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const ProviderScope(child: CinePremierApp()));
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(CinePremierApp)),
    );
  }

  Future<void> openPayment(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('hero-book-2')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('showtime-slot-1002')).hitTestable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('showtime-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ticket-plus-adult')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('seat-3001')));
    await tester.tap(find.byKey(const ValueKey('seat-3001')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('seat-continue')));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(ConcessionsPage), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('concessions-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('checkout-pay')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'R5 completes hold, checkout, payment verification and QR ticket',
    (tester) async {
      await pumpApp(tester);
      await openPayment(tester);

      await tester.tap(find.byKey(const ValueKey('payment-success')));
      await tester.pumpAndSettle();
      expect(find.text('Booking đã được xác nhận'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('open-ticket')));
      await tester.pumpAndSettle();

      expect(find.byType(TicketPage), findsOneWidget);
      expect(find.text('Đã thanh toán'), findsOneWidget);
      expect(find.textContaining('CP-MOCK-'), findsOneWidget);
    },
  );

  testWidgets('R5 opens VNPay mock handoff before callback verification', (
    tester,
  ) async {
    await pumpApp(tester);
    await openPayment(tester);

    expect(find.byKey(const ValueKey('payment-url')), findsOneWidget);
    expect(find.textContaining('mock://vnpay/'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('payment-open-webview')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Đã mở VNPay Mock'), findsOneWidget);
    expect(find.byKey(const ValueKey('payment-success')), findsOneWidget);
  });

  testWidgets('R5 payment failure can create a fresh retry payment', (
    tester,
  ) async {
    await pumpApp(tester);
    await openPayment(tester);
    await tester.tap(find.byKey(const ValueKey('payment-failure')));
    await tester.pumpAndSettle();
    expect(find.text('Thanh toán thất bại'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('payment-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('payment-success')), findsOneWidget);
  });

  testWidgets('R6 guest account signs in and opens account core actions', (
    tester,
  ) async {
    final container = await pumpApp(tester, size: const Size(360, 800));
    container.read(mockAuthSessionProvider.notifier).signOut();
    appRouter.go(AppRoutes.account);
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập để quản lý vé và quyền lợi'), findsOneWidget);

    appRouter.go(AppRoutes.wallet);
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập'), findsAtLeastNWidgets(1));

    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();
    expect(container.read(mockAuthSessionProvider).isAuthenticated, isTrue);
    expect(find.text('Hồ sơ cá nhân'), findsOneWidget);
    expect(find.text('CinePoints'), findsOneWidget);
  });

  testWidgets('R7 release-like build hides preview account actions', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(412, 915));
    appRouter.go(AppRoutes.account);
    await tester.pumpAndSettle();

    expect(find.text('Trợ lý điện ảnh PopBot AI'), findsNothing);
    expect(find.text('Ưu đãi & Voucher cá nhân'), findsNothing);
    expect(find.text('Đặt bắp nước độc lập'), findsNothing);

    appRouter.go(AppRoutes.popBot);
    await tester.pumpAndSettle();
    expect(
      find.text('PopBot AI đang tắt trong release-like build.'),
      findsOneWidget,
    );
  });
}
