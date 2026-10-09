import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/network/api_exception.dart';
import 'package:mss301_mobile/features/account/data/repositories/remote_account_repositories.dart';

void main() {
  test('maps wallet balance and transaction page through Gateway', () async {
    final adapter = _Adapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = RemoteWalletRepository(dio);
    final wallet = await repository.getWallet(99);
    final transactions = await repository.getTransactions(99);
    expect(wallet.balance.amount, 125000);
    expect(transactions.single.amount.amount, 50000);
    expect(adapter.paths, contains('/api/v1/wallet/transactions'));
  });

  test('maps loyalty points and configuration', () async {
    final adapter = _Adapter();
    final repository = RemoteLoyaltyRepository(
      Dio()..httpClientAdapter = adapter,
    );
    expect((await repository.getLoyalty(99)).points, 800);
    expect((await repository.getConfiguration()).redemptionPoints, 100);
    final redeemed = await repository.redeemPoints(250);
    expect(adapter.lastMethod, 'POST');
    expect(adapter.lastPath, '/api/v1/loyalty/me/redeem');
    expect(adapter.lastQuery, {'points': 250});
    expect(redeemed.points, 550);
    expect(redeemed.totalPoints, 1200);
  });

  test('rejects invalid wallet and loyalty envelopes', () async {
    final dio = Dio()..httpClientAdapter = _Adapter(invalid: true);
    expect(
      () => RemoteWalletRepository(dio).getWallet(1),
      throwsA(isA<ApiException>()),
    );
    expect(
      () => RemoteLoyaltyRepository(dio).getLoyalty(1),
      throwsA(isA<ApiException>()),
    );
  });

  test('preserves mapped backend errors for redemption', () async {
    final dio = Dio()..httpClientAdapter = _Adapter(failRedeem: true);
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) => handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            error: const ApiException(
              type: ApiErrorType.badRequest,
              statusCode: 400,
              message: 'Insufficient loyalty points',
            ),
          ),
        ),
      ),
    );
    expect(
      () => RemoteLoyaltyRepository(dio).redeemPoints(900),
      throwsA(isA<ApiException>()),
    );
  });

  test(
    'rejects successful redemption envelopes without loyalty fields',
    () async {
      final dio = Dio()..httpClientAdapter = _Adapter(invalidShape: true);
      expect(
        () => RemoteLoyaltyRepository(dio).redeemPoints(100),
        throwsA(isA<ApiException>()),
      );
    },
  );
}

class _Adapter implements HttpClientAdapter {
  _Adapter({
    this.invalid = false,
    this.failRedeem = false,
    this.invalidShape = false,
  });
  final bool invalid;
  final bool failRedeem;
  final bool invalidShape;
  final paths = <String>[];
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastQuery;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    lastMethod = options.method;
    lastPath = options.path;
    lastQuery = options.queryParameters;
    Object? data;
    if (options.path == '/api/v1/wallet') {
      data = {'id': 1, 'balance': 125000, 'createdAt': '2026-10-01T00:00:00'};
    } else if (options.path == '/api/v1/wallet/transactions') {
      data = {
        'content': [_transaction],
        'page': 0,
        'size': 20,
        'totalElements': 1,
        'totalPages': 1,
      };
    } else if (options.path == '/api/v1/loyalty/me' ||
        options.path == '/api/v1/loyalty/me/redeem') {
      data = {
        'userId': 99,
        'userEmail': 'customer@example.com',
        'points': options.path.endsWith('/redeem')
            ? 800 - (options.queryParameters['points'] as int)
            : 800,
        'totalPoints': 1200,
        'status': 'ACTIVE',
      };
    } else {
      data = {
        'id': 1,
        'earningRatePercent': 1,
        'redemptionPoints': 100,
        'redemptionValueVnd': 10000,
        'expiryMonth': 12,
        'expiryDay': 31,
        'expiryTime': '23:59',
      };
    }
    if (invalidShape && options.path.endsWith('/redeem')) {
      data = <String, Object?>{};
    }
    final isFailure =
        invalid || (failRedeem && options.path.endsWith('/redeem'));
    if (failRedeem && options.path.endsWith('/redeem')) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Insufficient loyalty points'}),
        400,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'success': !isFailure, 'data': isFailure ? null : data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

const _transaction = {
  'id': 2,
  'walletId': 1,
  'userId': 99,
  'bookingId': 7,
  'type': 'REFUND_CREDIT',
  'amount': 50000,
  'balanceAfter': 125000,
  'referenceCode': 'BK-7',
  'description': 'Refund',
  'createdAt': '2026-10-01T00:00:00',
};
