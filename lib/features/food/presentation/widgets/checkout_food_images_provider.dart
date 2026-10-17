import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../movie/data/models/food_quote_dto.dart';
import '../../../movie/data/repositories/catalog_providers.dart';

// Optional presentation enrichment only. Snapshot names and prices never come
// from this lookup; either catalog request can fail without blocking checkout.
final checkoutFoodImagesProvider =
    FutureProvider.autoDispose<Map<String, String>>((ref) async {
      final repository = ref.watch(catalogRepositoryProvider);
      Future<List<FoodProductDto>> optional(
        Future<List<FoodProductDto>> request,
      ) async {
        try {
          return await request;
        } catch (_) {
          return const [];
        }
      }

      final results = await Future.wait([
        optional(repository.getFoodItems()),
        optional(repository.getFoodCombos()),
      ]);
      return {
        for (final product in results.expand((items) => items))
          if (product.imageUrl?.trim().isNotEmpty == true)
            product.selectionKey: product.imageUrl!.trim(),
      };
    });
