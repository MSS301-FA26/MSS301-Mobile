import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../../movie/data/models/catalog_enums.dart';
import '../../../movie/data/models/movie_dto.dart';
import '../../../movie/presentation/models/movie.dart';
import '../../../movie/presentation/providers/movies_provider.dart';
import '../../../movie/data/repositories/catalog_providers.dart';
import '../providers/discover_provider.dart';
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
  Timer? _searchDebounce;
  String _query = '';
  int? _genreId;
  DiscoverMovieTab _tab = DiscoverMovieTab.now;
  int _page = 0;
  final _loaded = <Movie>[];
  var _hasMore = false;
  var _loadingMore = false;
  String? _loadMoreError;
  int _generation = 0;
  MoviePageDto? _firstSnapshot;

  MovieStatus get _status => _tab == DiscoverMovieTab.now
      ? MovieStatus.nowShowing
      : MovieStatus.upcoming;
  DiscoverQuery get _request => DiscoverQuery(
    keyword: _query,
    status: _status,
    genreId: _genreId,
    page: 0,
  );

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _resetResults() => setState(() {
    _generation++;
    _page = 0;
    _loaded.clear();
    _firstSnapshot = null;
    _loadingMore = false;
    _loadMoreError = null;
    _hasMore = false;
  });
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _query = value.trim();
      });
      _resetResults();
    });
  }

  void _clearFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _query = '';
      _genreId = null;
      _tab = DiscoverMovieTab.now;
    });
    _resetResults();
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;
    final generation = _generation;
    setState(() {
      _loadingMore = true;
      _loadMoreError = null;
    });
    try {
      final next = await ref
          .read(catalogRepositoryProvider)
          .getMoviePage(
            keyword: _query,
            status: _status,
            genreId: _genreId,
            page: _page + 1,
          );
      if (!mounted || generation != _generation) return;
      setState(() {
        _page = next.page;
        final ids = _loaded.map((movie) => movie.id).toSet();
        _loaded.addAll(
          next.items
              .where((movie) => ids.add(movie.id))
              .map(mapMovieToPresentation),
        );
        _hasMore = !next.last;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _loadingMore = false;
          _loadMoreError =
              'Chưa tải được thêm phim. Danh sách hiện tại vẫn được giữ lại.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoverPageProvider(_request));
    Widget pending(Widget content) => Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              DiscoverSearchBar(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onClear: _clearFilters,
              ),
              const SizedBox(height: AppSpacing.md),
              DiscoverSegmentedControl(
                selected: _tab,
                nowCount: null,
                soonCount: null,
                onSelected: (tab) {
                  setState(() => _tab = tab);
                  _resetResults();
                },
              ),
            ],
          ),
        ),
        Expanded(child: content),
      ],
    );
    return AppShell(
      currentIndex: 1,
      body: state.when(
        skipError: state.hasValue,
        loading: () => pending(
          const RepositoryStatePane.loading(
            layout: RepositorySkeleton.movies,
            title: 'Đang tìm phim…',
          ),
        ),
        error: (error, _) => pending(
          RepositoryStatePane.error(
            onRetry: () => ref.invalidate(discoverPageProvider(_request)),
            title: 'Chưa tải được danh sách phim',
          ),
        ),
        data: (page) {
          if (!identical(_firstSnapshot, page)) {
            _firstSnapshot = page;
            _page = 0;
            _loaded
              ..clear()
              ..addAll(page.items.map(mapMovieToPresentation));
            _hasMore = !page.last;
          }
          final genres = ref.watch(discoverGenresProvider);
          return CustomScrollView(
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
                    if (state.hasError)
                      RepositoryStatePane.error(
                        compact: true,
                        message: 'Chưa cập nhật được phim. Bạn vẫn có thể xem danh sách đã tải.',
                        onRetry: () =>
                            ref.invalidate(discoverPageProvider(_request)),
                      ),
                    DiscoverSearchBar(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onClear: _clearFilters,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DiscoverSegmentedControl(
                      selected: _tab,
                      nowCount: page.totalItems,
                      soonCount: page.totalItems,
                      onSelected: (tab) {
                        setState(() => _tab = tab);
                        _resetResults();
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    genres.when(
                      data: (items) => Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          ChoiceChip(
                            label: const Text('Tất cả thể loại'),
                            selected: _genreId == null,
                            onSelected: (_) {
                              setState(() => _genreId = null);
                              _resetResults();
                            },
                          ),
                          for (final genre in items)
                            ChoiceChip(
                              label: Text(genre.name),
                              selected: _genreId == genre.id,
                              onSelected: (_) {
                                setState(() => _genreId = genre.id);
                                _resetResults();
                              },
                            ),
                        ],
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => TextButton.icon(
                        onPressed: () => ref.invalidate(discoverGenresProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại thể loại'),
                      ),
                    ),
                    if (_query.isNotEmpty || _genreId != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Xóa bộ lọc'),
                        ),
                      ),
                    Text(
                      '${page.totalItems} kết quả',
                      style: AppTextStyles.caption,
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
                sliver: _loaded.isEmpty
                    ? SliverToBoxAdapter(
                        child: RepositoryStatePane.empty(
                          title: 'Không tìm thấy phim',
                          message: 'Hãy thử từ khóa hoặc bộ lọc khác.',
                          icon: Icons.search_off_rounded,
                          compact: true,
                          onAction: _clearFilters,
                          actionLabel: 'Xóa bộ lọc',
                        ),
                      )
                    : SliverGrid.builder(
                        itemCount: _loaded.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: AppSpacing.sm,
                              mainAxisSpacing: AppSpacing.sm,
                              childAspectRatio: 0.48,
                            ),
                        itemBuilder: (context, index) {
                          final movie = _loaded[index];
                          return DiscoverMovieCard(
                            movie: movie,
                            onOpen: () => context.pushNamed(
                              'movieDetail',
                              pathParameters: {'id': '${movie.id}'},
                            ),
                            onBook: () => context.go(
                              AppRoutes.showtimesForMovie(movie.id),
                            ),
                          );
                        },
                      ),
              ),
              if (_hasMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        if (_loadMoreError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _loadMoreError!,
                              style: AppTextStyles.body,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        OutlinedButton(
                          onPressed: _loadingMore ? null : _loadMore,
                          child: Text(
                            _loadingMore
                                ? 'Đang tải...'
                                : _loadMoreError != null
                                ? 'Thử lại tải thêm'
                                : 'Tải thêm',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
