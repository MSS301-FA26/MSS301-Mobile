import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/network/api_exception.dart';
import 'package:mss301_mobile/core/time/app_clock.dart';
import 'package:mss301_mobile/features/auth/application/auth_session.dart';
import 'package:mss301_mobile/features/booking/application/booking_checkpoint.dart';
import 'package:mss301_mobile/features/booking/application/booking_completion_controller.dart';
import 'package:mss301_mobile/features/movie/data/repositories/catalog_providers.dart';
import 'package:mss301_mobile/features/movie/data/repositories/remote_catalog_repository.dart';
import 'package:mss301_mobile/features/orders/data/repositories/booking_providers.dart';
import 'package:mss301_mobile/features/orders/data/repositories/remote_booking_repository.dart';
import 'package:mss301_mobile/features/payment/data/repositories/payment_providers.dart';
import 'package:mss301_mobile/features/payment/data/repositories/remote_payment_repository.dart';
import 'package:mss301_mobile/features/seat/data/repositories/seat_hold_providers.dart';
import 'package:mss301_mobile/features/seat/data/repositories/remote_seat_hold_repository.dart';

import 'support/fake_auth_session.dart';

void main() {
  late _Gateway gateway;
  late ProviderContainer container;
  late BookingCompletionController controller;
  late _Checkpoints checkpoints;
  late FakeAppClock clock;

  setUp(() {
    gateway = _Gateway();
    checkpoints = _Checkpoints();
    clock = FakeAppClock(DateTime(2026, 10, 11));
    final dio = Dio()..httpClientAdapter = gateway;
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          if (error.response?.statusCode == 404) {
            handler.next(
              error.copyWith(
                error: const ApiException(
                  type: ApiErrorType.notFound,
                  message: 'Not found',
                ),
              ),
            );
          } else {
            handler.next(error);
          }
        },
      ),
    );
    container = ProviderContainer(
      overrides: [
        appClockProvider.overrideWithValue(clock),
        authSessionProvider.overrideWith(
          () => FakeAuthSessionController(authenticatedCustomerState()),
        ),
        bookingCheckpointStoreProvider.overrideWithValue(checkpoints),
        catalogRepositoryProvider.overrideWithValue(
          RemoteCatalogRepository(dio),
        ),
        bookingRepositoryProvider.overrideWithValue(
          RemoteBookingRepository(dio),
        ),
        seatHoldRepositoryProvider.overrideWithValue(
          RemoteSeatHoldRepository(dio),
        ),
        paymentRepositoryProvider.overrideWithValue(
          RemotePaymentRepository(dio),
        ),
      ],
    );
    controller = container.read(bookingCompletionProvider.notifier);
  });
  tearDown(() => container.dispose());

  test(
    'Vietnam booking deadline without offset gives three minutes remaining',
    () async {
      clock.advance(
        DateTime.parse('2026-10-11T13:00:00+07:00').difference(clock.now()),
      );
      gateway.expiry = '2026-10-11T13:03:00';
      await controller.load(42);
      final state = container.read(bookingCompletionProvider);
      expect(state.phase, BookingCompletionPhase.choosingFood);
      expect(
        state.booking!.holdExpiresAt!.difference(clock.now()),
        const Duration(minutes: 3),
      );
      controller.changeQuantity(1, 1);
      expect(await controller.prepareCheckout(), isTrue);
      expect(
        container.read(bookingCompletionProvider).quote!.validUntil.isUtc,
        isTrue,
      );
      clock.advance(const Duration(minutes: 3));
      expect(await controller.createPayment(), isNull);
      expect(
        gateway.calls.where(
          (call) => call == 'POST /api/v1/payments/vnpay/create',
        ),
        isEmpty,
      );
    },
  );

  test('remote flow keeps colliding item/combo IDs separate and checks out before payment', () async {
    await controller.load(42);
    expect(container.read(bookingCompletionProvider).products, hasLength(2));
    controller.changeQuantity(1, 1);
    controller.changeQuantity(1, 1, isCombo: true);
    expect(await controller.prepareCheckout(), isTrue);
    final foods = gateway.itemsBody!['foods'] as List;
    expect(foods, [
      {'productId': 1, 'isCombo': true, 'quantity': 1},
      {'productId': 1, 'isCombo': false, 'quantity': 1},
    ]);
    expect(await controller.createPayment(), isNotNull);
    expect(
      gateway.calls.indexOf('POST /api/v1/bookings/42/checkout'),
      lessThan(gateway.calls.indexOf('POST /api/v1/payments/vnpay/create')),
    );
    expect(
      container.read(bookingCompletionProvider).booking!.totalAmount.amount,
      130000,
    );
    expect(checkpoints.values[5101]?.paymentId, 99);
  });

  test('double payment submit creates once, then reuses the pending server payment', () async {
    await controller.load(42);
    await controller.prepareCheckout();
    final gate = Completer<void>();
    gateway.paymentGate = gate;
    final first = controller.createPayment();
    await Future<void>.delayed(Duration.zero);
    expect(await controller.createPayment(), isNull);
    gate.complete();
    expect(await first, isNotNull);
    expect(await controller.createPayment(), isNotNull);
    expect(
      gateway.calls.where(
        (call) => call == 'POST /api/v1/payments/vnpay/create',
      ),
      hasLength(1),
    );
  });

  test('SUCCESS waits for PAID and clears recovery state only after issuing ticket', () async {
    gateway.hasPayment = true;
    gateway.paymentStatus = 'SUCCESS';
    gateway.bookingStatus = 'PENDING_PAYMENT';
    await controller.attachPayment(99);
    expect(
      container.read(bookingCompletionProvider).phase,
      BookingCompletionPhase.verifyingBooking,
    );
    expect(await controller.refreshPaymentStatus(), isFalse);
    gateway.bookingStatus = 'PAID';
    expect(await controller.refreshPaymentStatus(), isTrue);
    expect(
      container.read(bookingCompletionProvider).phase,
      BookingCompletionPhase.ticketReady,
    );
    expect(checkpoints.values, isEmpty);
  });

  test('an expired hold never creates payment', () async {
    await controller.load(42);
    await controller.prepareCheckout();
    clock.set(DateTime(2100));
    expect(await controller.createPayment(), isNull);
    expect(
      container.read(bookingCompletionProvider).phase,
      BookingCompletionPhase.expired,
    );
    expect(
      gateway.calls,
      isNot(contains('POST /api/v1/payments/vnpay/create')),
    );
  });

  test(
    'restored child age survives the backend snapshot overwriting viewerAge',
    () async {
      gateway.ticketType = 'CHILD';
      checkpoints.values[5101] = const BookingCheckpoint(
        bookingId: 42,
        viewerAges: {11: 10},
      );
      await controller.load(42);
      expect(await controller.prepareCheckout(), isTrue);
      final tickets = gateway.itemsBody!['tickets'] as List;
      expect(tickets.single['viewerAge'], 10);
      expect(tickets.single['ticketType'], 'CHILD');
      expect((gateway.quoteBody!['tickets'] as List).single['viewerAge'], 10);
    },
  );

  test('checkout price change stops before creating payment', () async {
    await controller.load(42);
    await controller.prepareCheckout();
    gateway.checkoutPriceChange = true;
    expect(await controller.createPayment(), isNull);
    expect(
      gateway.calls,
      isNot(contains('POST /api/v1/payments/vnpay/create')),
    );
    expect(
      container.read(bookingCompletionProvider).message,
      contains('Tổng tiền'),
    );
    expect(
      container.read(bookingCompletionProvider).phase,
      BookingCompletionPhase.checkout,
    );
    expect(
      container.read(bookingCompletionProvider).quote!.total.amount,
      110000,
    );
    expect(await controller.createPayment(), isNotNull);
    expect(
      gateway.calls.where((c) => c == 'POST /api/v1/payments/vnpay/create'),
      hasLength(1),
    );
  });

  test(
    'out-of-stock errors preserve the cart and allow removing missing products',
    () async {
      await controller.load(42);
      controller.changeQuantity(1, 2);
      gateway.foodUnavailable = true;
      gateway.hideProducts = true;
      expect(await controller.prepareCheckout(), isFalse);
      var state = container.read(bookingCompletionProvider);
      expect(state.phase, BookingCompletionPhase.choosingFood);
      expect(state.quantities['item:1'], 2);
      expect(state.products.single.isAvailable, isFalse);
      expect(state.message, contains('sửa giỏ'));
      controller.changeQuantity(1, 1);
      expect(container.read(bookingCompletionProvider).quantities['item:1'], 2);
      controller.changeQuantity(1, -2);
      gateway.foodUnavailable = false;
      expect(await controller.prepareCheckout(), isTrue);
      expect(gateway.itemsBody!['foods'], isEmpty);
      expect(await controller.createPayment(), isNotNull);
    },
  );

  test('each item and combo can have eight and food is optional', () async {
    await controller.load(42);
    controller.changeQuantity(1, 99);
    controller.changeQuantity(1, 99, isCombo: true);
    expect(container.read(bookingCompletionProvider).quantities, {
      'item:1': 8,
      'combo:1': 8,
    });
    controller.changeQuantity(1, -99);
    controller.changeQuantity(1, -99, isCombo: true);
    expect(await controller.prepareCheckout(), isTrue);
    expect(gateway.itemsBody!['foods'], isEmpty);
    expect(gateway.quoteBody!['voucherCode'], isNull);
    expect(gateway.quoteBody!['cinePointsToUse'], isNull);
  });

  test('history retrieves records beyond the first twenty orders', () async {
    final orders = await container
        .read(bookingRepositoryProvider)
        .getBookings(0);
    expect(orders, hasLength(23));
    expect(orders.map((order) => order.id).toSet(), hasLength(23));
    expect(
      gateway.calls.where((call) => call == 'GET /api/v1/bookings'),
      hasLength(2),
    );
  });

  test(
    'logout discards a late booking response from the previous account',
    () async {
      final gate = Completer<void>();
      gateway.bookingGate = gate;
      final loading = controller.load(42);
      await Future<void>.delayed(Duration.zero);
      await container.read(authSessionProvider.notifier).logout();
      expect(
        container.read(bookingCompletionProvider).phase,
        BookingCompletionPhase.idle,
      );
      gate.complete();
      await loading;
      expect(container.read(bookingCompletionProvider).booking, isNull);
    },
  );

  test(
    'only ACTIVE items and combos can be added, matching backend quote',
    () async {
      for (final status in [
        'LOW_STOCK',
        'OUT_OF_STOCK',
        'INACTIVE',
        'UNKNOWN',
        'ACTIVE',
      ]) {
        container.invalidate(bookingCompletionProvider);
        controller = container.read(bookingCompletionProvider.notifier);
        gateway.productStatus = status;
        await controller.load(42);
        controller.changeQuantity(1, 1);
        controller.changeQuantity(1, 1, isCombo: true);
        final quantities = container.read(bookingCompletionProvider).quantities;
        expect(
          quantities,
          status == 'ACTIVE' ? {'item:1': 1, 'combo:1': 1} : isEmpty,
        );
      }
    },
  );

  test(
    'restored LOW_STOCK selection must be removed before checkout',
    () async {
      gateway.productStatus = 'LOW_STOCK';
      gateway.foods = [
        {
          'id': 1,
          'productId': 1,
          'isCombo': false,
          'productName': 'Drink',
          'quantity': 2,
          'unitPrice': 10000,
          'lineTotal': 20000,
        },
      ];
      await controller.load(42);
      expect(container.read(bookingCompletionProvider).quantities['item:1'], 2);
      expect(await controller.prepareCheckout(), isFalse);
      expect(
        container.read(bookingCompletionProvider).phase,
        BookingCompletionPhase.choosingFood,
      );
      expect(
        container.read(bookingCompletionProvider).message,
        contains('sửa giỏ'),
      );
      expect(gateway.calls, isNot(contains('PUT /api/v1/bookings/42/items')));
      controller.changeQuantity(1, 1);
      expect(container.read(bookingCompletionProvider).quantities['item:1'], 2);
      controller.changeQuantity(1, -2);
      expect(await controller.prepareCheckout(), isTrue);
      expect(gateway.itemsBody!['foods'], isEmpty);
    },
  );

  test('Back to concessions makes quantities editable again', () async {
    await controller.load(42);
    await controller.prepareCheckout();
    controller.returnToFood();
    controller.changeQuantity(1, 1);
    expect(container.read(bookingCompletionProvider).quantities['item:1'], 1);
  });
}

class _Checkpoints implements BookingCheckpointStore {
  final values = <int, BookingCheckpoint>{};
  @override
  Future<void> clear(int userId) async {
    values.remove(userId);
  }

  @override
  Future<BookingCheckpoint?> read(int userId) async => values[userId];
  @override
  Future<void> save(int userId, BookingCheckpoint checkpoint) async {
    values[userId] = checkpoint;
  }
}

class _Gateway implements HttpClientAdapter {
  final calls = <String>[];
  Map<String, dynamic>? itemsBody;
  Map<String, dynamic>? quoteBody;
  String ticketType = 'ADULT';
  String productStatus = 'ACTIVE';
  bool checkoutPriceChange = false;
  bool hasPayment = false;
  String paymentStatus = 'PENDING';
  String bookingStatus = 'HOLDING';
  String expiry = '2099-01-01T00:00:00';
  Completer<void>? paymentGate;
  Completer<void>? bookingGate;
  int total = 100000;
  int baseTotal = 100000;
  bool foodUnavailable = false;
  bool hideProducts = false;
  List<dynamic> foods = [];

  Map<String, Object?> get booking => {
    'id': 42,
    'bookingCode': 'BK42',
    'userId': 5101,
    'showtimeId': 7,
    'movieId': 2,
    'subtotal': total,
    'totalAmount': total,
    'discountAmount': 0,
    'loyaltyPointsRedeemed': 0,
    'status': bookingStatus,
    'holdExpiresAt': expiry,
    'createdAt': '2026-01-01T00:00:00',
    'seats': [
      {
        'id': 1,
        'seatId': 11,
        'showtimeId': 7,
        'rowLabel': 'A',
        'seatNumber': 1,
        'seatLabel': 'A1',
        'seatType': 'STANDARD',
        'unitPrice': 100000,
        'status': 'HOLDING',
        'ticketType': ticketType,
      },
    ],
    'tickets': [
      {
        'id': 1,
        'seatId': 11,
        'ticketType': ticketType,
        'viewerAge': 20,
        'quantity': 1,
        'unitPrice': 100000,
        'lineTotal': 100000,
      },
    ],
    'foods': foods,
  };

  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add('${options.method} ${options.path}');
    Object? data;
    var status = 200;
    if (options.path == '/api/v1/bookings') {
      final page = options.queryParameters['page'] as int;
      data = {
        'content': [
          for (var i = 0; i < (page == 0 ? 20 : 3); i++)
            {...booking, 'id': 42 + page * 20 + i},
        ],
        'totalPages': 2,
      };
    } else if (options.path.startsWith('/api/v1/foods/')) {
      final combo = options.path.endsWith('combos');
      data = {
        'items': [
          if (!hideProducts)
            {
              'id': 1,
              'name': combo ? 'Combo' : 'Drink',
              'price': combo ? 20000 : 10000,
              'status': productStatus,
            },
        ],
        'totalPages': 1,
      };
    } else if (options.path.endsWith('/items') ||
        options.path.endsWith('/checkout')) {
      if (foodUnavailable) {
        return ResponseBody.fromString(
          jsonEncode({
            'success': false,
            'message': 'Food product is unavailable: 1',
          }),
          400,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
      itemsBody = Map<String, dynamic>.from(options.data as Map);
      final selected = itemsBody!['foods'] as List;
      total = baseTotal;
      foods = [
        for (final food in selected)
          {
            'id': food['isCombo'] == true ? 2 : 1,
            ...food,
            'productName': food['isCombo'] == true ? 'Combo' : 'Drink',
            'unitPrice': food['isCombo'] == true ? 20000 : 10000,
            'lineTotal':
                (food['isCombo'] == true ? 20000 : 10000) *
                (food['quantity'] as int),
          },
      ];
      for (final food in foods) {
        total += food['lineTotal'] as int;
      }
      if (options.path.endsWith('/checkout')) bookingStatus = 'PENDING_PAYMENT';
      if (options.path.endsWith('/checkout') && checkoutPriceChange) {
        total += 10000;
        baseTotal += 10000;
        checkoutPriceChange = false;
      }
      data = booking;
    } else if (options.path == '/api/v1/catalog/checkout-quote') {
      quoteBody = Map<String, dynamic>.from(options.data as Map);
      data = {
        'quoteId': 'quote42',
        'validUntil': expiry,
        'showtime': {
          'showtimeId': 7,
          'movieId': 2,
          'startTime': '2099-01-01T12:00:00',
        },
        'seats': [],
        'tickets': [],
        'foods': foods,
        'foodItems': foods,
        'ticketSubtotal': baseTotal,
        'foodSubtotal': total - baseTotal,
        'subtotal': total,
        'total': total,
        'discount': 0,
        'cinePointsDiscount': 0,
        'fees': 0,
        'tax': 0,
      };
    } else if (options.path == '/api/v1/payments/vnpay/create') {
      await paymentGate?.future;
      hasPayment = true;
      data = {'paymentId': 99};
    } else if (options.path.startsWith('/api/v1/payments/')) {
      if (!hasPayment) {
        status = 404;
      }
      data = {
        'id': 99,
        'bookingId': 42,
        'userId': 5101,
        'provider': 'VNPAY',
        'amount': total,
        'status': paymentStatus,
        'paymentUrl': 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html',
        'createdAt': '2026-01-01T00:00:00',
      };
    } else {
      await bookingGate?.future;
      data = booking;
    }
    return ResponseBody.fromString(
      jsonEncode({'success': status == 200, 'data': data}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
