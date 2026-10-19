import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
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
            _FoodImage(product: product, size: 104),
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
                  const SizedBox(height: 8),
                  Text(
                    product.price.format(),
                    style: AppTextStyles.cardTitle.copyWith(
                      color: AppColors.gold,
                      fontSize: 18,
                    ),
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
                  TextButton(
                    key: ValueKey('food-details-${product.selectionKey}'),
                    onPressed: () => _showDetails(context),
                    child: const Text('Xem chi tiết'),
                  ),
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

  void _showDetails(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (context) => SafeArea(
      top: false,
      child: ConstrainedBox(
        key: ValueKey('food-details-sheet-${product.selectionKey}'),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .82,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      product.isCombo ? 'Chi tiết combo' : 'Chi tiết sản phẩm',
                      style: AppTextStyles.cardTitle,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('food-details-close'),
                    tooltip: 'Đóng chi tiết',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FoodImage(
                      product: product,
                      width: double.infinity,
                      height: 210,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      product.isCombo ? 'COMBO BẮP NƯỚC' : 'BẮP & NƯỚC',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(product.name, style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 12),
                    Text(_availability, style: AppTextStyles.caption),
                    const SizedBox(height: 16),
                    Text(
                      product.isCombo ? 'Thông tin combo' : 'Mô tả sản phẩm',
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      product.description?.trim().isNotEmpty == true
                          ? product.description!.trim()
                          : 'Thông tin chi tiết đang được cập nhật.',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.surfaceRaised,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Giá mỗi phần',
                          style: AppTextStyles.caption,
                        ),
                        Text(
                          product.price.format(),
                          style: AppTextStyles.cardTitle.copyWith(
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      key: ValueKey('food-details-add-${product.selectionKey}'),
                      label: quantity > 0 ? 'Thêm 1 phần' : 'Thêm vào đơn',
                      onPressed: enabled && product.isAvailable && quantity < 8
                          ? () {
                              Navigator.pop(context);
                              onChange(1);
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FoodImage extends StatelessWidget {
  const _FoodImage({
    required this.product,
    this.size = 104,
    this.width,
    this.height,
  });
  final FoodProductDto product;
  final double size;
  final double? width;
  final double? height;

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
        width: width ?? size,
        height: height ?? size,
        child: ColoredBox(
          color: AppColors.surfaceRaised,
          child: valid
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
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
