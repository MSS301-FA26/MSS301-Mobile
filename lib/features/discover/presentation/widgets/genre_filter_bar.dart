import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../movie/data/models/movie_dto.dart';

class GenreFilterBar extends StatelessWidget {
  const GenreFilterBar({
    super.key,
    required this.genres,
    required this.selectedId,
    required this.onSelected,
  });

  final List<GenreDto> genres;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SingleChildScrollView(
        key: const ValueKey('discover-genre-scroll'),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _GenrePill(
              label: 'Tất cả thể loại',
              selected: selectedId == null,
              onTap: () => onSelected(null),
            ),
            for (final genre in genres)
              _GenrePill(
                label: genre.name,
                selected: selectedId == genre.id,
                onTap: () => onSelected(genre.id),
              ),
          ],
        ),
      ),
    ],
  );
}

class _GenrePill extends StatelessWidget {
  const _GenrePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? AppColors.gold : AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.black : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
