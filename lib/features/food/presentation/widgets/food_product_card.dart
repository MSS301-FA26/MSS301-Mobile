import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../movie/data/models/catalog_enums.dart';
import '../../../movie/data/models/food_quote_dto.dart';

class FoodProductCard extends StatelessWidget {
  const FoodProductCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.onChange,
    this.enabled = true,
  });

  final FoodProductDto product;
  final int quantity;
  final ValueChanged<int> onChange;
  final bool enabled;

  String get _availability => switch (product.status) {
    FoodItemStatus.active =>
      quantity == 8 ? 'Đã đạt tối đa 8' : 'Tối đa 8 mỗi loại',
    FoodItemStatus.lowStock => 'Sắp hết • Tạm ngừng đặt',
    FoodItemStatus.outOfStock => 'Tạm hết hàng',
    FoodItemStatus.inactive => 'Tạm ngừng bán',
    _ => 'Chưa thể đặt',
  };

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('food-card-${product.selectionKey}'),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: quantity > 0 ? AppColors.goldSurface : AppColors.surface,
      borderRadius: AppRadii.card,
      border: Border.all(
        color: quantity > 0 ? AppColors.gold : AppColors.border,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FoodImage(product: product),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.isCombo ? 'COMBO' : 'BẮP & NƯỚC',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
                  ),
                  if (product.description?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              product.price.format(),
              style: AppTextStyles.cardTitle.copyWith(
                color: AppColors.gold,
                fontSize: 18,
              ),
            ),
            Text(
              _availability,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              quantity > 0 ? 'Đã chọn $quantity' : 'Số lượng',
              style: AppTextStyles.caption,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: ValueKey('food-minus-${product.selectionKey}'),
                  tooltip: 'Giảm ${product.name}',
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                  onPressed: enabled && quantity > 0
                      ? () => onChange(-1)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Semantics(
                  liveRegion: true,
                  label: '${product.name}, số lượng $quantity',
                  child: ExcludeSemantics(
                    child: Text('$quantity', style: AppTextStyles.cardTitle),
                  ),
                ),
                IconButton(
                  key: ValueKey('food-plus-${product.selectionKey}'),
                  tooltip: 'Tăng ${product.name}',
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                  onPressed: enabled && product.isAvailable && quantity < 8
                      ? () => onChange(1)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.gold,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

class _FoodImage extends StatelessWidget {
  const _FoodImage({required this.product});
  final FoodProductDto product;

  @override
  Widget build(BuildContext context) {
    final url = product.imageUrl?.trim() ?? '';
    final uri = Uri.tryParse(url);
    final valid =
        uri != null &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'https' || uri.scheme == 'http');
    final fallback = Center(
      child: Icon(
        product.isCombo ? Icons.fastfood_rounded : Icons.local_drink_rounded,
        color: AppColors.gold,
        size: 32,
      ),
    );
    return ClipRRect(
      borderRadius: AppRadii.control,
      child: SizedBox(
        key: ValueKey('food-image-${product.selectionKey}'),
        width: 80,
        height: 80,
        child: ColoredBox(
          color: AppColors.surfaceRaised,
          child: valid
              ? Image.network(
                  url,
                  fit: BoxFit.contain,
                  semanticLabel: product.name,
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : fallback,
                  errorBuilder: (_, _, _) => fallback,
                )
              : fallback,
        ),
      ),
    );
  }
}
