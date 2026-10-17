import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../models/showtime_models.dart';

class ShowtimeSelectionBar extends StatelessWidget {
  const ShowtimeSelectionBar({
    super.key,
    required this.slot,
    required this.onContinue,
  });

  final ShowtimeSlot slot;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final date =
        '${slot.startAt.day.toString().padLeft(2, '0')}/${slot.startAt.month.toString().padLeft(2, '0')}/${slot.startAt.year}';
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xxs,
              children: [
                Text(
                  'Đã chọn ${slot.time} · $date',
                  style: AppTextStyles.emphasis,
                ),
                Text(
                  slot.priceDisplay,
                  style: AppTextStyles.emphasis.copyWith(color: AppColors.gold),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              key: const ValueKey('showtime-continue'),
              label: 'Vé & Ghế',
              icon: Icons.arrow_forward_rounded,
              fullWidth: true,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}
