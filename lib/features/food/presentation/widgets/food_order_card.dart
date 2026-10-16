import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/checkout_summary.dart';
import '../../data/models/food_order_dto.dart';

class FoodOrderCard extends StatelessWidget {
  const FoodOrderCard({super.key, required this.order});
  final FoodOrderDto order;

  @override
  Widget build(BuildContext context) {
    final created = order.createdAt.toLocal().toString().split('.').first;
    final (color, icon) = switch (order.status) {
      FoodOrderStatus.pendingPayment => (AppColors.gold, Icons.schedule),
      FoodOrderStatus.paid => (
        const Color(0xFF62D9A3),
        Icons.check_circle_outline,
      ),
      FoodOrderStatus.pickedUp => (
        const Color(0xFF92B9FF),
        Icons.shopping_bag_outlined,
      ),
      FoodOrderStatus.cancelled => (
        const Color(0xFFFF9393),
        Icons.cancel_outlined,
      ),
      FoodOrderStatus.expired => (
        AppColors.textMuted,
        Icons.timer_off_outlined,
      ),
      _ => (AppColors.textMuted, Icons.help_outline),
    };
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
          StatusBadge(label: order.status.label, color: color, icon: icon),
          const SizedBox(height: 10),
          Text(
            order.orderCode.isEmpty ? '#${order.id}' : order.orderCode,
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(created, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          for (final item in order.items)
            CheckoutLine(
              '${item.productName} × ${item.quantity}',
              item.lineTotal.format(),
            ),
          const Divider(color: AppColors.border),
          CheckoutLine(
            'Tổng cộng',
            order.totalAmount.format(),
            emphasized: true,
          ),
        ],
      ),
    );
  }
}
