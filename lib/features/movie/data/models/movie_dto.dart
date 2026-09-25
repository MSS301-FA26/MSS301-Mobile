import '../../../../core/contracts/json_parsers.dart';
import 'catalog_enums.dart';

class GenreDto {
  const GenreDto({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory GenreDto.fromJson(Map<String, Object?> json) => GenreDto(
    id: intFromJson(json['id'], field: 'genre.id'),
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString(),
    createdAt: nullableDateTimeFromJson(json['createdAt']),
    updatedAt: nullableDateTimeFromJson(json['updatedAt']),
  );
}

class ActorDto {
  const ActorDto({
    required this.id,
    required this.name,
    required this.movieCount,
    this.biography,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String? biography;
  final String? avatarUrl;
  final int movieCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ActorDto.fromJson(Map<String, Object?> json) => ActorDto(
    id: intFromJson(json['id'], field: 'actor.id'),
    name: json['name']?.toString() ?? '',
    biography: json['biography']?.toString(),
    avatarUrl: json['avatarUrl']?.toString(),
    movieCount: intFromJson(json['movieCount'] ?? 0),
    createdAt: nullableDateTimeFromJson(json['createdAt']),
    updatedAt: nullableDateTimeFromJson(json['updatedAt']),
  );
}

class MovieDto {
  const MovieDto({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.status,
    required this.genres,
    required this.actors,
    required this.mainActorIds,
    this.description,
    this.trailerUrl,
    this.posterUrl,
    this.avatarUrl,
    this.releaseDate,
    this.endDate,
    this.language,
    this.subtitleLanguage,
    this.ageRating,
    this.director,
    this.mainActors,
    this.castList,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String title;
  final String? description;
  final String? trailerUrl;
  final String? posterUrl;
  final String? avatarUrl;
  final int durationMinutes;
  final DateTime? releaseDate;
  final DateTime? endDate;
  final String? language;
  final String? subtitleLanguage;
  final MovieStatus status;
  final String? ageRating;
  final String? director;
  final String? mainActors;
  final String? castList;
  final List<GenreDto> genres;
  final List<ActorDto> actors;
  final List<int> mainActorIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory MovieDto.fromJson(Map<String, Object?> json) => MovieDto(
    id: intFromJson(json['id'], field: 'movie.id'),
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString(),
    trailerUrl: json['trailerUrl']?.toString(),
    posterUrl: json['posterUrl']?.toString(),
    avatarUrl: json['avatarUrl']?.toString(),
    durationMinutes: intFromJson(json['durationMinutes'] ?? 0),
    releaseDate: nullableDateTimeFromJson(json['releaseDate']),
    endDate: nullableDateTimeFromJson(json['endDate']),
    language: json['language']?.toString(),
    subtitleLanguage: json['subtitleLanguage']?.toString(),
    status: MovieStatus.parse(json['status']),
    ageRating: json['ageRating']?.toString(),
    director: json['director']?.toString(),
    mainActors: json['mainActors']?.toString(),
    castList: json['castList']?.toString(),
    genres: listFromJson(json['genres'], GenreDto.fromJson),
    actors: listFromJson(json['actors'], ActorDto.fromJson),
    mainActorIds: intListFromJson(json['mainActorIds']),
    createdAt: nullableDateTimeFromJson(json['createdAt']),
    updatedAt: nullableDateTimeFromJson(json['updatedAt']),
  );
}

class MoviePresentationMetadata {
  const MoviePresentationMetadata({
    required this.movieId,
    this.rating,
    this.ratingCount,
    this.tagline,
    this.heroBannerAsset,
    this.formatBadge,
  });

  final int movieId;
  final double? rating;
  final int? ratingCount;
  final String? tagline;
  final String? heroBannerAsset;
  final String? formatBadge;
}
