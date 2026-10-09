import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/age_badge.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../data/models/catalog_enums.dart';
import '../../data/models/review_dto.dart';
import '../models/movie.dart';

class MovieDetailHeader extends StatelessWidget {
  const MovieDetailHeader({super.key, required this.movie, this.reviewSummary});

  final Movie movie;
  final ReviewSummaryDto? reviewSummary;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final background = movie.bannerAsset ?? movie.posterAsset;
      final posterWidth = ((constraints.maxWidth - AppSpacing.md * 2) / 3)
          .clamp(0.0, 144.0);
      final backdropHeight =
          (constraints.maxWidth / AppSizes.backdropAspectRatio).clamp(
            0.0,
            220.0,
          );
      final summary = reviewSummary;
      final hasSummaryRating =
          summary != null &&
          summary.totalReviews > 0 &&
          summary.averageRating > 0;
      final rating = hasSummaryRating
          ? summary.averageRating
          : movie.rating > 0
          ? movie.rating
          : null;
      final status = switch (movie.status) {
        MovieStatus.nowShowing => 'Đang chiếu',
        MovieStatus.upcoming => 'Sắp chiếu',
        MovieStatus.ended => 'Đã kết thúc',
        MovieStatus.inactive => 'Ngừng chiếu',
        MovieStatus.unknown => null,
      };
      final genres = movie.genreTags.isNotEmpty
          ? movie.genreTags
          : movie.genre.isNotEmpty && movie.genre != 'Đang cập nhật'
          ? [movie.genre]
          : const <String>[];
      return Stack(
        children: [
          if (background.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: backdropHeight,
              child: ExcludeSemantics(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(
                      asset: background,
                      borderRadius: BorderRadius.zero,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.surfaceOverlay,
                            AppColors.background,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: posterWidth,
                      child: AppImage(
                        key: const ValueKey('movie-detail-poster'),
                        asset: movie.posterAsset,
                        aspectRatio: AppSizes.posterAspectRatio,
                        borderRadius: AppRadii.control,
                        semanticLabel: 'Poster ${movie.title}',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              AgeBadge(rating: movie.ageRating),
                              if (status != null) AppChip(label: status),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(movie.duration, style: AppTextStyles.emphasis),
                          if (movie.releaseDate != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Khởi chiếu ${_date(movie.releaseDate!)}',
                              style: AppTextStyles.body,
                            ),
                          ],
                          if (rating != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              '★ ${rating.toStringAsFixed(1)}/10',
                              key: const ValueKey('movie-detail-rating'),
                              style: AppTextStyles.emphasis.copyWith(
                                color: AppColors.gold,
                              ),
                            ),
                            if (hasSummaryRating)
                              Text(
                                '${summary.totalReviews} lượt đánh giá',
                                style: AppTextStyles.caption,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Semantics(
                  header: true,
                  child: Text(movie.title, style: AppTextStyles.displayTitle),
                ),
                if (genres.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xxs,
                    children: [
                      for (final genre in genres)
                        AppChip(
                          label: genre,
                          maxLabelWidth:
                              constraints.maxWidth -
                              AppSpacing.md * 2 -
                              AppSpacing.xxl * 2,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    },
  );
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
