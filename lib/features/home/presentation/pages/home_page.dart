import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../booking/presentation/widgets/resume_booking_banner.dart';
import '../../../movie/presentation/models/movie.dart';
import '../../../movie/data/models/catalog_enums.dart';
import '../../../movie/presentation/widgets/trailer_preview_dialog.dart';
import '../providers/home_preview_provider.dart';
import '../providers/poster_ambient_color.dart';
import '../widgets/movie_coverflow.dart';
import '../widgets/promotional_banner_carousel.dart';
import '../widgets/popbot_banner.dart';
import '../widgets/quick_actions.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  MovieStatus _category = MovieStatus.nowShowing;

  bool _previewOnly() {
    if (!ref.read(homeUiPreviewProvider)) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dữ liệu mẫu chỉ dùng để xem giao diện Trang chủ.'),
      ),
    );
    return true;
  }

  void _openMovie(Movie movie) {
    if (_previewOnly()) return;
    context.pushNamed('movieDetail', pathParameters: {'id': '${movie.id}'});
  }

  void _bookMovie(Movie movie) {
    if (_previewOnly()) return;
    context.go(AppRoutes.showtimesForMovie(movie.id));
  }

  @override
  Widget build(BuildContext context) {
    final movies = ref.watch(homeCategoryMoviesProvider(_category));
    final preview = ref.watch(homeUiPreviewProvider);
    return AppShell(
      currentIndex: 0,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PromotionalBannerCarousel(),
            if (preview)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'Trang chủ · Dữ liệu mẫu',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ),
            const ResumeBookingBanner(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 8,
              ),
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
                            selected: _category == status,
                            child: TextButton(
                              key: ValueKey(
                                'home-category-${status.wireValue}',
                              ),
                              onPressed: () =>
                                  setState(() => _category = status),
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: AppTextStyles.cardTitle.copyWith(
                                  color: _category == status
                                      ? AppColors.text
                                      : AppColors.textMuted,
                                ),
                                child: Text(
                                  status == MovieStatus.nowShowing
                                      ? 'Đang chiếu'
                                      : 'Sắp chiếu',
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
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        alignment: _category == MovieStatus.nowShowing
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: FractionallySizedBox(
                          widthFactor: 0.5,
                          child: Container(height: 2, color: AppColors.gold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            movies.when(
              loading: () => const SizedBox(
                height: 320,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, _) => SizedBox(
                height: 280,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      color: AppColors.textMuted,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Không thể tải danh sách phim.',
                      style: AppTextStyles.caption,
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          ref.invalidate(homeCategoryMoviesProvider(_category)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
              data: (items) => items.isEmpty
                  ? SizedBox(
                      height: 280,
                      child: Center(
                        child: Text(
                          _category == MovieStatus.nowShowing
                              ? 'Chưa có phim đang chiếu'
                              : 'Chưa có phim sắp chiếu',
                          style: AppTextStyles.caption,
                        ),
                      ),
                    )
                  : MovieCoverflow(
                      key: ValueKey('showcase-${_category.wireValue}'),
                      movies: items,
                      colorLoader: ref.watch(posterAmbientLoaderProvider),
                      onOpen: _openMovie,
                      onBook: _bookMovie,
                      onTrailer: (movie) => showDialog<void>(
                        context: context,
                        builder: (_) => TrailerPreviewDialog(movie: movie),
                      ),
                    ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Divider(height: 28),
            ),
            const QuickActions(),
            const SizedBox(height: AppSpacing.xl),
            const PopBotBanner(onOpen: null),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
