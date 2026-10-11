import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../../auth/application/auth_session.dart';
import '../../../movie/presentation/models/movie.dart';
import '../../../movie/presentation/providers/movies_provider.dart';
import '../widgets/home_cinemas_section.dart';
import '../widgets/home_hero_carousel.dart';
import '../widgets/home_movie_carousel.dart';
import '../widgets/home_quick_booking.dart';
import '../widgets/home_section_heading.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  void _openMovie(BuildContext context, Movie movie) =>
      context.pushNamed('movieDetail', pathParameters: {'id': '${movie.id}'});

  void _bookMovie(BuildContext context, Movie movie) =>
      context.go(AppRoutes.showtimesForMovie(movie.id));

  void _openSeats(BuildContext context, WidgetRef ref, int showtimeId) {
    final route = AppRoutes.seatSelection(showtimeId);
    // Use the same existing session boundary as the Showtimes entry CTA.
    if (ref.read(authSessionProvider).isAuthenticated) {
      context.push(route);
    } else {
      context.go(AppRoutes.loginWithRedirect(route));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movies = ref.watch(moviesProvider);
    return AppShell(
      currentIndex: 0,
      compactHeader: true,
      body: SingleChildScrollView(
        key: const ValueKey('home-scroll'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (movies.isLoading)
              const RepositoryStatePane.loading()
            else if (movies.hasError)
              RepositoryStatePane.error(
                onRetry: () => ref.invalidate(moviesProvider),
              )
            else if (movies.requireValue.isEmpty)
              const RepositoryStatePane.empty(
                title: 'Chưa có phim',
                message: 'Danh sách phim sẽ được cập nhật sớm.',
              )
            else
              HomeHeroCarousel(
                movies: movies.requireValue.take(3).toList(growable: false),
                onOpen: (movie) => _openMovie(context, movie),
              ),
            HomeQuickBooking(
              movies: movies.hasError || movies.isLoading
                  ? const []
                  : movies.requireValue,
              onBook: (id) => _openSeats(context, ref, id),
            ),
            HomeSectionHeading(
              eyebrow: 'PHÒNG VÉ CINEPREMIER',
              title: 'PHIM ĐANG CHIẾU',
              subtitle:
                  'Những siêu phẩm điện ảnh đang khuấy đảo phòng vé tuần này',
              action: 'Xem tất cả',
              onAction: () => context.go(AppRoutes.discover),
            ),
            _MovieSection(
              state: movies,
              upcoming: false,
              retry: () => ref.invalidate(moviesProvider),
              onOpen: (movie) => _openMovie(context, movie),
              onBook: (movie) => _bookMovie(context, movie),
            ),
            HomeSectionHeading(
              eyebrow: 'SẮP KHỞI CHIẾU',
              title: 'PHIM SẮP CHIẾU',
              subtitle: 'Đón chờ những bom tấn tiếp theo sắp đổ bộ phòng vé',
              accent: AppColors.lavender,
              action: 'Xem tất cả',
              onAction: () => context.go(AppRoutes.discover),
            ),
            _MovieSection(
              state: movies,
              upcoming: true,
              retry: () => ref.invalidate(moviesProvider),
              onOpen: (movie) => _openMovie(context, movie),
            ),
            HomeCinemasSection(onBook: (id) => _openSeats(context, ref, id)),
            // F&B stays hidden until a production catalog is integrated.
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _MovieSection extends StatelessWidget {
  const _MovieSection({
    required this.state,
    required this.upcoming,
    required this.retry,
    required this.onOpen,
    this.onBook,
  });
  final AsyncValue<List<Movie>> state;
  final bool upcoming;
  final VoidCallback retry;
  final ValueChanged<Movie> onOpen;
  final ValueChanged<Movie>? onBook;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) return const RepositoryStatePane.loading();
    if (state.hasError) return RepositoryStatePane.error(onRetry: retry);
    final movies = state.requireValue
        .where((m) => upcoming ? m.isComingSoon : m.isNowShowing)
        .take(20)
        .toList(growable: false);
    if (movies.isEmpty) {
      return RepositoryStatePane.empty(
        title: upcoming ? 'Chưa có phim sắp chiếu' : 'Chưa có phim đang chiếu',
        message: 'Danh sách phim sẽ được cập nhật sớm.',
      );
    }
    return HomeMovieCarousel(movies: movies, onOpen: onOpen, onBook: onBook);
  }
}
