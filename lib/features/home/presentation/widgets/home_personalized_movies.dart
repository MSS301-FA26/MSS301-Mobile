import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../../auth/application/auth_session.dart';
import '../../../movie/data/models/catalog_enums.dart';
import '../../../movie/presentation/models/movie.dart';
import '../../../movie/presentation/widgets/trailer_preview_dialog.dart';
import '../providers/home_preview_provider.dart';
import '../providers/home_recommendations_provider.dart';
import '../providers/poster_ambient_color.dart';
import 'home_section_heading.dart';
import 'movie_coverflow.dart';

enum _HomeMovieTab { ai, nowShowing }

class HomePersonalizedMovies extends ConsumerStatefulWidget {
  const HomePersonalizedMovies({
    super.key,
    required this.onOpen,
    required this.onBook,
  });

  final ValueChanged<Movie> onOpen;
  final ValueChanged<Movie> onBook;

  @override
  ConsumerState<HomePersonalizedMovies> createState() =>
      _HomePersonalizedMoviesState();
}

class _HomePersonalizedMoviesState
    extends ConsumerState<HomePersonalizedMovies> {
  _HomeMovieTab _tab = _HomeMovieTab.ai;
  final _selectedMovieIds = <_HomeMovieTab, int>{};

  @override
  Widget build(BuildContext context) {
    final ai = ref.watch(homeRecommendationsProvider);
    final showing = ref.watch(
      homeCategoryMoviesProvider(MovieStatus.nowShowing),
    );
    final signedIn = ref.watch(authSessionProvider).session != null;
    final colorLoader = ref.watch(posterAmbientLoaderProvider);
    final isAi = _tab == _HomeMovieTab.ai;

    void openTrailer(Movie movie) => showDialog<void>(
      context: context,
      builder: (_) => TrailerPreviewDialog(movie: movie),
    );

    MovieCoverflow coverflow(
      List<Movie> movies, {
      Map<int, String> reasons = const {},
    }) => MovieCoverflow(
      key: ValueKey(isAi ? 'home-ai-coverflow' : 'home-now-showing-coverflow'),
      keyPrefix: isAi ? 'home-ai' : 'home-now',
      movies: movies,
      initialMovieId: _selectedMovieIds[_tab],
      onSelected: (movie) => _selectedMovieIds[_tab] = movie.id,
      recommendationReasons: reasons,
      colorLoader: colorLoader,
      onOpen: widget.onOpen,
      onBook: widget.onBook,
      onTrailer: openTrailer,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionHeading(
          eyebrow: isAi
              ? signedIn
                    ? 'DÀNH RIÊNG CHO BẠN'
                    : 'XU HƯỚNG TẠI RẠP'
              : 'CHỌN VÉ NGAY',
          title: 'Khám phá phim',
          subtitle: isAi
              ? signedIn
                    ? 'Phim được AI chọn theo sở thích của bạn.'
                    : 'AI chọn phim theo xu hướng xem hiện tại.'
              : 'Tất cả phim đang chiếu tại rạp.',
          action: 'Xem tất cả',
          onAction: () => context.go(AppRoutes.discover),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  for (final tab in _HomeMovieTab.values)
                    Expanded(
                      child: Semantics(
                        selected: _tab == tab,
                        child: TextButton(
                          key: ValueKey(
                            tab == _HomeMovieTab.ai
                                ? 'home-tab-ai'
                                : 'home-tab-now-showing',
                          ),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                          onPressed: () => setState(() => _tab = tab),
                          child: Text(
                            tab == _HomeMovieTab.ai ? 'Gợi ý AI' : 'Đang chiếu',
                            style: AppTextStyles.cardTitle.copyWith(
                              color: _tab == tab
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
                    alignment: isAi
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
        if (isAi)
          ai.when(
            skipLoadingOnRefresh: true,
            skipError: ai.hasValue,
            loading: () => const SizedBox(
              height: 320,
              child: RepositoryStatePane.loading(
                title: 'Đang tìm phim phù hợp…',
                layout: RepositorySkeleton.poster,
              ),
            ),
            error: (error, _) => RepositoryStatePane.error(
              compact: true,
              title: 'Chưa tải được gợi ý AI',
              message: error is HomeRecommendationLoadException
                  ? error.userMessage
                  : userFacingErrorMessage(error),
              onRetry: () => ref.invalidate(homeRecommendationsProvider),
            ),
            data: (items) => items.isEmpty
                ? RepositoryStatePane.empty(
                    compact: true,
                    title: 'AI chưa có gợi ý phù hợp',
                    message: 'Hãy xem phim đang chiếu ở tab bên cạnh.',
                    icon: Icons.auto_awesome_outlined,
                  )
                : coverflow(
                    items.map((item) => item.movie).toList(growable: false),
                    reasons: {
                      for (final item in items) item.movie.id: item.reason,
                    },
                  ),
          )
        else
          showing.when(
            skipLoadingOnRefresh: true,
            skipError: showing.hasValue,
            loading: () => const SizedBox(
              height: 320,
              child: RepositoryStatePane.loading(
                title: 'Đang tải phim đang chiếu…',
                layout: RepositorySkeleton.poster,
              ),
            ),
            error: (error, _) => RepositoryStatePane.error(
              compact: true,
              title: 'Chưa tải được phim đang chiếu',
              message: userFacingErrorMessage(error),
              onRetry: () => ref.invalidate(
                homeCategoryMoviesProvider(MovieStatus.nowShowing),
              ),
            ),
            data: (items) => items.isEmpty
                ? const RepositoryStatePane.empty(
                    compact: true,
                    title: 'Chưa có phim đang chiếu',
                    message: 'Lịch chiếu sẽ được cập nhật sớm.',
                  )
                : coverflow(items),
          ),
      ],
    );
  }
}
