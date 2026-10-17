import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../../auth/application/auth_session.dart';
import '../../../movie/presentation/models/movie.dart';
import '../../../movie/presentation/providers/movies_provider.dart';
import '../widgets/home_cinemas_section.dart';
import '../widgets/home_hero_carousel.dart';
import '../widgets/home_movie_section.dart';
import '../widgets/home_quick_booking.dart';
import '../providers/home_providers.dart';

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
    final quickBookingMovies = ref.watch(quickBookingMoviesProvider);
    return AppShell(
      currentIndex: 0,
      compactHeader: true,
      body: SingleChildScrollView(
        key: const ValueKey('home-scroll'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (movies.isLoading)
              const _HomeLoadingPanel()
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
              movies:
                  quickBookingMovies.hasError || quickBookingMovies.isLoading
                  ? const []
                  : quickBookingMovies.requireValue
                        .map(mapMovieToPresentation)
                        .toList(growable: false),
              onBook: (id) => _openSeats(context, ref, id),
            ),
            HomeMovieSection(
              onOpen: (movie) => _openMovie(context, movie),
              onBook: (movie) => _bookMovie(context, movie),
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

class _HomeLoadingPanel extends StatelessWidget {
  const _HomeLoadingPanel();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 220,
    child: Center(child: CircularProgressIndicator()),
  );
}
