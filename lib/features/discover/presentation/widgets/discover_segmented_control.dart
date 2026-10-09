import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class DiscoverSegmentedControl extends StatelessWidget {
  const DiscoverSegmentedControl({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final DiscoverMovieTab selected;
  final ValueChanged<DiscoverMovieTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _SegmentButton(
            label: 'Đang chiếu',
            selected: selected == DiscoverMovieTab.now,
            onTap: () => onSelected(DiscoverMovieTab.now),
          ),
          _SegmentButton(
            label: 'Sắp chiếu',
            selected: selected == DiscoverMovieTab.soon,
            onTap: () => onSelected(DiscoverMovieTab.soon),
          ),
        ],
      ),
    );
  }
}

enum DiscoverMovieTab { now, soon }

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          key: ValueKey('discover-status-$label'),
          onTap: onTap,
          borderRadius: AppRadii.control,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: AppSizes.buttonHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.gold : Colors.transparent,
              borderRadius: AppRadii.control,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.emphasis.copyWith(
                color: selected ? AppColors.background : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
