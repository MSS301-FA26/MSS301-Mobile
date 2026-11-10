import 'package:flutter/material.dart';

import '../../../../core/money/vnd_money.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';

class ConcessionSelectionBar extends StatelessWidget {
  const ConcessionSelectionBar({
    super.key,
    required this.subtotal,
    required this.hasSelection,
    required this.selectedProductCount,
    required this.selectedQuantity,
    required this.isBusy,
    required this.onContinue,
  });

  final VndMoney subtotal;
  final bool hasSelection;
  final int selectedProductCount;
  final int selectedQuantity;
  final bool isBusy;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      key: const ValueKey('concessions-summary'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                hasSelection ? 'Tạm tính' : 'Bỏ qua bắp nước',
                style: AppTextStyles.emphasis,
              ),
              Text(
                subtotal.format(),
                key: const ValueKey('concessions-food-subtotal'),
                style: AppTextStyles.price.copyWith(color: AppColors.gold),
              ),
              if (hasSelection)
                Text(
                  '$selectedProductCount sản phẩm · $selectedQuantity phần',
                  style: AppTextStyles.caption,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          const Text(
            'Giá cuối cùng theo báo giá Checkout.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            key: const ValueKey('concessions-continue'),
            label: isBusy ? 'Đang cập nhật…' : 'Tiếp tục',
            loading: isBusy,
            icon: Icons.arrow_forward_rounded,
            fullWidth: true,
            onPressed: onContinue,
          ),
        ],
      ),
    ),
  );
}
