import '../../data/models/catalog_enums.dart';

class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.ageRating,
    required this.duration,
    required this.rating,
    this.ratingCount = '',
    required this.genre,
    required this.tagline,
    required this.posterAsset,
    this.description,
    this.director,
    this.cast,
    this.language,
    this.subtitleLanguage,
    this.trailerUrl,
    this.genreTags = const [],
    this.bannerAsset,
    this.format = '2D',
    this.releaseDate,
    required this.status,
  });

  final int id;
  final String title;
  final String ageRating;
  final String duration;
  final double rating;
  final String ratingCount;
  final String genre;
  final String tagline;
  final String? description;
  final String? director;
  final String? cast;
  final String? language;
  final String? subtitleLanguage;
  final String? trailerUrl;
  final String posterAsset;
  final List<String> genreTags;
  final String? bannerAsset;
  final String format;
  final DateTime? releaseDate;
  final MovieStatus status;

  bool get isNowShowing => status == MovieStatus.nowShowing;
  bool get isComingSoon => status == MovieStatus.upcoming;
}
