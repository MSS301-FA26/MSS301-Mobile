import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../models/food_order_dto.dart';
import 'food_order_repository.dart';

class RemoteFoodOrderRepository implements FoodOrderRepository {
  RemoteFoodOrderRepository(this._dio);
  final Dio _dio;

  @override
  Future<List<FoodOrderDto>> getMyOrders() async {
    try {
      final response = await _dio.get('/api/v1/food-orders/my');
      final body = response.data;
      if (body is! Map || body['success'] != true || body['data'] is! List) {
        throw const ApiException(
          type: ApiErrorType.unknown,
          message: 'Invalid food order API response.',
        );
      }
      return (body['data'] as List)
          .map(
            (item) =>
                FoodOrderDto.fromJson(Map<String, Object?>.from(item as Map)),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      if (error.error case final ApiException mapped) throw mapped;
      rethrow;
    }
  }
}
