import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/age_badge.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../models/movie.dart';
import '../providers/movies_provider.dart';

class MovieDetailPlaceholder extends ConsumerWidget {
  const MovieDetailPlaceholder({super.key, required this.movieId});

  final int movieId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movieState = ref.watch(movieProvider(movieId));
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
                  SizedBox(
                    height: 270,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AppImage(asset: movie.bannerAsset ?? movie.posterAsset),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppColors.background.withValues(alpha: 0.4),
                                AppColors.background,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 105,
                              height: 158,
                              child: ClipRRect(
                                borderRadius: AppRadii.control,
                                child: AppImage(asset: movie.posterAsset),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AgeBadge(rating: movie.ageRating),
                                  const SizedBox(height: 8),
                                  Text(
                                    movie.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: AppColors.gold,
                                        size: 18,
                                      ),
                                      Text(
                                        ' ${movie.rating}/10',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoPill(movie.genre),
                            _InfoPill(movie.duration),
                            _InfoPill(movie.format),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Nội dung phim',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          movie.tagline,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border.all(color: AppColors.border),
                            borderRadius: AppRadii.card,
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chi tiết phim',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gold,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Bản mock hiện hiển thị thông tin phim cơ bản để kiểm tra navigation và bố cục.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
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

class _InfoPill extends StatelessWidget {
  const _InfoPill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
    ),
  );
}
