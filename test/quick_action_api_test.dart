import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/money/vnd_money.dart';
import 'package:mss301_mobile/core/network/api_exception.dart';
import 'package:mss301_mobile/features/food/data/models/food_order_dto.dart';
import 'package:mss301_mobile/features/food/data/repositories/standalone_food_repository.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';
import 'package:mss301_mobile/features/movie/data/models/cinema_dto.dart';
import 'package:mss301_mobile/features/movie/data/models/food_quote_dto.dart';
import 'package:mss301_mobile/features/popbot/data/chat_repository.dart';

const cinema = CinemaDto(
  id: 1,
  name: 'QA',
  address: 'Address',
  city: 'HCM',
  active: true,
);
FoodProductDto product({
  bool combo = false,
  FoodItemStatus status = FoodItemStatus.active,
}) => FoodProductDto(
  id: 7,
  name: 'QA product',
  price: const VndMoney(50000),
  status: status,
  isCombo: combo,
);

Dio responding(Object? Function(RequestOptions) response) {
  final dio = Dio(BaseOptions(baseUrl: 'https://qa.invalid'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (request, handler) {
        handler.resolve(
          Response(
            requestOptions: request,
            statusCode: 200,
            data: response(request),
          ),
        );
      },
    ),
  );
  return dio;
}

Map<String, Object?> envelope(Object data) => {'success': true, 'data': data};
Map<String, Object?> order({String status = 'PENDING_PAYMENT'}) => {
  'id': 9,
  'orderCode': 'FOOD-QA',
  'status': status,
  'totalAmount': 120000,
  'createdAt': '2026-10-14T10:00:00Z',
  'expiresAt': '2026-10-14T10:03:00',
  'items': <Object>[],
};

void main() {
  test(
    'food create sends product identity and cinema, server owns prices',
    () async {
      late RequestOptions sent;
      final repo = StandaloneFoodRepository(
        responding((request) {
          sent = request;
          return envelope(order());
        }),
      );
      final result = await repo.create(cinema, [
        (product: product(), quantity: 2),
        (product: product(combo: true), quantity: 1),
      ]);
      expect(sent.method, 'POST');
      expect(sent.path, '/api/v1/food-orders');
      expect(sent.data, {
        'cinemaId': 1,
        'cinemaName': 'QA',
        'cinemaAddress': 'Address',
        'foods': [
          {'productId': 7, 'isCombo': false, 'quantity': 2},
          {'productId': 7, 'isCombo': true, 'quantity': 1},
        ],
      });
      expect(result.totalAmount.amount, 120000);
      expect(product().selectionKey, isNot(product(combo: true).selectionKey));
    },
  );

  test('rejects invalid carts before any HTTP request', () async {
    var calls = 0;
    final repo = StandaloneFoodRepository(
      responding((_) {
        calls++;
        return envelope(order());
      }),
    );
    for (final quantity in [0, 9]) {
      await expectLater(
        repo.create(cinema, [(product: product(), quantity: quantity)]),
        throwsA(isA<ApiException>()),
      );
    }
    await expectLater(repo.create(cinema, []), throwsA(isA<ApiException>()));
    await expectLater(
      repo.create(cinema, [
        (product: product(status: FoodItemStatus.outOfStock), quantity: 1),
      ]),
      throwsA(isA<ApiException>()),
    );
    expect(calls, 0);
  });

  test(
    'reuses pending VNPay payment without creating another payment',
    () async {
      final paths = <String>[];
      final repo = StandaloneFoodRepository(
        responding((request) {
          paths.add(request.path);
          return envelope({
            'id': 4,
            'foodOrderId': 9,
            'userId': 12,
            'provider': 'VNPAY',
            'amount': 120000,
            'status': 'PENDING',
            'refundAmount': 0,
            'createdAt': '2026-10-14T10:00:00Z',
            'paymentUrl': 'https://sandbox.vnpayment.vn/qa',
          });
        }),
      );
      final payment = await repo.payment(9, 12);
      expect(payment.paymentUrl, 'https://sandbox.vnpayment.vn/qa');
      expect(paths, ['/api/v1/payments/food-order/9']);
    },
  );

  test(
    'sync and cancel use BE state, unknown status is never payable',
    () async {
      final methods = <String>[];
      final repo = StandaloneFoodRepository(
        responding((request) {
          methods.add('${request.method} ${request.path}');
          return envelope(order(status: 'CANCELLED'));
        }),
      );
      expect((await repo.sync(9)).status, FoodOrderStatus.cancelled);
      expect((await repo.cancel(9)).status, FoodOrderStatus.cancelled);
      expect(methods, [
        'POST /api/v1/food-orders/9/sync',
        'DELETE /api/v1/food-orders/9',
      ]);
      expect(
        FoodOrderDto.fromJson(order(status: 'NEW_STATUS')).status,
        FoodOrderStatus.unknown,
      );
      expect(
        FoodOrderDto.fromJson(order()).expiresAt,
        DateTime.parse('2026-10-14T10:03:00+07:00').toUtc(),
      );
    },
  );

  test('chat guest omits identity and continues server conversation', () async {
    final payloads = <Object?>[];
    final repo = ChatRepository(
      responding((request) {
        expect(request.path, '/api/v1/chat/message');
        payloads.add(request.data);
        return envelope({
          'conversationId': 'server-conversation',
          'reply': 'Server reply',
        });
      }),
    );
    final first = await repo.send('Hello');
    await repo.send('Next', conversationId: first.conversationId, userId: 12);
    expect(first.reply, 'Server reply');
    expect(payloads, [
      {'message': 'Hello'},
      {
        'message': 'Next',
        'conversationId': 'server-conversation',
        'userId': 12,
      },
    ]);
  });

  test(
    'chat malformed and empty responses produce errors, no invented reply',
    () async {
      for (final body in [
        envelope({'conversationId': 'id', 'reply': ''}),
        {'success': false},
        envelope({'reply': 'Missing ID'}),
      ]) {
        await expectLater(
          ChatRepository(responding((_) => body)).send('Hello'),
          throwsA(isA<ApiException>()),
        );
      }
    },
  );
}
