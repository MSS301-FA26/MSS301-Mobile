import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class DiscoverSegmentedControl extends StatelessWidget {
  const DiscoverSegmentedControl({
    super.key,
    required this.selected,
    required this.nowCount,
    required this.soonCount,
    required this.onSelected,
  });

  final DiscoverMovieTab selected;
  final int? nowCount;
  final int? soonCount;
  final ValueChanged<DiscoverMovieTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _SegmentButton(
            label: nowCount == null
                ? 'Phim đang chiếu'
                : 'Phim đang chiếu ($nowCount)',
            selected: selected == DiscoverMovieTab.now,
            onTap: () => onSelected(DiscoverMovieTab.now),
          ),
          _SegmentButton(
            label: soonCount == null
                ? 'Phim sắp chiếu'
                : 'Phim sắp chiếu ($soonCount)',
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
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.control,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.gold : Colors.transparent,
            borderRadius: AppRadii.control,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.black : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
