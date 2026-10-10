import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mss301_mobile/core/config/feature_flags.dart';
import 'package:mss301_mobile/core/money/vnd_money.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/core/theme/app_theme.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_enums.dart';
import 'package:mss301_mobile/features/orders/presentation/models/ticket_order.dart';
import 'package:mss301_mobile/features/orders/presentation/pages/orders_page.dart';
import 'package:mss301_mobile/features/orders/presentation/providers/orders_provider.dart';
import 'package:mss301_mobile/features/orders/presentation/widgets/order_card.dart';
import 'package:mss301_mobile/features/orders/presentation/widgets/orders_segmented_tabs.dart';
import 'package:mss301_mobile/shared/widgets/app_button.dart';
import 'package:mss301_mobile/shared/widgets/app_image.dart';

const _longCode =
    'BK-SUPPLIED-5807-CUSTOMER-BOOKING-REFERENCE-WITH-A-LONG-UNTRUNCATED-CODE';
const _title =
    'Tên phim dài được cung cấp trong booking và cần đọc đầy đủ trên điện thoại';

TicketOrder _order({
  int id = 5807,
  int movieId = 29,
  String code = _longCode,
  String ageRating = 'T16',
  BookingStatus status = BookingStatus.paid,
  String foods = '2x Bắp rang được cung cấp, 1x Nước uống được cung cấp',
}) => TicketOrder(
  id: id,
  ticketCode: code,
  movieId: movieId,
  movieTitle: _title,
  moviePoster: 'https://catalog.test/movies/29.jpg',
  ageRating: ageRating,
  format: '2D • Phụ đề',
  cinemaLocation: 'Rạp được cung cấp có tên dài ở thành phố hiện tại',
  roomName: 'Phòng chiếu số 12 được cung cấp',
  showtimeAt: DateTime(2026, 10, 10, 20, 30),
  seats: const ['C4', 'C5', 'C6'],
  seatsTypeLabel: '2 người lớn, 1 sinh viên',
  concessionsSummary: foods,
  totalPrice: const VndMoney(1299000),
  status: status,
);

Future<void> _pumpCard(
  WidgetTester tester,
  Widget card, {
  Size size = const Size(320, 844),
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: card,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<GoRouter> _pumpHistory(
  WidgetTester tester, {
  required Future<List<TicketOrder>> Function() load,
  bool settle = true,
  Size size = const Size(430, 844),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: AppRoutes.orders,
    routes: [
      GoRoute(path: AppRoutes.orders, builder: (_, _) => const OrdersPage()),
      GoRoute(
        path: AppRoutes.ticketPattern,
        builder: (_, state) => Scaffold(
          body: Text('Ticket route ${state.pathParameters['bookingId']}'),
        ),
      ),
      GoRoute(
        path: AppRoutes.showtimes,
        builder: (_, state) => Scaffold(
          body: Text('Showtimes route ${state.uri.queryParameters['movieId']}'),
        ),
      ),
      GoRoute(
        path: AppRoutes.previewRefundPattern,
        builder: (_, state) => Scaffold(
          body: Text('Refund route ${state.pathParameters['bookingId']}'),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [ordersProvider.overrideWith((ref) => load())],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return router;
}

Future<void> _reveal(WidgetTester tester, Finder target) async {
  final scrollable = find.byType(Scrollable).first;
  if (target.evaluate().isEmpty) {
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pump();
    await tester.scrollUntilVisible(target, 180, scrollable: scrollable);
  } else {
    await tester.ensureVisible(target);
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('long supplied booking code and title stay readable at 320', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      UpcomingOrderCard(order: _order(), onCancel: null, onOpenTicket: () {}),
    );
    expect(tester.takeException(), isNull);
    final code = tester.widget<Text>(find.text(_longCode));
    expect(code.maxLines, isNull);
    expect(code.overflow, isNot(TextOverflow.ellipsis));
    final title = tester.widget<Text>(find.text(_title));
    expect(title.maxLines, isNull);
    expect(title.overflow, isNot(TextOverflow.ellipsis));
  });

  testWidgets('supplied booking detail fields and amount render unchanged', (
    tester,
  ) async {
    final order = _order();
    await _pumpCard(
      tester,
      UpcomingOrderCard(order: order, onCancel: null, onOpenTicket: () {}),
    );
    expect(find.text(order.cinemaLocation), findsOneWidget);
    expect(find.text(order.roomName), findsOneWidget);
    expect(find.text(order.dateTime), findsOneWidget);
    expect(
      find.text('Ghế: C4, C5, C6 (2 người lớn, 1 sinh viên)'),
      findsOneWidget,
    );
    expect(find.text('Bắp nước: ${order.concessionsSummary}'), findsOneWidget);
    final amount = find.byKey(ValueKey('order-amount-${order.id}'));
    await _reveal(tester, amount);
    expect(tester.widget<Text>(amount).data, order.totalPrice.format());
    final image = tester.widget<AppImage>(find.byType(AppImage));
    expect(image.asset, order.moviePoster);
    expect(image.aspectRatio, AppSizes.posterAspectRatio);
    expect(tester.takeException(), isNull);
  });

  for (final status in [BookingStatus.paid, BookingStatus.used]) {
    testWidgets(
      'remote-shaped ${status.name} card does not claim fallback age or format',
      (tester) async {
        final order = _order(status: status, ageRating: 'P');
        await _pumpCard(
          tester,
          order.isUpcoming
              ? UpcomingOrderCard(
                  order: order,
                  onCancel: null,
                  onOpenTicket: () {},
                )
              : CompletedOrderCard(
                  order: order,
                  onBookAgain: () {},
                  onRate: null,
                ),
        );
        expect(find.text('P'), findsNothing);
        expect(find.text('2D • Phụ đề'), findsNothing);
        expect(find.text(order.ticketCode), findsOneWidget);
        expect(find.text(order.movieTitle), findsOneWidget);
        expect(find.text(order.cinemaLocation), findsOneWidget);
        expect(find.text(order.dateTime), findsOneWidget);
        expect(
          find.text('Ghế: C4, C5, C6 (2 người lớn, 1 sinh viên)'),
          findsOneWidget,
        );
        expect(find.text(order.totalPrice.format()), findsOneWidget);
        expect(find.text(order.statusLabel), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final status in BookingStatus.values) {
    testWidgets(
      'existing status ${status.name} keeps its label and card kind',
      (tester) async {
        final order = _order(status: status);
        await _pumpCard(
          tester,
          order.isUpcoming
              ? UpcomingOrderCard(
                  order: order,
                  onCancel: null,
                  onOpenTicket: () {},
                )
              : CompletedOrderCard(
                  order: order,
                  onBookAgain: () {},
                  onRate: null,
                ),
        );
        expect(find.text(order.statusLabel), findsOneWidget);
        expect(
          find.byType(
            order.isUpcoming ? UpcomingOrderCard : CompletedOrderCard,
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('no attached food stays absent without invented content', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      UpcomingOrderCard(
        order: _order(foods: 'Không kèm F&B'),
        onCancel: null,
        onOpenTicket: () {},
      ),
    );
    expect(find.textContaining('Bắp nước:'), findsNothing);
    expect(find.textContaining('Giảm giá'), findsNothing);
  });

  testWidgets('upcoming actions retain their callbacks and 48px full width', (
    tester,
  ) async {
    var ticketCalls = 0;
    var refundCalls = 0;
    await _pumpCard(
      tester,
      UpcomingOrderCard(
        order: _order(),
        onCancel: () => refundCalls++,
        onOpenTicket: () => ticketCalls++,
      ),
    );
    final ticket = find.byKey(const ValueKey('order-ticket-5807'));
    final refund = find.byKey(const ValueKey('order-refund-5807'));
    await _reveal(tester, ticket);
    expect(tester.getSize(ticket).width, greaterThanOrEqualTo(250));
    expect(tester.getSize(ticket).height, greaterThanOrEqualTo(48));
    await tester.tap(ticket);
    await _reveal(tester, refund);
    await tester.tap(refund);
    expect(ticketCalls, 1);
    expect(refundCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed actions preserve book-again and disabled review', (
    tester,
  ) async {
    var bookCalls = 0;
    await _pumpCard(
      tester,
      CompletedOrderCard(
        order: _order(status: BookingStatus.used),
        onBookAgain: () => bookCalls++,
        onRate: null,
      ),
    );
    final book = find.byKey(const ValueKey('order-book-again-5807'));
    final review = find.byKey(const ValueKey('order-review-5807'));
    await _reveal(tester, book);
    await tester.tap(book);
    expect(bookCalls, 1);
    expect(tester.widget<AppButton>(review).onPressed, isNull);
    expect(find.text('Đánh giá • Sắp có'), findsOneWidget);
    expect(tester.getSize(review).height, greaterThanOrEqualTo(48));
  });

  testWidgets('history groups and orders supplied records without sorting', (
    tester,
  ) async {
    await _pumpHistory(
      tester,
      load: () async => [
        _order(id: 902, code: 'FIRST-PAID'),
        _order(id: 901, code: 'FIRST-USED', status: BookingStatus.used),
        _order(id: 900, code: 'SECOND-HOLDING', status: BookingStatus.holding),
        _order(
          id: 899,
          code: 'SECOND-CANCELLED',
          status: BookingStatus.cancelled,
        ),
        _order(
          id: 898,
          code: 'THIRD-PENDING',
          status: BookingStatus.pendingPayment,
        ),
      ],
    );
    final tabs = tester.widget<OrdersSegmentedTabs>(
      find.byType(OrdersSegmentedTabs),
    );
    expect(tabs.upcomingCount, 3);
    expect(tabs.completedCount, 2);
    expect(tabs.selected, OrdersTab.upcoming);
    final first = find.text('FIRST-PAID');
    final second = find.text('SECOND-HOLDING');
    final third = find.text('THIRD-PENDING');
    final scrollPosition = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    final firstPosition = scrollPosition.pixels + tester.getTopLeft(first).dy;
    await _reveal(tester, second);
    final secondPosition = scrollPosition.pixels + tester.getTopLeft(second).dy;
    expect(firstPosition, lessThan(secondPosition));
    await _reveal(tester, third);
    expect(
      secondPosition,
      lessThan(scrollPosition.pixels + tester.getTopLeft(third).dy),
    );
    expect(find.text('FIRST-USED'), findsNothing);
    await _reveal(tester, find.text('Lịch sử đã xem'));
    await tester.tap(find.text('Lịch sử đã xem'));
    await tester.pumpAndSettle();
    final completedFirstPosition =
        scrollPosition.pixels + tester.getTopLeft(find.text('FIRST-USED')).dy;
    await _reveal(tester, find.text('SECOND-CANCELLED'));
    expect(
      completedFirstPosition,
      lessThan(
        scrollPosition.pixels +
            tester.getTopLeft(find.text('SECOND-CANCELLED')).dy,
      ),
    );
    expect(find.text('FIRST-PAID'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('open-ticket keeps the exact supplied bookingId route', (
    tester,
  ) async {
    final router = await _pumpHistory(tester, load: () async => [_order()]);
    final ticket = find.byKey(const ValueKey('order-ticket-5807'));
    await _reveal(tester, ticket);
    await tester.tap(ticket);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/ticket/5807');
    expect(find.text('Ticket route 5807'), findsOneWidget);
  });

  testWidgets('book-again keeps the exact supplied movieId route', (
    tester,
  ) async {
    final router = await _pumpHistory(
      tester,
      load: () async => [_order(status: BookingStatus.used)],
    );
    await tester.tap(find.text('Lịch sử đã xem'));
    await tester.pumpAndSettle();
    final book = find.byKey(const ValueKey('order-book-again-5807'));
    await _reveal(tester, book);
    await tester.tap(book);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/showtimes?movieId=29',
    );
    expect(find.text('Showtimes route 29'), findsOneWidget);
  });

  testWidgets('history refund action keeps the feature flag boundary', (
    tester,
  ) async {
    final router = await _pumpHistory(tester, load: () async => [_order()]);
    final refund = find.byKey(const ValueKey('order-refund-5807'));
    await _reveal(tester, refund);
    final button = tester.widget<AppButton>(refund);
    expect(button.onPressed != null, FeatureFlags.refundPreview);
    if (FeatureFlags.refundPreview) {
      await tester.tap(refund);
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/preview/refund/5807',
      );
    } else {
      await tester.tap(refund);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.orders);
    }
  });

  testWidgets('empty tabs show empty states without fabricated cards', (
    tester,
  ) async {
    await _pumpHistory(tester, load: () async => []);
    expect(find.text('Chưa có vé sắp chiếu nào'), findsOneWidget);
    expect(find.byType(UpcomingOrderCard), findsNothing);
    await tester.tap(find.text('Lịch sử đã xem'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có lịch sử đã xem'), findsOneWidget);
    expect(find.byType(CompletedOrderCard), findsNothing);
  });

  testWidgets('loading stays pending until supplied future resolves', (
    tester,
  ) async {
    final pending = Completer<List<TicketOrder>>();
    await _pumpHistory(tester, load: () => pending.future, settle: false);
    expect(find.text('Đang tải dữ liệu...'), findsOneWidget);
    expect(find.byType(UpcomingOrderCard), findsNothing);
    pending.complete([_order()]);
    await tester.pumpAndSettle();
    expect(find.text(_longCode), findsOneWidget);
  });

  testWidgets('error and retry keep provider invalidation and real recovery', (
    tester,
  ) async {
    var attempts = 0;
    await _pumpHistory(
      tester,
      load: () async {
        attempts++;
        if (attempts == 1) throw StateError('history unavailable');
        return [_order()];
      },
    );
    expect(find.text('Đã xảy ra lỗi'), findsOneWidget);
    expect(find.byType(UpcomingOrderCard), findsNothing);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text(_longCode), findsOneWidget);
  });

  for (final width in [320.0, 430.0, 768.0]) {
    testWidgets('history detail and actions fit ${width.toInt()}px', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        CompletedOrderCard(
          order: _order(status: BookingStatus.used),
          onBookAgain: () {},
          onRate: null,
        ),
        size: Size(width, 844),
      );
      final book = find.byKey(const ValueKey('order-book-again-5807'));
      await _reveal(tester, book);
      expect(tester.getSize(book).width, greaterThanOrEqualTo(width - 70));
      expect(tester.getSize(book).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });
  }

  for (final status in [BookingStatus.paid, BookingStatus.used]) {
    testWidgets(
      'read-only ${status.name} status has an explicit readable foreground',
      (tester) async {
        final order = _order(status: status);
        await _pumpCard(
          tester,
          order.isUpcoming
              ? UpcomingOrderCard(
                  order: order,
                  onCancel: null,
                  onOpenTicket: () {},
                )
              : CompletedOrderCard(
                  order: order,
                  onBookAgain: () {},
                  onRate: null,
                ),
        );
        final statusLabel = find.text(order.statusLabel);
        final foreground = order.isUpcoming
            ? AppColors.gold
            : AppColors.textSecondary;
        expect(tester.widget<Text>(statusLabel).style?.color, foreground);
        expect(
          find.ancestor(of: statusLabel, matching: find.byType(ActionChip)),
          findsNothing,
        );
        final luminance = foreground.computeLuminance();
        final backgroundLuminance = AppColors.surfaceRaised.computeLuminance();
        expect(
          (luminance + .05) / (backgroundLuminance + .05),
          greaterThanOrEqualTo(4.5),
        );
        final semantics = tester.ensureSemantics();
        try {
          await tester.pump();
          final statusSemantics = tester.getSemantics(
            find.byKey(ValueKey('order-status-${order.id}')),
          );
          expect(
            statusSemantics.label,
            'Trạng thái đặt vé: ${order.statusLabel}',
          );
          expect(statusSemantics.flagsCollection.isButton, isFalse);
        } finally {
          semantics.dispose();
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('long booking content and actions remain usable at 200% text', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      UpcomingOrderCard(order: _order(), onCancel: null, onOpenTicket: () {}),
      textScale: 2,
    );
    final ticket = find.byKey(const ValueKey('order-ticket-5807'));
    await _reveal(tester, ticket);
    expect(ticket.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history card can scroll to its actions in short landscape', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      UpcomingOrderCard(order: _order(), onCancel: null, onOpenTicket: () {}),
      size: const Size(844, 320),
    );
    final ticket = find.byKey(const ValueKey('order-ticket-5807'));
    await _reveal(tester, ticket);
    expect(ticket.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history tabs and ticket action remain keyboard accessible', (
    tester,
  ) async {
    var selection = OrdersTab.upcoming;
    await _pumpCard(
      tester,
      OrdersSegmentedTabs(
        selected: selection,
        upcomingCount: 1,
        completedCount: 2,
        onSelected: (value) => selection = value,
      ),
    );
    final tabFocus = Focus.of(tester.element(find.text('Lịch sử đã xem')));
    tabFocus.requestFocus();
    await tester.pump();
    expect(tabFocus.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(selection, OrdersTab.completed);

    var ticketCalls = 0;
    await _pumpCard(
      tester,
      UpcomingOrderCard(
        order: _order(),
        onCancel: null,
        onOpenTicket: () => ticketCalls++,
      ),
    );
    final ticket = find.byKey(const ValueKey('order-ticket-5807'));
    await _reveal(tester, ticket);
    final ticketFocus = Focus.of(tester.element(find.text('Mở mã vé')));
    ticketFocus.requestFocus();
    await tester.pump();
    expect(ticketFocus.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(ticketCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'tabs keep full labels, selected semantics and touch targets at 200%',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        var selected = OrdersTab.upcoming;
        await _pumpCard(
          tester,
          OrdersSegmentedTabs(
            selected: OrdersTab.upcoming,
            upcomingCount: 123,
            completedCount: 456,
            onSelected: (value) => selected = value,
          ),
          textScale: 2,
        );
        final completed = find.text('Lịch sử đã xem');
        expect(tester.widget<Text>(completed).maxLines, isNull);
        final tapTarget = find
            .ancestor(of: completed, matching: find.byType(InkWell))
            .first;
        expect(tester.getSize(tapTarget).height, greaterThanOrEqualTo(48));
        await tester.tap(completed);
        expect(selected, OrdersTab.completed);
        expect(
          tester
              .getSemantics(find.text('Sắp chiếu'))
              .flagsCollection
              .isSelected
              .toBoolOrNull(),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
}
