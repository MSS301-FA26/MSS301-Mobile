import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/food_order_dto.dart';

class FoodOrderCard extends StatelessWidget {
  const FoodOrderCard({super.key, required this.order});
  final FoodOrderDto order;

  @override
  Widget build(BuildContext context) {
    final created = order.createdAt.toLocal().toString().replaceFirst('T', ' ');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderCode.isEmpty ? '#${order.id}' : order.orderCode,
                  style: AppTextStyles.cardTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                order.status.label,
                style: AppTextStyles.label.copyWith(color: AppColors.gold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(created, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.productName} × ${item.quantity}',
                      style: AppTextStyles.body,
                    ),
                  ),
                  Text(item.lineTotal.format(), style: AppTextStyles.label),
                ],
              ),
            ),
          const Divider(color: AppColors.border),
          Row(
            children: [
              const Expanded(
                child: Text('Tổng cộng', style: AppTextStyles.label),
              ),
              Text(
                order.totalAmount.format(),
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
