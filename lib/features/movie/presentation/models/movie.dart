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
    this.genreTags = const [],
    this.bannerAsset,
    this.format = '2D',
    this.releaseDate,
    this.isNowShowing = false,
  });

  final String id;
  final String title;
  final String ageRating;
  final String duration;
  final double rating;
  final String ratingCount;
  final String genre;
  final String tagline;
  final String posterAsset;
  final List<String> genreTags;
  final String? bannerAsset;
  final String format;
  final String? releaseDate;
  final bool isNowShowing;

  bool get isComingSoon => !isNowShowing;
}
