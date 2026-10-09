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
    final repository = RemoteLoyaltyRepository(Dio()..httpClientAdapter = _Adapter());
    expect((await repository.getLoyalty(99)).points, 800);
    expect((await repository.getConfiguration()).redemptionPoints, 100);
  });

  test('rejects invalid wallet and loyalty envelopes', () async {
    final dio = Dio()..httpClientAdapter = _Adapter(invalid: true);
    expect(() => RemoteWalletRepository(dio).getWallet(1), throwsA(isA<ApiException>()));
    expect(() => RemoteLoyaltyRepository(dio).getLoyalty(1), throwsA(isA<ApiException>()));
  });
}

class _Adapter implements HttpClientAdapter {
  _Adapter({this.invalid = false});
  final bool invalid;
  final paths = <String>[];
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream,
      Future<void>? cancelFuture) async {
    paths.add(options.path);
    Object? data;
    if (options.path == '/api/v1/wallet') {
      data = {'id': 1, 'balance': 125000, 'createdAt': '2026-10-01T00:00:00'};
    } else if (options.path == '/api/v1/wallet/transactions') {
      data = {'content': [_transaction], 'page': 0, 'size': 20, 'totalElements': 1, 'totalPages': 1};
    } else if (options.path == '/api/v1/loyalty/me') {
      data = {'userId': 99, 'userEmail': 'customer@example.com', 'points': 800, 'totalPoints': 1200, 'status': 'ACTIVE'};
    } else {
      data = {'id': 1, 'earningRatePercent': 1, 'redemptionPoints': 100, 'redemptionValueVnd': 10000, 'expiryMonth': 12, 'expiryDay': 31, 'expiryTime': '23:59'};
    }
    return ResponseBody.fromString(jsonEncode({'success': !invalid, 'data': invalid ? null : data}), 200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }
}

const _transaction = {
  'id': 2, 'walletId': 1, 'userId': 99, 'bookingId': 7, 'type': 'REFUND_CREDIT',
  'amount': 50000, 'balanceAfter': 125000, 'referenceCode': 'BK-7',
  'description': 'Refund', 'createdAt': '2026-10-01T00:00:00',
};
