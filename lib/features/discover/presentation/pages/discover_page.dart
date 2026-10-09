import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../../movie/data/models/catalog_enums.dart';
import '../../../movie/presentation/models/movie.dart';
import '../../../movie/presentation/providers/movies_provider.dart';
import '../../../movie/data/repositories/catalog_providers.dart';
import '../providers/discover_provider.dart';
import '../widgets/discover_movie_card.dart';
import '../widgets/discover_filter_summary.dart';
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

  MovieStatus get _status => _tab == DiscoverMovieTab.now
      ? MovieStatus.nowShowing
      : MovieStatus.upcoming;
  DiscoverQuery get _request => DiscoverQuery(
    keyword: _query,
    status: _status,
    genreId: _genreId,
    page: _page,
  );

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _resetResults() => setState(() {
    _page = 0;
    _loaded.clear();
  });
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _query = value.trim();
        _page = 0;
        _loaded.clear();
      });
    });
  }

  void _clearFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _query = '';
      _genreId = null;
      _tab = DiscoverMovieTab.now;
      _page = 0;
      _loaded.clear();
    });
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final next = await ref
          .read(catalogRepositoryProvider)
          .getMoviePage(
            keyword: _query,
            status: _status,
            genreId: _genreId,
            page: _page + 1,
          );
      if (!mounted) return;
      setState(() {
        _page = next.page;
        _loaded.addAll(next.items.map(mapMovieToPresentation));
        _hasMore = !next.last;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoverPageProvider(_request));
    return AppShell(
      currentIndex: 1,
      body: state.when(
        loading: () => const RepositoryStatePane.loading(),
        error: (error, _) => RepositoryStatePane.error(
          onRetry: () => ref.invalidate(discoverPageProvider(_request)),
        ),
        data: (page) {
          if (_loaded.isEmpty ||
              (_page == 0 && _loaded.length != page.items.length)) {
            _loaded
              ..clear()
              ..addAll(page.items.map(mapMovieToPresentation));
            _hasMore = !page.last;
          }
          final genres = ref.watch(discoverGenresProvider);
          final selectedGenreName = genres.asData?.value
              .where((genre) => genre.id == _genreId)
              .map((genre) => genre.name)
              .join();
          final canClear =
              _query.isNotEmpty ||
              _genreId != null ||
              _tab == DiscoverMovieTab.soon;
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
                    const Text(
                      'Khám phá phim',
                      style: AppTextStyles.screenTitle,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Tìm bộ phim cho lần đến rạp tiếp theo.',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DiscoverSearchBar(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onClear: _clearFilters,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DiscoverSegmentedControl(
                      selected: _tab,
                      onSelected: (tab) {
                        setState(() => _tab = tab);
                        _resetResults();
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    genres.when(
                      data: (items) => LayoutBuilder(
                        builder: (context, filterConstraints) =>
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  AppChip(
                                    key: const ValueKey('discover-genre-all'),
                                    label: 'Tất cả thể loại',
                                    selected: _genreId == null,
                                    onPressed: () {
                                      setState(() => _genreId = null);
                                      _resetResults();
                                    },
                                  ),
                                  for (final genre in items)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: AppSpacing.xs,
                                      ),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: filterConstraints.maxWidth,
                                        ),
                                        child: AppChip(
                                          key: ValueKey(
                                            'discover-genre-${genre.id}',
                                          ),
                                          label: genre.name,
                                          maxLabelWidth:
                                              filterConstraints.maxWidth -
                                              AppSpacing.xxl * 2,
                                          selected: _genreId == genre.id,
                                          onPressed: () {
                                            setState(() => _genreId = genre.id);
                                            _resetResults();
                                          },
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    if (canClear) ...[
                      const SizedBox(height: AppSpacing.sm),
                      DiscoverFilterSummary(
                        keyword: _query,
                        statusLabel: _tab == DiscoverMovieTab.now
                            ? 'Đang chiếu'
                            : 'Sắp chiếu',
                        genreLabel: _genreId == null
                            ? null
                            : selectedGenreName == null ||
                                  selectedGenreName.isEmpty
                            ? 'Thể loại #$_genreId'
                            : selectedGenreName,
                        onClear: canClear ? _clearFilters : null,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Kết quả',
                          style: AppTextStyles.sectionTitle,
                        ),
                        Text(
                          '${page.totalItems} phim',
                          key: const ValueKey('discover-result-count'),
                          style: AppTextStyles.emphasis,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Đã hiển thị ${_loaded.length} / ${page.totalItems}',
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
                    ? const SliverToBoxAdapter(
                        child: RepositoryStatePane.empty(
                          title: 'Không tìm thấy phim',
                          message: 'Hãy thử từ khóa hoặc bộ lọc khác.',
                          icon: Icons.search_off_rounded,
                        ),
                      )
                    : SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final columns =
                              (constraints.crossAxisExtent /
                                      (AppSpacing.movieCardWidth +
                                          AppSpacing.sm))
                                  .floor()
                                  .clamp(2, 4);
                          final cardWidth =
                              (constraints.crossAxisExtent -
                                  AppSpacing.sm * (columns - 1)) /
                              columns;
                          final textScaler = MediaQuery.textScalerOf(context);
                          final detailsHeight =
                              AppSizes.buttonHeight +
                              AppSpacing.sm * 4 +
                              AppSpacing.xxs +
                              textScaler.scale(
                                    AppTextStyles.cardTitle.fontSize!,
                                  ) *
                                  AppTextStyles.cardTitle.height! *
                                  2 +
                              textScaler.scale(
                                    AppTextStyles.caption.fontSize!,
                                  ) *
                                  AppTextStyles.caption.height! *
                                  2;
                          return SliverGrid.builder(
                            itemCount: _loaded.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: AppSpacing.sm,
                                  mainAxisSpacing: AppSpacing.sm,
                                  mainAxisExtent:
                                      cardWidth / AppSizes.posterAspectRatio +
                                      detailsHeight,
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
                          );
                        },
                      ),
              ),
              if (_hasMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: AppButton(
                      key: const ValueKey('discover-load-more'),
                      fullWidth: true,
                      loading: _loadingMore,
                      variant: AppButtonVariant.secondary,
                      onPressed: _loadingMore ? null : _loadMore,
                      label: _loadingMore ? 'Đang tải thêm…' : 'Tải thêm phim',
                    ),
                  ),
                ),
              if (!_hasMore && _loaded.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.xl),
                    child: Text(
                      'Đã hiển thị hết kết quả.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption,
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
