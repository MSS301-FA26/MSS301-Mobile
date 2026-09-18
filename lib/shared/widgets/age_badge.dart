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
    final isAdult = rating == '18+';
    final isAllAges = rating == 'P';
    final color = isAdult
        ? AppColors.adultBadge
        : isAllAges
        ? AppColors.allAgesBadge
        : AppColors.gold;
    final isHero = variant == AgeBadgeVariant.hero;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isHero ? 8 : 6, vertical: 3),
      decoration: BoxDecoration(
        color: isHero ? AppColors.goldSurface : color,
        borderRadius: BorderRadius.circular(4),
        border: isHero ? Border.all(color: AppColors.goldBorder) : null,
      ),
      child: Text(
        rating,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: isHero
              ? AppColors.gold
              : (isAdult ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
