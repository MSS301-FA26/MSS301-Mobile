import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_chip.dart';

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
    'Vision Quest Hoạt hình',
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
              child: AppChip(
                label: genre,
                selected: selectedGenre == genre,
                onPressed: () => onSelected(genre),
              ),
            ),
        ],
      ),
    );
  }
}
