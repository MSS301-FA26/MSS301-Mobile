import '../../../../core/contracts/json_parsers.dart';

class RecommendationDto {
  const RecommendationDto({
    required this.movieId,
    required this.title,
    this.posterUrl,
    this.averageRating,
    this.reason,
  });
  final int movieId;
  final String title;
  final String? posterUrl;
  final double? averageRating;
  final String? reason;
  factory RecommendationDto.fromJson(Map<String, Object?> json) =>
      RecommendationDto(
        movieId: intFromJson(json['movieId'] ?? json['id']),
        title: json['title']?.toString() ?? '',
        posterUrl: json['posterUrl']?.toString(),
        averageRating: json['avgRating'] == null
            ? null
            : doubleFromJson(json['avgRating']),
        reason: json['reason']?.toString(),
      );
}
