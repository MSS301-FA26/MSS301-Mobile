import 'package:flutter/material.dart';

import '../../../../core/money/vnd_money.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';

class FoodCartBar extends StatelessWidget {
  const FoodCartBar({
    super.key,
    required this.total,
    required this.quantity,
    required this.label,
    required this.buttonKey,
    required this.onContinue,
    this.detail,
  });

  final VndMoney total;
  final int quantity;
  final String label;
  final Key buttonKey;
  final VoidCallback? onContinue;
  final String? detail;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final summary = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quantity == 0
                    ? 'Chưa chọn bắp nước'
                    : '$quantity sản phẩm • Tạm tính',
                style: AppTextStyles.caption,
              ),
              Text(
                total.format(),
                style: AppTextStyles.cardTitle.copyWith(
                  color: AppColors.gold,
                  fontSize: 20,
                ),
              ),
              if (detail != null)
                Text(
                  detail!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
            ],
          );
          final button = AppButton(
            key: buttonKey,
            label: label,
            onPressed: onContinue,
          );
          if (constraints.maxWidth < 330 ||
              MediaQuery.textScalerOf(context).scale(14) > 18) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [summary, const SizedBox(height: 8), button],
            );
          }
          return Row(
            children: [
              Expanded(child: summary),
              const SizedBox(width: 12),
              Flexible(child: SizedBox(width: 180, child: button)),
            ],
          );
        },
      ),
    ),
  );
}
