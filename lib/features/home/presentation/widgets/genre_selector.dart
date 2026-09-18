import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class GenreSelector extends StatelessWidget {
  const GenreSelector({
    super.key,
    required this.selectedGenre,
    required this.onSelected,
  });

  final String selectedGenre;
  final ValueChanged<String> onSelected;

  static const genres = [
    'Tất cả',
    'Sci-Fi Cyber',
    'Cinematic Noir',
    'Hoạt hình',
    'Pure Action',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          for (final genre in genres)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ChoiceChip(
                label: Text(genre),
                selected: selectedGenre == genre,
                onSelected: (_) => onSelected(genre),
                showCheckmark: false,
                backgroundColor: AppColors.surface,
                selectedColor: AppColors.surfaceRaised,
                side: BorderSide(
                  color: selectedGenre == genre
                      ? AppColors.gold
                      : AppColors.border,
                ),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selectedGenre == genre
                      ? AppColors.text
                      : AppColors.textMuted,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.control,
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}
