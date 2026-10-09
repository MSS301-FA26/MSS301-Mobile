import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../movie/data/models/catalog_enums.dart';
import '../models/showtime_models.dart';

class ShowtimeSlotButton extends StatelessWidget {
  const ShowtimeSlotButton({
    super.key,
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  final ShowtimeSlot slot;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = switch (slot.status) {
      ShowtimeStatus.open => 'Mở bán',
      ShowtimeStatus.scheduled => 'Chưa mở bán',
      ShowtimeStatus.cancelled => 'Đã hủy',
      ShowtimeStatus.completed => 'Đã kết thúc',
      ShowtimeStatus.unknown => 'Không khả dụng',
    };
    final date =
        '${slot.startAt.day.toString().padLeft(2, '0')}/${slot.startAt.month.toString().padLeft(2, '0')}';
    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      label:
          'Suất chiếu $date, ${slot.time}, kết thúc ${slot.endTime}, ${slot.priceDisplay}, $status',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.goldSurface : AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.control,
          side: BorderSide(
            color: selected ? AppColors.gold : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          key: ValueKey('showtime-slot-${slot.id}'),
          onTap: onTap,
          borderRadius: AppRadii.control,
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSizes.buttonHeight),
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(date, style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  slot.time,
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: slot.isBookable
                        ? AppColors.text
                        : AppColors.textMuted,
                  ),
                ),
                Text(slot.endTime, style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  slot.priceDisplay,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.label.copyWith(color: AppColors.gold),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  status,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
                if (selected) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  const Icon(
                    Icons.check_circle,
                    size: AppSizes.iconSmall,
                    color: AppColors.gold,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
