import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AgeBadge extends StatelessWidget {
  const AgeBadge({super.key, required this.rating});

  final String rating;

  @override
  Widget build(BuildContext context) {
    final isAdult = rating == '18+';
    final isAllAges = rating == 'P';
    final color = isAdult
        ? AppColors.adultBadge
        : isAllAges
        ? AppColors.allAgesBadge
        : AppColors.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        rating,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: isAdult ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
