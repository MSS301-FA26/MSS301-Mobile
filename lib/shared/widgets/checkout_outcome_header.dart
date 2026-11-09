import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Shared receipt hierarchy; callers supply the server-confirmed state.
class CheckoutOutcomeHeader extends StatelessWidget {
  const CheckoutOutcomeHeader({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.reference,
    required this.amount,
  });

  final IconData icon;
  final Color color;
  final String title, description, reference, amount;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      borderRadius: AppRadii.card,
      border: Border.all(color: color.withValues(alpha: .35)),
    ),
    child: Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 44, color: color),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          Text(description, style: AppTextStyles.caption),
          const SizedBox(height: 18),
          Text(
            amount,
            style: AppTextStyles.sectionTitle.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: 6),
          Text(reference, style: AppTextStyles.caption),
        ],
      ),
    ),
  );
}
