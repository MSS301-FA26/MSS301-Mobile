import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class DateOption {
  const DateOption({
    required this.date,
    required this.label,
    required this.sub,
  });

  final DateTime date;
  final String label;
  final String sub;
}

class DateSelector extends StatelessWidget {
  const DateSelector({
    super.key,
    required this.dates,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<DateOption> dates;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < dates.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: _DatePill(
                  option: dates[i],
                  selected: selectedIndex == i,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final DateOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.card,
      child: Container(
        width: 66,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceRaised : AppColors.surface,
          borderRadius: AppRadii.card,
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              option.label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.meta.copyWith(
                color: selected ? AppColors.gold : AppColors.textDisabled,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              option.sub,
              style: AppTextStyles.label.copyWith(
                color: selected ? AppColors.text : AppColors.textSecondary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
