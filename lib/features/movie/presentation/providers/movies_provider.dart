import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/demo/demo_scenario.dart';
import '../../data/models/movie_dto.dart';
import '../../data/repositories/catalog_providers.dart';
import '../models/movie.dart';

final moviesProvider = FutureProvider<List<Movie>>((ref) async {
  final repository = ref.watch(catalogRepositoryProvider);
  final movies = await repository.getMovies();
  return movies.map(mapMovieToPresentation).toList(growable: false);
});

final movieProvider = FutureProvider.family<Movie?, int>((ref, movieId) async {
  final repository = ref.watch(catalogRepositoryProvider);
  final movie = await repository.getMovie(movieId);
  return movie == null ? null : mapMovieToPresentation(movie);
});

Movie mapMovieToPresentation(MovieDto movie) {
  final metadata =
      _metadata[movie.id] ?? const MoviePresentationMetadata(movieId: -1);
  final genres = movie.genres
      .map((genre) => genre.name)
      .toList(growable: false);
  return Movie(
    id: movie.id,
    title: movie.title,
    ageRating: movie.ageRating ?? 'P',
    duration: '${movie.durationMinutes} phút',
    rating: metadata.rating ?? 0,
    ratingCount: _compactCount(metadata.ratingCount),
    genre: genres.isEmpty ? 'Đang cập nhật' : genres.join(', '),
    genreTags: genres,
    tagline: metadata.tagline ?? movie.description ?? '',
    posterAsset: movie.posterUrl ?? movie.avatarUrl ?? '',
    bannerAsset: metadata.heroBannerAsset,
    format: metadata.formatBadge ?? '2D',
    releaseDate: movie.releaseDate,
    status: movie.status,
  );
}

String _compactCount(int? value) {
  if (value == null || value == 0) return '';
  if (value >= 1000) {
    final compact = (value / 1000).toStringAsFixed(1).replaceFirst('.0', '');
    return '${compact}k';
  }
  return '$value';
}

const _metadata = <int, MoviePresentationMetadata>{
  DemoIds.movieInception: MoviePresentationMetadata(
    movieId: DemoIds.movieInception,
    rating: 8.8,
    ratingCount: 12400,
    tagline: 'Giấc mơ trong giấc mơ — đỉnh cao điện ảnh của Christopher Nolan.',
    heroBannerAsset: 'assets/mock/movies/inception-banner.jpg',
    formatBadge: 'IMAX Laser',
  ),
  DemoIds.movieAvengers: MoviePresentationMetadata(
    movieId: DemoIds.movieAvengers,
    rating: 9.4,
    ratingCount: 12800,
    tagline: 'Một phần của hành trình chính là hồi kết.',
    formatBadge: 'IMAX 3D',
  ),
  DemoIds.movieJoker: MoviePresentationMetadata(
    movieId: DemoIds.movieJoker,
    rating: 8.9,
    tagline: 'Một câu chuyện về thành phố và con người bên lề.',
  ),
  DemoIds.movieSpiderVerse: MoviePresentationMetadata(
    movieId: DemoIds.movieSpiderVerse,
    rating: 9.1,
    ratingCount: 15200,
    tagline: 'Bước vào thế giới Người Nhện đa vũ trụ.',
    formatBadge: 'IMAX Laser',
  ),
  DemoIds.movieCoco: MoviePresentationMetadata(
    movieId: DemoIds.movieCoco,
    rating: 9.3,
    tagline: 'Một hành trình đầy màu sắc về gia đình và âm nhạc.',
  ),
  DemoIds.movieGreenMile: MoviePresentationMetadata(
    movieId: DemoIds.movieGreenMile,
    rating: 8.6,
    tagline: 'Một câu chuyện khó quên về lòng trắc ẩn.',
  ),
  DemoIds.movieParasite: MoviePresentationMetadata(
    movieId: DemoIds.movieParasite,
    rating: 8.5,
    tagline: 'Hai gia đình, hai thế giới.',
  ),
  DemoIds.movieLaLaLand: MoviePresentationMetadata(
    movieId: DemoIds.movieLaLaLand,
    rating: 8.9,
    tagline: 'Một chuyện tình giữa những giấc mơ.',
  ),
};
