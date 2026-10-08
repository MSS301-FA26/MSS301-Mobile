import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/features/payment/data/models/payment_dto.dart';
import 'package:mss301_mobile/features/payment/data/repositories/remote_payment_repository.dart';

void main() {
  test(
    'creates VNPay payment with exact booking id and maps status response',
    () async {
      final adapter = _PaymentAdapter();
      final repository = RemotePaymentRepository(
        Dio()..httpClientAdapter = adapter,
      );

      final payment = await repository.createPayment(
        999,
        const CreatePaymentRequestDto(bookingId: 741852),
      );

      expect(adapter.methods, ['POST', 'GET']);
      expect(adapter.paths, [
        '/api/v1/payments/vnpay/create',
        '/api/v1/payments/7418520',
      ]);
      expect(adapter.bodies.first, {'bookingId': 741852});
      expect(payment.id, 7418520);
      expect(payment.bookingId, 741852);
      expect(payment.paymentUrl, 'https://sandbox.vnpay.test/pay');
      expect(payment.amount.amount, 123456);
    },
  );

  test('gets payment by id and preserves pending status', () async {
    final adapter = _PaymentAdapter();
    final payment = await RemotePaymentRepository(
      Dio()..httpClientAdapter = adapter,
    ).getPayment(7418520);
    expect(payment!.status.wireValue, 'PENDING');
    expect(adapter.paths.single, '/api/v1/payments/7418520');
  });
}

class _PaymentAdapter implements HttpClientAdapter {
  final methods = <String>[];
  final paths = <String>[];
  final bodies = <Map<String, Object?>>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    methods.add(options.method);
    paths.add(options.path);
    if (options.data is Map) {
      bodies.add(Map<String, Object?>.from(options.data as Map));
    }
    if (options.path.endsWith('/vnpay/create')) {
      return _json({
        'success': true,
        'data': {
          'paymentId': 7418520,
          'paymentUrl': 'https://sandbox.vnpay.test/pay',
          'txnRef': 'TXN-1',
          'amount': 123456,
          'provider': 'VNPAY',
        },
      });
    }
    return _json({
      'success': true,
      'data': {
        'id': 7418520,
        'bookingId': 741852,
        'foodOrderId': null,
        'userId': 19,
        'provider': 'VNPAY',
        'transactionId': 'TXN-1',
        'amount': 123456,
        'status': 'PENDING',
        'paymentUrl': 'https://sandbox.vnpay.test/pay',
        'paymentAccountLabel': 'VNPay',
        'paidAt': null,
        'refundAmount': 0,
        'refundedAt': null,
        'createdAt': '2026-10-07T10:00:00',
      },
    });
  }
}

ResponseBody _json(Object value) => ResponseBody.fromString(
  jsonEncode(value),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);
