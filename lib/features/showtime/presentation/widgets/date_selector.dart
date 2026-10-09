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
                  index: i,
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
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final DateOption option;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${option.label}, ${option.sub}',
      child: InkWell(
        key: ValueKey('date-option-$index'),
        onTap: onTap,
        borderRadius: AppRadii.card,
        child: Container(
          constraints: const BoxConstraints(minWidth: 82, minHeight: 64),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.gold : AppColors.surface,
            borderRadius: AppRadii.card,
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.border,
            ),
          ),
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option.label,
                  style: AppTextStyles.caption.copyWith(
                    color: selected
                        ? AppColors.background
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  option.sub,
                  style: AppTextStyles.emphasis.copyWith(
                    color: selected ? AppColors.background : AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
