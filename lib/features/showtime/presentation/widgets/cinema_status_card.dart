import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'date_selector.dart';

class CinemaStatusCard extends StatelessWidget {
  const CinemaStatusCard({super.key, required this.onInfo, this.selectedDate});

  final VoidCallback onInfo;
  final DateOption? selectedDate;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.sm,
      AppSpacing.md,
      0,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: const Text(
                  'Lịch chiếu & mua vé',
                  style: AppTextStyles.screenTitle,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Giới thiệu rạp',
              onPressed: onInfo,
              icon: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: AppSizes.iconSmall,
              color: AppColors.gold,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                selectedDate == null
                    ? 'Tất cả ngày'
                    : '${selectedDate!.label} · ${selectedDate!.sub}',
                style: AppTextStyles.emphasis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        const Text(
          'Chọn ngày để lọc lịch chiếu, sau đó chọn một suất còn mở bán.',
          style: AppTextStyles.caption,
        ),
      ],
    ),
  );
}
