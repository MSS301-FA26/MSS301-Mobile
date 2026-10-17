import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../movie/data/repositories/catalog_providers.dart';
import '../../../movie/presentation/models/movie.dart';
import '../../../movie/data/models/catalog_enums.dart';
import '../../../movie/data/models/movie_dto.dart';

// Only the Home screen uses fixtures, explicitly enabled in debug builds.
final homeUiPreviewProvider = Provider<bool>(
  (ref) => kDebugMode && const bool.fromEnvironment('UI_PREVIEW'),
);

Movie mapHomeMovie(MovieDto movie) => Movie(
  id: movie.id,
  title: movie.title,
  ageRating: movie.ageRating ?? '',
  hasAgeRating: movie.ageRating?.trim().isNotEmpty ?? false,
  duration: movie.durationMinutes > 0 ? '${movie.durationMinutes} phút' : '',
  rating: null,
  genre: movie.genres.map((genre) => genre.name).join(' · '),
  genreTags: movie.genres.map((genre) => genre.name).toList(growable: false),
  tagline: movie.description ?? '',
  posterAsset: movie.posterUrl ?? movie.avatarUrl ?? '',
  trailerUrl: movie.trailerUrl,
  releaseDate: movie.releaseDate,
  status: movie.status,
);

final homeCategoryMoviesProvider =
    FutureProvider.family<List<Movie>, MovieStatus>((ref, status) async {
      final repository = ref.watch(homeUiPreviewProvider)
          ? ref.watch(mockCatalogRepositoryProvider)
          : ref.watch(catalogRepositoryProvider);
      final movies = <int, MovieDto>{};
      var page = 0;
      while (true) {
        final result = await repository.getMoviePage(
          status: status,
          page: page,
          size: 100,
        );
        final previousCount = movies.length;
        for (final movie in result.items) {
          if (movie.status == status) movies[movie.id] = movie;
        }
        if (result.last ||
            page + 1 >= result.totalPages ||
            result.items.isEmpty ||
            movies.length == previousCount) {
          break;
        }
        page++;
      }
      return movies.values.map(mapHomeMovie).toList(growable: false);
    }, retry: (retryCount, error) => null);
