import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Sắp chiếu',
            count: upcomingCount,
            selected: selected == OrdersTab.upcoming,
            onTap: () => onSelected(OrdersTab.upcoming),
          ),
          _TabButton(
            label: 'Lịch sử đã xem',
            count: completedCount,
            selected: selected == OrdersTab.completed,
            onTap: () => onSelected(OrdersTab.completed),
          ),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.control,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.gold : Colors.transparent,
            borderRadius: AppRadii.control,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.black : AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.black.withValues(alpha: 0.18)
                      : AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? Colors.black : AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
