import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../data/models/recommendation_dto.dart';
import '../../data/models/review_dto.dart';

class MovieDetailReviews extends StatelessWidget {
  const MovieDetailReviews({
    super.key,
    required this.summary,
    required this.reviews,
  });
  final AsyncValue<ReviewSummaryDto> summary;
  final AsyncValue<List<ReviewDto>> reviews;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const AppSectionHeader(title: 'Đánh giá từ khán giả'),
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        child: AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              summary.when(
                loading: () =>
                    const _SectionMessage('Đang tải tổng hợp đánh giá…'),
                error: (_, _) =>
                    const _SectionMessage('Chưa thể tải tổng hợp đánh giá.'),
                data: (value) => Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (value.totalReviews > 0 && value.averageRating > 0)
                      Text(
                        '★ ${value.averageRating.toStringAsFixed(1)}/10',
                        style: AppTextStyles.sectionTitle.copyWith(
                          color: AppColors.gold,
                        ),
                      ),
                    Text(
                      value.totalReviews == 0
                          ? 'Chưa có đánh giá'
                          : '${value.totalReviews} lượt đánh giá',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              reviews.when(
                loading: () => const _SectionMessage('Đang tải đánh giá…'),
                error: (_, _) => const _SectionMessage(
                  'Chưa thể tải các đánh giá. Bạn vẫn có thể xem phim và đặt vé.',
                ),
                data: (items) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final review in items.take(3))
                      _ReviewItem(review: review),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _ReviewItem extends StatelessWidget {
  const _ReviewItem({required this.review});
  final ReviewDto review;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: AppSpacing.sm),
        Text(review.userName, style: AppTextStyles.emphasis),
        const SizedBox(height: AppSpacing.xxs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xxs,
          children: [
            if (review.rating > 0)
              Text(
                '${review.rating}/10',
                style: AppTextStyles.meta.copyWith(color: AppColors.gold),
              ),
            if (review.createdAt != null)
              Text(_date(review.createdAt!), style: AppTextStyles.caption),
            if (review.verifiedBooking)
              const Text('Đã mua vé', style: AppTextStyles.caption),
          ],
        ),
        if (review.content.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(review.content, style: AppTextStyles.body),
        ],
      ],
    ),
  );
}

class MovieDetailRecommendations extends StatelessWidget {
  const MovieDetailRecommendations({super.key, required this.items});
  final AsyncValue<List<RecommendationDto>> items;

  @override
  Widget build(BuildContext context) => items.when(
    loading: () => const _RecommendationMessage('Đang tải phim gợi ý…'),
    error: (_, _) => const _RecommendationMessage('Chưa thể tải phim gợi ý.'),
    data: (values) {
      if (values.isEmpty) return const SizedBox.shrink();
      final titleStyle = AppTextStyles.cardTitle;
      final ratingStyle = AppTextStyles.meta;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: 'Có thể bạn cũng thích'),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < values.length; index++) ...[
                    if (index > 0) const SizedBox(width: AppSpacing.cardGap),
                    SizedBox(
                      key: ValueKey(
                        'movie-detail-recommendation-${values[index].movieId}',
                      ),
                      width: AppSpacing.movieCardWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppImage(
                            asset: values[index].posterUrl ?? '',
                            aspectRatio: AppSizes.posterAspectRatio,
                            semanticLabel: 'Poster ${values[index].title}',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            values[index].title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle,
                          ),
                          if ((values[index].averageRating ?? 0) > 0) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '★ ${values[index].averageRating!.toStringAsFixed(1)}/10',
                              style: ratingStyle.copyWith(
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _SectionMessage extends StatelessWidget {
  const _SectionMessage(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.caption);
}

class _RecommendationMessage extends StatelessWidget {
  const _RecommendationMessage(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const AppSectionHeader(title: 'Có thể bạn cũng thích'),
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          0,
        ),
        child: _SectionMessage(text),
      ),
    ],
  );
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
