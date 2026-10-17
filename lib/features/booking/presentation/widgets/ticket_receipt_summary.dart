import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../orders/data/models/booking_dto.dart';

/// Read-only receipt values from the same booking, without recalculating totals.
class TicketReceiptSummary extends StatelessWidget {
  const TicketReceiptSummary({super.key, required this.booking});

  final BookingDto booking;

  @override
  Widget build(BuildContext context) => AppSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (booking.foods.isNotEmpty) ...[
          const AppSectionHeader(title: 'Bắp nước trong đơn'),
          const SizedBox(height: AppSpacing.sm),
          for (final food in booking.foods) ...[
            Text(
              '${food.productName} × ${food.quantity}',
              style: AppTextStyles.emphasis,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(food.lineTotal.format(), style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.sm),
          ],
          const Divider(),
          const SizedBox(height: AppSpacing.md),
        ],
        const AppSectionHeader(title: 'Thông tin thanh toán'),
        const SizedBox(height: AppSpacing.md),
        _ReceiptValue(label: 'Tạm tính', value: booking.subtotal.format()),
        const SizedBox(height: AppSpacing.sm),
        _ReceiptValue(
          label: 'Giảm giá',
          value: booking.discountAmount.format(),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('Tổng thanh toán', style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          booking.totalAmount.format(),
          style: AppTextStyles.price.copyWith(color: AppColors.gold),
        ),
      ],
    ),
  );
}

class _ReceiptValue extends StatelessWidget {
  const _ReceiptValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.xxs,
    alignment: WrapAlignment.spaceBetween,
    children: [
      Text(label, style: AppTextStyles.body),
      Text(value, style: AppTextStyles.emphasis),
    ],
  );
}
