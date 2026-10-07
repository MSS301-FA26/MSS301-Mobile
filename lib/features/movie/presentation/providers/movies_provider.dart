import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/movie_dto.dart';
import '../../data/repositories/catalog_providers.dart';
import '../models/movie.dart';

final moviesProvider = FutureProvider<List<Movie>>((ref) async {
  final repository = ref.watch(catalogRepositoryProvider);
  final movies = await repository.getMovies();
  return movies.map(mapMovieToPresentation).toList(growable: false);
});

final movieSearchProvider = FutureProvider.family<List<Movie>, String>((
  ref,
  keyword,
) async {
  final repository = ref.watch(catalogRepositoryProvider);
  final movies = await repository.getMovies(keyword: keyword);
  return movies.map(mapMovieToPresentation).toList(growable: false);
});

final movieProvider = FutureProvider.family<Movie?, int>((ref, movieId) async {
  final repository = ref.watch(catalogRepositoryProvider);
  final movie = await repository.getMovie(movieId);
  return movie == null ? null : mapMovieToPresentation(movie);
});

Movie mapMovieToPresentation(MovieDto movie) {
  final genres = movie.genres
      .map((genre) => genre.name)
      .toList(growable: false);
  return Movie(
    id: movie.id,
    title: movie.title,
    ageRating: movie.ageRating ?? 'P',
    duration: '${movie.durationMinutes} phút',
    rating: 0,
    ratingCount: '',
    genre: genres.isEmpty ? 'Đang cập nhật' : genres.join(', '),
    genreTags: genres,
    tagline: movie.description ?? '',
    description: movie.description,
    director: movie.director,
    cast: movie.castList ?? movie.mainActors,
    language: movie.language,
    subtitleLanguage: movie.subtitleLanguage,
    trailerUrl: movie.trailerUrl,
    posterAsset: movie.posterUrl ?? movie.avatarUrl ?? '',
    format: '',
    releaseDate: movie.releaseDate,
    status: movie.status,
  );
}
