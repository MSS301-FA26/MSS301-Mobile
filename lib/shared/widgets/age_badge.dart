import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum AgeBadgeVariant { solid, hero }

class AgeBadge extends StatelessWidget {
  const AgeBadge({
    super.key,
    required this.rating,
    this.variant = AgeBadgeVariant.solid,
  });

  final String rating;
  final AgeBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final normalizedRating = rating.trim().toUpperCase();
    final isAdult = normalizedRating == '18+' || normalizedRating == 'T18';
    final isAllAges = normalizedRating == 'P';
    final isTeen = normalizedRating == '16+' || normalizedRating == 'T16';
    final isChild = normalizedRating == '13+' || normalizedRating == 'T13';
    final color = isAdult
        ? AppColors.adultBadge
        : isAllAges
        ? AppColors.allAgesBadge
        : isTeen
        ? AppColors.warning
        : isChild
        ? AppColors.gold
        : AppColors.gold;
    final isHero = variant == AgeBadgeVariant.hero;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isHero ? AppSpacing.xs : AppSizes.badgeHorizontalPadding,
        vertical: AppSizes.badgeVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: isHero ? AppColors.goldSurface : color,
        borderRadius: AppRadii.small,
        border: isHero ? Border.all(color: AppColors.goldBorder) : null,
      ),
      child: Text(
        rating,
        style: AppTextStyles.meta.copyWith(
          fontWeight: FontWeight.w800,
          color: isHero || isAdult ? AppColors.text : Colors.black,
        ),
      ),
    );
  }
}
