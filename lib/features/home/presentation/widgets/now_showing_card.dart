import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/age_badge.dart';
import '../../../movie/presentation/models/movie.dart';

class NowShowingCard extends StatelessWidget {
  const NowShowingCard({
    super.key,
    required this.movie,
    required this.onOpen,
    required this.onBook,
  });

  final Movie movie;
  final VoidCallback onOpen;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadii.card,
        child: InkWell(
          onTap: onOpen,
          borderRadius: AppRadii.card,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: AppRadii.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 2 / 3,
                  child: ClipRRect(
                    borderRadius: AppRadii.control,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AppImage(asset: movie.posterAsset),
                        Positioned(
                          top: 6,
                          left: 6,
                          child: AgeBadge(rating: movie.ageRating),
                        ),
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background.withValues(
                                alpha: 0.86,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 13,
                                  color: AppColors.gold,
                                ),
                                Text(
                                  '${movie.rating}',
                                  style: const TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 34,
                  child: Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle,
                  ),
                ),
                Text(
                  '${movie.genre} • ${movie.duration}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: OutlinedButton.icon(
                    key: ValueKey('now-showing-book-${movie.id}'),
                    onPressed: onBook,
                    icon: const Icon(
                      Icons.confirmation_number_outlined,
                      size: 14,
                    ),
                    label: const Text(
                      'Đặt vé',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      backgroundColor: AppColors.surfaceRaised,
                      side: const BorderSide(color: AppColors.border),
                      padding: EdgeInsets.zero,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadii.small,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
