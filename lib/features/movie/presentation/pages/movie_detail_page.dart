import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../providers/movies_provider.dart';
import '../providers/movie_engagement_provider.dart';
import '../widgets/movie_detail_sections.dart';
import '../widgets/trailer_preview_dialog.dart';

class MovieDetailPage extends ConsumerStatefulWidget {
  const MovieDetailPage({
    super.key,
    required this.movieId,
    this.showReviews = false,
  });
  final int movieId;
  final bool showReviews;
  @override
  ConsumerState<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends ConsumerState<MovieDetailPage> {
  final _reviewsAnchor = GlobalKey();
  final _scroll = ScrollController();
  bool _scrolledToReviews = false;
  int get movieId => widget.movieId;

  @override
  void didUpdateWidget(covariant MovieDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movieId != movieId) {
      _scrolledToReviews = false;
      if (_scroll.hasClients) _scroll.jumpTo(0);
    } else if (!oldWidget.showReviews && widget.showReviews) {
      _scrolledToReviews = false;
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _back() => context.canPop() ? context.pop() : context.go(AppRoutes.home);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(movieProvider(movieId));
    final movie = state.asData?.value;
    final summary = ref.watch(movieReviewSummaryProvider(movieId));
    final reviews = ref.watch(movieReviewsProvider(movieId));
    final related = ref.watch(movieRecommendationsProvider(movieId));
    if (movie != null && widget.showReviews && !_scrolledToReviews) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final anchor = _reviewsAnchor.currentContext;
        if (!mounted || anchor == null || _scrolledToReviews) return;
        _scrolledToReviews = true;
        Scrollable.ensureVisible(
          anchor,
          duration: const Duration(milliseconds: 250),
        );
      });
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chi tiết phim', style: AppTextStyles.cardTitle),
        leading: IconButton(
          tooltip: 'Quay lại',
          onPressed: _back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      bottomNavigationBar: movie == null
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: AppButton(
                  key: ValueKey('movie-detail-book-${movie.id}'),
                  label: movie.isNowShowing
                      ? 'Xem lịch chiếu & đặt vé'
                      : 'Chưa mở bán',
                  icon: Icons.confirmation_number_outlined,
                  onPressed: movie.isNowShowing
                      ? () =>
                            context.push(AppRoutes.showtimesForMovie(movie.id))
                      : null,
                ),
              ),
            ),
      body: state.isLoading
          ? const RepositoryStatePane.loading(
              layout: RepositorySkeleton.poster,
              title: 'Đang tải thông tin phim…',
            )
          : state.hasError
          ? RepositoryStatePane.error(
              onRetry: () => ref.invalidate(movieProvider(movieId)),
            )
          : movie == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.movie_outlined,
                      color: AppColors.gold,
                      size: 44,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Không tìm thấy phim.',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Phim có thể đã ngừng công khai.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                    TextButton(onPressed: _back, child: const Text('Quay lại')),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              key: PageStorageKey('movie-detail-scroll-$movieId'),
              controller: _scroll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MovieDetailHero(
                    movie: movie,
                    onTrailer: movie.trailerUrl?.trim().isNotEmpty == true
                        ? () => showDialog<void>(
                            context: context,
                            builder: (_) => TrailerPreviewDialog(movie: movie),
                          )
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MovieDetailIntroduction(movie: movie),
                        const SizedBox(height: 24),
                        MovieSynopsis(
                          key: ValueKey('synopsis-$movieId'),
                          text: (movie.description?.trim().isNotEmpty == true
                              ? movie.description!
                              : movie.tagline),
                        ),
                        const SizedBox(height: 24),
                        MovieCredits(movie: movie),
                        const SizedBox(height: 24),
                        KeyedSubtree(
                          key: _reviewsAnchor,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Đánh giá từ khán giả',
                                style: AppTextStyles.sectionTitle,
                              ),
                              const SizedBox(height: 12),
                              summary.when(
                                loading: () => const MovieSectionNotice(
                                  label: 'Đang tải điểm đánh giá…',
                                ),
                                error: (_, _) => MovieSectionNotice(
                                  label: 'Chưa tải được điểm đánh giá.',
                                  onRetry: () => ref.invalidate(
                                    movieReviewSummaryProvider(movieId),
                                  ),
                                  retryKey: const ValueKey(
                                    'movie-summary-retry',
                                  ),
                                ),
                                data: (value) => value.totalReviews <= 0
                                    ? const MovieSectionNotice(
                                        label: 'Chưa có đánh giá. Điểm sẽ hiển thị khi có đánh giá từ khán giả.',
                                      )
                                    : Wrap(
                                        spacing: 12,
                                        runSpacing: 8,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            '★ ${value.averageRating.toStringAsFixed(1)}/10',
                                            style: AppTextStyles.sectionTitle
                                                .copyWith(
                                                  color: AppColors.gold,
                                                ),
                                          ),
                                          Text(
                                            '${value.totalReviews} lượt đánh giá',
                                            style: AppTextStyles.body,
                                          ),
                                        ],
                                      ),
                              ),
                              reviews.when(
                                loading: () => const MovieSectionNotice(
                                  label: 'Đang tải nhận xét…',
                                ),
                                error: (_, _) => MovieSectionNotice(
                                  label: 'Chưa tải được nhận xét.',
                                  onRetry: () => ref.invalidate(
                                    movieReviewsProvider(movieId),
                                  ),
                                  retryKey: const ValueKey(
                                    'movie-reviews-retry',
                                  ),
                                ),
                                data: (items) => Column(
                                  children: [
                                    for (final review in items.take(5))
                                      MovieReviewCard(review: review),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        related.when(
                          loading: () => const MovieSectionNotice(
                            label: 'Đang tìm phim liên quan…',
                            skeleton: true,
                          ),
                          error: (_, _) => MovieSectionNotice(
                            label: 'Chưa tải được phim liên quan. Bạn vẫn có thể xem lịch chiếu của phim này.',
                            onRetry: () => ref.invalidate(
                              movieRecommendationsProvider(movieId),
                            ),
                            retryKey: const ValueKey('movie-related-retry'),
                          ),
                          data: (items) => items.isEmpty
                              ? const SizedBox.shrink()
                              : RelatedMovies(items: items),
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
