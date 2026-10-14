import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../models/food_order_dto.dart';
import 'food_order_repository.dart';
import 'remote_food_order_repository.dart';
import '../../../auth/application/auth_session.dart';

final foodOrderRepositoryProvider = Provider<FoodOrderRepository>(
  (ref) => RemoteFoodOrderRepository(ref.watch(dioProvider)),
);
final myFoodOrdersProvider = FutureProvider.autoDispose<List<FoodOrderDto>>((
  ref,
) {
  final userId = ref.watch(
    authSessionProvider.select((auth) => auth.session?.user.id),
  );
  if (userId == null) return Future.value(const []);
  return ref.watch(foodOrderRepositoryProvider).getMyOrders();
});
