import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../../movie/presentation/models/movie.dart';
import '../../../movie/presentation/providers/movies_provider.dart';
import '../widgets/discover_movie_card.dart';
import '../widgets/discover_search_bar.dart';
import '../widgets/discover_segmented_control.dart';
import '../widgets/format_filter_chips.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  final _searchController = TextEditingController();
  DiscoverMovieTab _tab = DiscoverMovieTab.now;
  String _format = 'Tất cả định dạng';
  String _query = '';

  static const _filters = [
    'Tất cả định dạng',
    'IMAX Laser',
    'Dolby Atmos',
    '3D Digital',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(Movie movie) {
    final inTab = _tab == DiscoverMovieTab.now
        ? movie.isNowShowing
        : movie.isComingSoon;
    if (!inTab) return false;

    if (_format != 'Tất cả định dạng' &&
        !movie.format.toLowerCase().contains(_format.toLowerCase())) {
      return false;
    }

    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;

    return movie.title.toLowerCase().contains(query) ||
        movie.genre.toLowerCase().contains(query) ||
        movie.tagline.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final moviesState = ref.watch(moviesProvider);
    if (moviesState.isLoading) {
      return const AppShell(
        currentIndex: 1,
        body: RepositoryStatePane.loading(),
      );
    }
    if (moviesState.hasError) {
      return AppShell(
        currentIndex: 1,
        body: RepositoryStatePane.error(
          onRetry: () => ref.invalidate(moviesProvider),
        ),
      );
    }
    final movies = moviesState.requireValue;
    final filtered = movies.where(_matches).toList();
    final nowCount = movies.where((movie) => movie.isNowShowing).length;
    final soonCount = movies.where((movie) => movie.isComingSoon).length;

    return AppShell(
      currentIndex: 1,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            sliver: SliverList.list(
              children: [
                DiscoverSearchBar(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  onClear: () => setState(() {
                    _searchController.clear();
                    _query = '';
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                DiscoverSegmentedControl(
                  selected: _tab,
                  nowCount: nowCount,
                  soonCount: soonCount,
                  onSelected: (tab) => setState(() => _tab = tab),
                ),
                const SizedBox(height: AppSpacing.md),
                FormatFilterChips(
                  filters: _filters,
                  selected: _format,
                  onSelected: (format) => setState(() => _format = format),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            sliver: filtered.isEmpty
                ? const SliverToBoxAdapter(
                    child: RepositoryStatePane.empty(
                      title: 'Không tìm thấy phim',
                      message: 'Hãy thử từ khóa hoặc bộ lọc khác.',
                      icon: Icons.search_off_rounded,
                    ),
                  )
                : SliverGrid.builder(
                    itemCount: filtered.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.sm,
                          mainAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 0.48,
                        ),
                    itemBuilder: (context, index) {
                      final movie = filtered[index];
                      return DiscoverMovieCard(
                        movie: movie,
                        onOpen: () => context.pushNamed(
                          'movieDetail',
                          pathParameters: {'id': '${movie.id}'},
                        ),
                        onBook: () =>
                            context.go(AppRoutes.showtimesForMovie(movie.id)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
