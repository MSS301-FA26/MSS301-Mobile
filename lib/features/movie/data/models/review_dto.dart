import '../../../../core/contracts/json_parsers.dart';

class ReviewSummaryDto {
  const ReviewSummaryDto({
    required this.averageRating,
    required this.totalReviews,
    required this.verifiedRatio,
  });
  final double averageRating;
  final int totalReviews;
  final double verifiedRatio;
  factory ReviewSummaryDto.fromJson(Map<String, Object?> json) =>
      ReviewSummaryDto(
        averageRating: doubleFromJson(json['averageRating'] ?? 0),
        totalReviews: intFromJson(json['totalReviews'] ?? 0),
        verifiedRatio: doubleFromJson(json['verifiedRatio'] ?? 0),
      );
}

class ReviewDto {
  const ReviewDto({
    required this.id,
    required this.userName,
    required this.rating,
    required this.content,
    required this.verifiedBooking,
    required this.createdAt,
  });
  final int id;
  final String userName;
  final int rating;
  final String content;
  final bool verifiedBooking;
  final DateTime? createdAt;
  factory ReviewDto.fromJson(Map<String, Object?> json) => ReviewDto(
    id: intFromJson(json['id'] ?? 0),
    userName: (json['userFullName'] ?? json['userEmail'] ?? 'Khán giả')
        .toString(),
    rating: intFromJson(json['rating'] ?? 0),
    content: json['content']?.toString() ?? '',
    verifiedBooking: boolFromJson(json['verifiedBooking']),
    createdAt: nullableDateTimeFromJson(json['createdAt']),
  );
}
