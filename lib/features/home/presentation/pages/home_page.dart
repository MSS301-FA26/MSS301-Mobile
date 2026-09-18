import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../movie/presentation/models/movie.dart';
import '../../../movie/presentation/providers/mock_movies_provider.dart';
import '../../../movie/presentation/widgets/trailer_preview_dialog.dart';
import '../widgets/coming_soon_card.dart';
import '../widgets/genre_selector.dart';
import '../widgets/hero_card.dart';
import '../widgets/now_showing_card.dart';
import '../widgets/popbot_banner.dart';
import '../widgets/quick_actions.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final PageController _heroController = PageController();
  int _activeHero = 0;
  String _genre = 'Tất cả';
  final Set<String> _reminders = {};

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  void _openMovie(Movie movie) =>
      context.pushNamed('movieDetail', pathParameters: {'id': movie.id});

  void _unavailable(String feature) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature sẽ có trong giai đoạn tiếp theo.'),
        backgroundColor: AppColors.surfaceRaised,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _matchesGenre(Movie movie) {
    return _genre == 'Tất cả' || movie.genreTags.contains(_genre);
  }

  @override
  Widget build(BuildContext context) {
    final movies = ref.watch(mockMoviesProvider);
    final nowShowing = movies
        .where((movie) => movie.isNowShowing && _matchesGenre(movie))
        .toList();
    final comingSoon = movies.where((movie) => movie.isComingSoon).toList();
    final heroes = [
      movies.firstWhere((movie) => movie.id == 'avengers-endgame'),
      movies.firstWhere((movie) => movie.id == 'inception'),
      movies.firstWhere((movie) => movie.id == 'spider-verse'),
    ];

    return AppShell(
      onUnavailable: _unavailable,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: AppSpacing.heroHeight,
              child: PageView.builder(
                controller: _heroController,
                itemCount: heroes.length,
                onPageChanged: (index) => setState(() => _activeHero = index),
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: HeroCard(
                    movie: heroes[index],
                    activeIndex: _activeHero,
                    count: heroes.length,
                    onOpen: () => _openMovie(heroes[index]),
                    onTrailer: () => showDialog<void>(
                      context: context,
                      builder: (context) =>
                          TrailerPreviewDialog(movie: heroes[index]),
                    ),
                    onDot: (page) => _heroController.animateToPage(
                      page,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            QuickActions(onUnavailable: _unavailable),
            const SizedBox(height: AppSpacing.xl),
            AppSectionHeader(
              title: 'Phim đang chiếu',
              action: 'Xem tất cả',
              onAction: () => _unavailable('Khám phá'),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 338,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: nowShowing.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) => NowShowingCard(
                  movie: nowShowing[index],
                  onOpen: () => _openMovie(nowShowing[index]),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PopBotBanner(onOpen: () => _unavailable('PopBot AI')),
            const SizedBox(height: AppSpacing.xl),
            const AppSectionHeader(
              title: 'Thể loại thịnh hành',
              accent: AppColors.lavender,
            ),
            const SizedBox(height: AppSpacing.sm),
            GenreSelector(
              selectedGenre: _genre,
              onSelected: (genre) => setState(() => _genre = genre),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSectionHeader(
              title: 'Phim sắp chiếu VIP',
              action: 'Xem lịch',
              onAction: () => _unavailable('Lịch chiếu'),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 30, right: 16, bottom: 12),
              child: Text(
                'Lưu trước thời khắc khởi chiếu và đặt chỗ tiên phong',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
            for (final movie in comingSoon)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: ComingSoonCard(
                  movie: movie,
                  reminded: _reminders.contains(movie.id),
                  onOpen: () => _openMovie(movie),
                  onReminder: () => setState(() {
                    if (!_reminders.add(movie.id)) _reminders.remove(movie.id);
                  }),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
