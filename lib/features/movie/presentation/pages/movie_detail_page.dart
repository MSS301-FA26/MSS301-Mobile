import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../models/movie.dart';
import '../providers/movies_provider.dart';
import '../providers/movie_engagement_provider.dart';
import '../widgets/movie_detail_content.dart';
import '../widgets/movie_detail_engagement.dart';
import '../widgets/movie_detail_header.dart';
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
                  fullWidth: true,
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
                  MovieDetailHeader(
                    movie: movie,
                    reviewSummary: reviewSummary.asData?.value,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  MovieDetailContent(movie: movie),
                  if (movie.trailerUrl?.trim().isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.xl,
                      ),
                      child: AppButton(
                        key: const ValueKey('movie-detail-trailer'),
                        label: 'Xem trailer',
                        icon: Icons.play_circle_outline,
                        variant: AppButtonVariant.secondary,
                        fullWidth: true,
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (context) =>
                              TrailerPreviewDialog(movie: movie),
                        ),
                      ),
                    ),
                  MovieDetailReviews(summary: reviewSummary, reviews: reviews),
                  MovieDetailRecommendations(items: recommendations),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }
}
