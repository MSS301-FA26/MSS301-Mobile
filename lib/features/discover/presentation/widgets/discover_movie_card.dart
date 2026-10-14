import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/age_badge.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../movie/presentation/models/movie.dart';

class DiscoverMovieCard extends StatelessWidget {
  const DiscoverMovieCard({
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
    return InkWell(
      onTap: onOpen,
      borderRadius: AppRadii.card,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.card,
          border: Border.all(color: AppColors.border),
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
                    if (movie.rating != null)
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: AppColors.gold,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                movie.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
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
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: MediaQuery.textScalerOf(context).scale(14) * 1.3 * 2,
              child: Text(
                movie.title.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(movie.duration, style: AppTextStyles.caption),
            Text(
              movie.genre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                onPressed: movie.isNowShowing ? onBook : onOpen,
                icon: movie.isNowShowing
                    ? Icons.confirmation_number_outlined
                    : Icons.arrow_forward_rounded,
                label: movie.isNowShowing ? 'Đặt vé' : 'Chi tiết',
                variant: AppButtonVariant.secondary,
                height: 48,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
