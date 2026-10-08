import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/age_badge.dart';
import '../../../movie/presentation/models/movie.dart';

class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.movie,
    required this.activeIndex,
    required this.count,
    required this.onOpen,
    required this.onBook,
    required this.onTrailer,
    required this.onDot,
  });

  final Movie movie;
  final int activeIndex;
  final int count;
  final VoidCallback onOpen;
  final VoidCallback onBook;
  final VoidCallback onTrailer;
  final void Function(int) onDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  key: ValueKey('hero-open-${movie.id}'),
                  onTap: onOpen,
                  child: AppImage(
                    asset: movie.bannerAsset ?? movie.posterAsset,
                  ),
                ),
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.16),
                          AppColors.background.withValues(alpha: 0.65),
                          AppColors.background,
                        ],
                        stops: const [0.15, 0.58, 1],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AgeBadge(
                            rating: movie.ageRating,
                            variant: AgeBadgeVariant.hero,
                          ),
                          const SizedBox(width: 7),
                          if (movie.format.isNotEmpty) ...[
                            Flexible(child: _HeroTag(movie.format)),
                            const SizedBox(width: 7),
                          ],
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          Expanded(
                            child: Text(
                              movie.duration,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: AppColors.gold,
                          ),
                          Text(
                            movie.ratingCount.isEmpty
                                ? '${movie.rating}'
                                : '${movie.rating} (${movie.ratingCount})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        movie.title.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.heroTitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        movie.tagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              key: ValueKey('hero-book-${movie.id}'),
                              label: 'Đặt vé ngay',
                              icon: Icons.confirmation_number_outlined,
                              onPressed: onBook,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: AppButton(
                              label: 'Xem trailer',
                              icon: Icons.play_circle_outline,
                              onPressed: onTrailer,
                              variant: AppButtonVariant.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < count; i++)
                  GestureDetector(
                    onTap: () => onDot(i),
                    child: Container(
                      width: i == activeIndex ? 24 : 7,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == activeIndex
                            ? AppColors.gold
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
    ),
  );
}
