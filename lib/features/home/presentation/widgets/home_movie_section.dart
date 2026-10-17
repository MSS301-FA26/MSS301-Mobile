import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../../movie/data/models/catalog_enums.dart';
import '../../../movie/presentation/models/movie.dart';
import '../../../movie/presentation/widgets/trailer_preview_dialog.dart';
import '../providers/home_preview_provider.dart';
import '../providers/poster_ambient_color.dart';
import 'movie_coverflow.dart';

class HomeMovieTabController extends Notifier<MovieStatus> {
  @override
  MovieStatus build() => MovieStatus.nowShowing;
  void select(MovieStatus status) => state = status;
}

final homeMovieTabProvider =
    NotifierProvider<HomeMovieTabController, MovieStatus>(
      HomeMovieTabController.new,
    );

class HomeMovieSelectionController extends Notifier<Map<MovieStatus, int>> {
  @override
  Map<MovieStatus, int> build() => const {};
  void select(MovieStatus category, int movieId) =>
      state = {...state, category: movieId};
}

final homeMovieSelectionProvider =
    NotifierProvider<HomeMovieSelectionController, Map<MovieStatus, int>>(
      HomeMovieSelectionController.new,
    );

class HomeMovieSection extends ConsumerWidget {
  const HomeMovieSection({
    super.key,
    required this.onOpen,
    required this.onBook,
  });
  final ValueChanged<Movie> onOpen, onBook;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(homeMovieTabProvider);
    final selected = ref.watch(homeMovieSelectionProvider)[category];
    final movies = ref.watch(homeCategoryMoviesProvider(category));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  for (final status in [
                    MovieStatus.nowShowing,
                    MovieStatus.upcoming,
                  ])
                    Expanded(
                      child: Semantics(
                        selected: category == status,
                        child: TextButton(
                          key: ValueKey('home-category-${status.wireValue}'),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                          onPressed: () => ref
                              .read(homeMovieTabProvider.notifier)
                              .select(status),
                          child: Text(
                            status == MovieStatus.nowShowing
                                ? 'Đang chiếu'
                                : 'Sắp chiếu',
                            style: AppTextStyles.cardTitle.copyWith(
                              color: category == status
                                  ? AppColors.text
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Stack(
                children: [
                  Container(height: 1, color: AppColors.border),
                  AnimatedAlign(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    alignment: category == MovieStatus.nowShowing
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: .5,
                      child: Container(height: 2, color: AppColors.gold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (movies.hasError && movies.hasValue)
          RepositoryStatePane.error(
            compact: true,
            message:
                'Chưa cập nhật được phim. Danh sách đã tải vẫn được giữ lại.',
            onRetry: () => ref.invalidate(homeCategoryMoviesProvider(category)),
          ),
        movies.when(
          skipLoadingOnRefresh: true,
          skipError: movies.hasValue,
          loading: () => const SizedBox(
            height: 420,
            child: RepositoryStatePane.loading(
              title: 'Đang tải phim…',
              layout: RepositorySkeleton.poster,
            ),
          ),
          error: (_, _) => RepositoryStatePane.error(
            title: 'Chưa tải được phim',
            compact: true,
            onRetry: () => ref.invalidate(homeCategoryMoviesProvider(category)),
          ),
          data: (items) => items.isEmpty
              ? RepositoryStatePane.empty(
                  title: category == MovieStatus.nowShowing
                      ? 'Chưa có phim đang chiếu'
                      : 'Chưa có phim sắp chiếu',
                  message: 'Bạn có thể khám phá các phim khác.',
                  compact: true,
                  onAction: () => context.go(AppRoutes.discover),
                )
              : MovieCoverflow(
                  key: ValueKey('home-coverflow-${category.wireValue}'),
                  keyPrefix: 'home-3d',
                  movies: items,
                  initialMovieId: selected,
                  onSelected: (movie) => ref
                      .read(homeMovieSelectionProvider.notifier)
                      .select(category, movie.id),
                  colorLoader: ref.watch(posterAmbientLoaderProvider),
                  onOpen: onOpen,
                  onBook: onBook,
                  onTrailer: (movie) => showDialog<void>(
                    context: context,
                    builder: (_) => TrailerPreviewDialog(movie: movie),
                  ),
                ),
        ),
      ],
    );
  }
}
