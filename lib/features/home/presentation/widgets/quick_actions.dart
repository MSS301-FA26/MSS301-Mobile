import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key, required this.onUnavailable});
  final void Function(String) onUnavailable;

  @override
  Widget build(BuildContext context) {
    final actions =
        <({String label, IconData icon, Color foreground, Color background})>[
          (
            label: 'Bắp & Nước',
            icon: Icons.fastfood_outlined,
            foreground: AppColors.lavender,
            background: AppColors.purple,
          ),
          (
            label: 'PopBot AI',
            icon: Icons.smart_toy_outlined,
            foreground: AppColors.lavender,
            background: AppColors.purple,
          ),
          (
            label: 'Ưu đãi VIP',
            icon: Icons.stars_outlined,
            foreground: AppColors.gold,
            background: AppColors.goldSurface,
          ),
          (
            label: 'CinePoints',
            icon: Icons.loyalty_outlined,
            foreground: AppColors.text,
            background: AppColors.surfaceRaised,
          ),
        ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Material(
                color: AppColors.surface,
                borderRadius: AppRadii.card,
                child: InkWell(
                  onTap: () => onUnavailable(actions[i].label),
                  borderRadius: AppRadii.card,
                  child: Container(
                    height: 92,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: AppRadii.card,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: actions[i].background,
                            borderRadius: AppRadii.control,
                          ),
                          child: Icon(
                            actions[i].icon,
                            size: 24,
                            color: actions[i].foreground,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          actions[i].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
