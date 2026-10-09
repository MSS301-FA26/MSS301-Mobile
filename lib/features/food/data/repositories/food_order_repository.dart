import '../models/food_order_dto.dart';

abstract interface class FoodOrderRepository {
  Future<List<FoodOrderDto>> getMyOrders();
}
