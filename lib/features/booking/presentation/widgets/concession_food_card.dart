import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../movie/data/models/catalog_enums.dart';
import '../../../movie/data/models/food_quote_dto.dart';

class ConcessionFoodCard extends StatelessWidget {
  const ConcessionFoodCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final FoodProductDto product;
  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl;
    final statusLabel = switch (product.status) {
      FoodItemStatus.active => 'Có thể chọn',
      FoodItemStatus.lowStock => 'Sắp hết',
      FoodItemStatus.inactive => 'Ngừng bán',
      FoodItemStatus.outOfStock => 'Tạm hết hàng',
      FoodItemStatus.unknown => 'Trạng thái chưa xác định',
    };
    return Semantics(
      key: ValueKey('food-card-${product.id}'),
      container: true,
      selected: quantity > 0,
      child: AppSurface(
        borderColor: quantity > 0 ? AppColors.gold : AppColors.border,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: AppSpacing.headerHeight,
                  height: AppSpacing.headerHeight,
                  child: imageUrl?.trim().isNotEmpty ?? false
                      ? AppImage(
                          asset: imageUrl!,
                          aspectRatio: 1,
                          semanticLabel: 'Ảnh ${product.name}',
                        )
                      : ExcludeSemantics(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceRaised,
                              borderRadius: AppRadii.small,
                            ),
                            child: Icon(
                              product.isCombo
                                  ? Icons.fastfood_outlined
                                  : Icons.local_drink_outlined,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          product.name,
                          style: AppTextStyles.cardTitle,
                        ),
                      ),
                      if (product.description?.trim().isNotEmpty ?? false) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(product.description!, style: AppTextStyles.body),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppChip(label: product.isCombo ? 'Combo' : 'Món lẻ'),
                Text(statusLabel, style: AppTextStyles.caption),
                if (quantity > 0)
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: AppSizes.iconSmall,
                        color: AppColors.gold,
                      ),
                      SizedBox(width: AppSpacing.xxs),
                      Text('Đã chọn', style: AppTextStyles.emphasis),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              product.price.format(),
              style: AppTextStyles.price.copyWith(color: AppColors.gold),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xxs,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Số lượng', style: AppTextStyles.body),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: ValueKey('food-minus-${product.id}'),
                      tooltip: 'Giảm ${product.name}',
                      onPressed: onDecrease,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Semantics(
                      key: ValueKey('food-quantity-${product.id}'),
                      label: 'Số lượng ${product.name}: $quantity',
                      liveRegion: true,
                      child: ExcludeSemantics(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          child: Text(
                            '$quantity',
                            style: AppTextStyles.emphasis,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      key: ValueKey('food-plus-${product.id}'),
                      tooltip: 'Tăng ${product.name}',
                      onPressed: onIncrease,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
