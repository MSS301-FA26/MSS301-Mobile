import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../../../core/network/api_exception.dart';
import '../../../movie/data/models/cinema_dto.dart';
import '../../../movie/data/models/food_quote_dto.dart';
import '../../../payment/data/models/payment_dto.dart';
import '../../../payment/data/repositories/remote_payment_repository.dart';
import '../models/food_order_dto.dart';

class StandaloneFoodRepository {
  StandaloneFoodRepository(this.dio);
  final Dio dio;
  Future<Map<String, Object?>> _request(
    String path, {
    String method = 'GET',
    Object? body,
    CancelToken? cancelToken,
  }) async {
    final response = await dio.request(
      path,
      data: body,
      cancelToken: cancelToken,
      options: Options(method: method),
    );
    final result = response.data;
    if (result is! Map || result['success'] != true || result['data'] is! Map) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Phản hồi đơn bắp nước không hợp lệ.',
      );
    }
    return Map<String, Object?>.from(result['data'] as Map);
  }

  Future<FoodOrderDto> create(
    CinemaDto cinema,
    List<({FoodProductDto product, int quantity})> cart, {
    CancelToken? cancelToken,
  }) async {
    if (cart.isEmpty ||
        cart.any(
          (item) =>
              !item.product.isAvailable ||
              item.quantity < 1 ||
              item.quantity > 8,
        )) {
      throw const ApiException(
        type: ApiErrorType.validation,
        message: 'Giỏ hàng không hợp lệ.',
      );
    }
    return FoodOrderDto.fromJson(
      await _request(
        '/api/v1/food-orders',
        method: 'POST',
        cancelToken: cancelToken,
        body: {
          'cinemaId': cinema.id,
          'cinemaName': cinema.name,
          'cinemaAddress': cinema.address,
          'foods': cart
              .map(
                (item) => {
                  'productId': item.product.id,
                  'isCombo': item.product.isCombo,
                  'quantity': item.quantity,
                },
              )
              .toList(),
        },
      ),
    );
  }

  Future<FoodOrderDto> get(int id, {CancelToken? cancelToken}) async =>
      FoodOrderDto.fromJson(
        await _request('/api/v1/food-orders/$id', cancelToken: cancelToken),
      );
  Future<FoodOrderDto> sync(int id, {CancelToken? cancelToken}) async =>
      FoodOrderDto.fromJson(
        await _request(
          '/api/v1/food-orders/$id/sync',
          method: 'POST',
          cancelToken: cancelToken,
        ),
      );
  Future<FoodOrderDto> cancel(int id, {CancelToken? cancelToken}) async =>
      FoodOrderDto.fromJson(
        await _request(
          '/api/v1/food-orders/$id',
          method: 'DELETE',
          cancelToken: cancelToken,
        ),
      );
  Future<PaymentDto> payment(int orderId, int userId) async {
    try {
      final existing = PaymentDto.fromJson(
        await _request('/api/v1/payments/food-order/$orderId'),
      );
      if (existing.status.wireValue == 'SUCCESS' ||
          existing.status.wireValue == 'PENDING' &&
              existing.paymentUrl?.isNotEmpty == true) {
        return existing;
      }
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) rethrow;
    }
    return RemotePaymentRepository(dio)
        .createPayment(userId, CreatePaymentRequestDto(foodOrderId: orderId));
  }
}

final standaloneFoodRepositoryProvider = Provider(
  (ref) => StandaloneFoodRepository(ref.watch(dioProvider)),
);
