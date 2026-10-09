import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/age_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/app_surface.dart';
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
    final releaseDate = movie.releaseDate;
    final releaseLabel = movie.isComingSoon && releaseDate != null
        ? 'Khởi chiếu ${releaseDate.day.toString().padLeft(2, '0')}/${releaseDate.month.toString().padLeft(2, '0')}/${releaseDate.year}'
        : movie.duration;
    return InkWell(
      key: ValueKey('discover-movie-${movie.id}'),
      onTap: onOpen,
      borderRadius: AppRadii.card,
      child: AppSurface(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: AppRadii.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: AppSizes.posterAspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(
                      asset: movie.posterAsset,
                      borderRadius: BorderRadius.zero,
                      semanticLabel: 'Poster ${movie.title}',
                    ),
                    Positioned(
                      top: AppSpacing.xs,
                      left: AppSpacing.xs,
                      child: AgeBadge(rating: movie.ageRating),
                    ),
                    if (movie.rating > 0)
                      Positioned(
                        right: AppSpacing.xs,
                        bottom: AppSpacing.xs,
                        child: AppSurface(
                          color: AppColors.surfaceOverlay,
                          padding: const EdgeInsets.all(AppSpacing.xxs),
                          borderRadius: AppRadii.small,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: AppSizes.iconSmall,
                                color: AppColors.gold,
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                              Text(
                                movie.rating.toStringAsFixed(1),
                                style: AppTextStyles.emphasis,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        movie.genre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        releaseLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                      const Spacer(),
                      AppButton(
                        key: ValueKey('discover-book-${movie.id}'),
                        label: 'Đặt vé',
                        onPressed: onBook,
                        icon: Icons.confirmation_number_outlined,
                        variant: AppButtonVariant.secondary,
                        fullWidth: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
