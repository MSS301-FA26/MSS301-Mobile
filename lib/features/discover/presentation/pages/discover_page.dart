import 'dart:async';

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

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  final _searchController = TextEditingController();
  DiscoverMovieTab _tab = DiscoverMovieTab.now;
  String _query = '';
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  bool _matches(Movie movie) {
    final inTab = _tab == DiscoverMovieTab.now
        ? movie.isNowShowing
        : movie.isComingSoon;
    if (!inTab) return false;

    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;

    return movie.title.toLowerCase().contains(query) ||
        movie.genre.toLowerCase().contains(query) ||
        movie.tagline.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final moviesState = _query.isEmpty
        ? ref.watch(moviesProvider)
        : ref.watch(movieSearchProvider(_query));
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
          onRetry: () => _query.isEmpty
              ? ref.invalidate(moviesProvider)
              : ref.invalidate(movieSearchProvider(_query)),
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
                  onChanged: _onSearchChanged,
                  onClear: () => setState(() {
                    _searchDebounce?.cancel();
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
