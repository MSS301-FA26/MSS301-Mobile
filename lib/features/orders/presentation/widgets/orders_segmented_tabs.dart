import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_surface.dart';

enum OrdersTab { upcoming, completed }

class OrdersSegmentedTabs extends StatelessWidget {
  const OrdersSegmentedTabs({
    super.key,
    required this.selected,
    required this.upcomingCount,
    required this.completedCount,
    required this.onSelected,
  });

  final OrdersTab selected;
  final int upcomingCount;
  final int completedCount;
  final ValueChanged<OrdersTab> onSelected;

  @override
  Widget build(BuildContext context) => AppSurface(
    padding: const EdgeInsets.all(AppSpacing.xxs),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
        final vertical = constraints.maxWidth < 360 * textScale;
        final upcoming = _TabButton(
          label: 'Sắp chiếu',
          count: upcomingCount,
          selected: selected == OrdersTab.upcoming,
          onTap: () => onSelected(OrdersTab.upcoming),
        );
        final completed = _TabButton(
          label: 'Lịch sử đã xem',
          count: completedCount,
          selected: selected == OrdersTab.completed,
          onTap: () => onSelected(OrdersTab.completed),
        );
        return vertical
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  upcoming,
                  const SizedBox(height: AppSpacing.xxs),
                  completed,
                ],
              )
            : Row(
                children: [
                  Expanded(child: upcoming),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(child: completed),
                ],
              );
      },
    ),
  );
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: InkWell(
      onTap: onTap,
      borderRadius: AppRadii.control,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: AppSizes.buttonHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : Colors.transparent,
          borderRadius: AppRadii.control,
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xxs,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.label.copyWith(
                color: selected
                    ? AppColors.background
                    : AppColors.textSecondary,
              ),
            ),
            Text(
              '$count',
              style: AppTextStyles.label.copyWith(
                color: selected
                    ? AppColors.background
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
