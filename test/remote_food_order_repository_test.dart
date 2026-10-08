import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/features/food/data/repositories/remote_food_order_repository.dart';
import 'package:mss301_mobile/core/network/api_exception.dart';

void main() {
  test(
    'maps standalone food order history from the Gateway endpoint',
    () async {
      final adapter = _Adapter();
      final orders = await RemoteFoodOrderRepository(
        Dio()..httpClientAdapter = adapter,
      ).getMyOrders();
      expect(adapter.method, 'GET');
      expect(adapter.path, '/api/v1/food-orders/my');
      expect(orders.single.id, 42);
      expect(orders.single.totalAmount.amount, 85000);
      expect(orders.single.items.single.quantity, 2);
      expect(orders.single.items.single.productName, 'Combo Couple');
    },
  );

  test('maps an empty standalone order history', () async {
    final orders = await RemoteFoodOrderRepository(
      Dio()..httpClientAdapter = _Adapter(empty: true),
    ).getMyOrders();
    expect(orders, isEmpty);
  });

  test('rejects an invalid backend response envelope', () async {
    expect(
      () => RemoteFoodOrderRepository(
        Dio()..httpClientAdapter = _Adapter(invalid: true),
      ).getMyOrders(),
      throwsA(isA<ApiException>()),
    );
  });
}

class _Adapter implements HttpClientAdapter {
  _Adapter({this.empty = false, this.invalid = false});
  final bool empty;
  final bool invalid;
  String? method;
  String? path;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    method = options.method;
    path = options.path;
    return ResponseBody.fromString(
      jsonEncode({
        'success': !invalid,
        'data': invalid ? null : (empty ? <Object?>[] : [_order]),
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

const _order = {
  'id': 42,
  'orderCode': 'FOOD-42',
  'bookingId': null,
  'bookingCode': null,
  'status': 'PAID',
  'totalAmount': 85000,
  'paidAt': '2026-10-08T10:00:00',
  'expiresAt': null,
  'pickedUpAt': null,
  'qrCode': 'CINEAI:FOOD:42',
  'createdAt': '2026-10-08T09:55:00',
  'createdByStaff': false,
  'items': [
    {
      'id': 7,
      'productId': 3,
      'isCombo': true,
      'productName': 'Combo Couple',
      'quantity': 2,
      'unitPrice': 42500,
      'lineTotal': 85000,
    },
  ],
};
