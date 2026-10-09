import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../models/account_dto.dart';
import 'account_repositories.dart';

class RemoteWalletRepository implements WalletRepository {
  RemoteWalletRepository(this._dio);
  final Dio _dio;

  @override
  Future<WalletDto> getWallet(int userId) async =>
      WalletDto.fromJson(_data(await _request(() => _dio.get('/api/v1/wallet'))));

  @override
  Future<List<WalletTransactionDto>> getTransactions(int userId) async {
    final data = _data(await _request(() => _dio.get(
      '/api/v1/wallet/transactions',
      queryParameters: {'page': 0, 'size': 20},
    )));
    final content = data['content'];
    if (content is! List) throw _invalid('wallet transaction response');
    return content.map((item) => WalletTransactionDto.fromJson(
      Map<String, Object?>.from(item as Map),
    )).toList(growable: false);
  }

  @override
  Future<List<WithdrawalDto>> getWithdrawals(int userId) async {
    final data = _data(await _request(() => _dio.get(
      '/api/v1/wallet/withdrawals',
      queryParameters: {'page': 0, 'size': 20},
    )));
    final content = data['content'];
    if (content is! List) throw _invalid('withdrawal response');
    return content.map((item) => WithdrawalDto.fromJson(
      Map<String, Object?>.from(item as Map),
    )).toList(growable: false);
  }
  @override
  Future<WithdrawalDto> createWithdrawal(int userId, WithdrawalCreateRequestDto request) =>
      _unsupported('Wallet withdrawals are outside B13 scope.');

  Future<T> _unsupported<T>(String message) => Future<T>.error(
    ApiException(type: ApiErrorType.unknown, message: message),
  );
  Future<Response<dynamic>> _request(Future<Response<dynamic>> Function() call) async {
    try { return await call(); } on DioException catch (error) {
      if (error.error case final ApiException mapped) throw mapped;
      rethrow;
    }
  }
  Map<String, Object?> _data(Response<dynamic> response) {
    final body = response.data;
    if (body is! Map || body['success'] != true || body['data'] is! Map) {
      throw _invalid('wallet API response');
    }
    return Map<String, Object?>.from(body['data'] as Map);
  }
  ApiException _invalid(String resource) => ApiException(
    type: ApiErrorType.unknown, message: 'Invalid $resource.',
  );
}

class RemoteLoyaltyRepository implements LoyaltyRepository {
  RemoteLoyaltyRepository(this._dio);
  final Dio _dio;

  @override
  Future<LoyaltyDto> getLoyalty(int userId) async => LoyaltyDto.fromJson(
    _data(await _request(() => _dio.get('/api/v1/loyalty/me'))),
  );

  @override
  Future<LoyaltyConfigurationDto> getConfiguration() async =>
      LoyaltyConfigurationDto.fromJson(
        _data(await _request(() => _dio.get('/api/v1/loyalty/config'))),
      );

  Future<Response<dynamic>> _request(Future<Response<dynamic>> Function() call) async {
    try { return await call(); } on DioException catch (error) {
      if (error.error case final ApiException mapped) throw mapped;
      rethrow;
    }
  }
  Map<String, Object?> _data(Response<dynamic> response) {
    final body = response.data;
    if (body is! Map || body['success'] != true || body['data'] is! Map) {
      throw const ApiException(
        type: ApiErrorType.unknown, message: 'Invalid loyalty API response.',
      );
    }
    return Map<String, Object?>.from(body['data'] as Map);
  }
}
