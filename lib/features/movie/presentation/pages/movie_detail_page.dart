import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/age_badge.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../models/movie.dart';
import '../../data/models/recommendation_dto.dart';
import '../../data/models/review_dto.dart';
import '../providers/movies_provider.dart';
import '../providers/movie_engagement_provider.dart';
import '../widgets/trailer_preview_dialog.dart';

class MovieDetailPage extends ConsumerWidget {
  const MovieDetailPage({super.key, required this.movieId});

  final int movieId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movieState = ref.watch(movieProvider(movieId));
    final reviewSummary = ref.watch(movieReviewSummaryProvider(movieId));
    final reviews = ref.watch(movieReviewsProvider(movieId));
    final recommendations = ref.watch(movieRecommendationsProvider(movieId));
    if (movieState.isLoading) {
      return const Scaffold(body: RepositoryStatePane.loading());
    }
    if (movieState.hasError) {
      return Scaffold(
        body: RepositoryStatePane.error(
          onRetry: () => ref.invalidate(movieProvider(movieId)),
        ),
      );
    }
    final Movie? movie = movieState.requireValue;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          movie?.title ?? 'Chi tiết phim',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          tooltip: 'Quay lại',
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      bottomNavigationBar: movie == null
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: AppButton(
                  key: ValueKey('movie-detail-book-${movie.id}'),
                  label: movie.isNowShowing ? 'Đặt vé' : 'Chưa mở bán',
                  icon: Icons.confirmation_number_outlined,
                  onPressed: movie.isNowShowing
                      ? () => context.go(AppRoutes.showtimesForMovie(movie.id))
                      : null,
                ),
              ),
            ),
      body: movie == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Không tìm thấy phim.'),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Về trang chủ'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 270,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AppImage(asset: movie.bannerAsset ?? movie.posterAsset),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppColors.background.withValues(alpha: 0.4),
                                AppColors.background,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 105,
                              height: 158,
                              child: ClipRRect(
                                borderRadius: AppRadii.control,
                                child: AppImage(asset: movie.posterAsset),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AgeBadge(rating: movie.ageRating),
                                  const SizedBox(height: 8),
                                  Text(
                                    movie.title,
                                    style: AppTextStyles.screenTitle,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: AppColors.gold,
                                        size: 18,
                                      ),
                                      Text(
                                        ' ${movie.rating}/10',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            AppChip(label: movie.genre),
                            AppChip(label: movie.duration),
                            if (movie.format.isNotEmpty)
                              AppChip(label: movie.format),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Nội dung phim',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          movie.description ?? movie.tagline,
                          style: AppTextStyles.body,
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          label: 'Xem trailer',
                          icon: Icons.play_circle_outline,
                          variant: AppButtonVariant.secondary,
                          onPressed: movie.trailerUrl == null
                              ? null
                              : () => showDialog<void>(
                                  context: context,
                                  builder: (context) =>
                                      TrailerPreviewDialog(movie: movie),
                                ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceRaised,
                            border: Border.all(color: AppColors.border),
                            borderRadius: AppRadii.card,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chi tiết phim',
                                style: AppTextStyles.sectionTitle.copyWith(
                                  color: AppColors.gold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _DetailRow(
                                label: 'Đạo diễn',
                                value: movie.director ?? 'Đang cập nhật',
                              ),
                              _DetailRow(
                                label: 'Diễn viên',
                                value: movie.cast ?? 'Đang cập nhật',
                              ),
                              _DetailRow(
                                label: 'Ngôn ngữ',
                                value: movie.language ?? 'Đang cập nhật',
                              ),
                              _DetailRow(
                                label: 'Phụ đề',
                                value:
                                    movie.subtitleLanguage ?? 'Đang cập nhật',
                                isLast: true,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Dữ liệu phim được tải từ CatalogRepository.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        reviewSummary.when(
                          loading: () => const _SectionLoading(
                            label: 'Đang tải đánh giá...',
                          ),
                          error: (_, _) => const SizedBox.shrink(),
                          data: (summary) => _ReviewSection(
                            summary: summary,
                            reviews: reviews.maybeWhen(
                              data: (items) => items,
                              orElse: () => const [],
                            ),
                          ),
                        ),
                        recommendations.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                          data: (items) => items.isEmpty
                              ? const SizedBox.shrink()
                              : _RecommendationSection(items: items),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(label, style: AppTextStyles.caption),
  );
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({required this.summary, required this.reviews});
  final ReviewSummaryDto summary;
  final List<ReviewDto> reviews;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      border: Border.all(color: AppColors.border),
      borderRadius: AppRadii.card,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Đánh giá từ khán giả',
          style: AppTextStyles.sectionTitle.copyWith(color: AppColors.gold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.star_rounded, color: AppColors.gold),
            const SizedBox(width: 6),
            Text(
              '${summary.averageRating.toStringAsFixed(1)}/10',
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(width: 8),
            Text(
              '${summary.totalReviews} lượt đánh giá',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        if (reviews.isNotEmpty) ...[
          const Divider(height: 24),
          ...reviews
              .take(3)
              .map(
                (review) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${review.userName} · ${review.rating}/10',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(review.content, style: AppTextStyles.body),
                    ],
                  ),
                ),
              ),
        ],
      ],
    ),
  );
}

class _RecommendationSection extends StatelessWidget {
  const _RecommendationSection({required this.items});
  final List<RecommendationDto> items;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 24),
      Text(
        'Có thể bạn cũng thích',
        style: AppTextStyles.sectionTitle.copyWith(color: AppColors.gold),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 190,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return SizedBox(
              width: 132,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: AppRadii.control,
                      child: AppImage(
                        asset: item.posterUrl ?? '',
                        width: 132,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (item.averageRating != null)
                    Text(
                      '★ ${item.averageRating!.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 82, child: Text(label, style: AppTextStyles.caption)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
}
