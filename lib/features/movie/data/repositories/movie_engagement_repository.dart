import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../models/recommendation_dto.dart';
import '../models/review_dto.dart';

class MovieEngagementRepository {
  MovieEngagementRepository(this._dio);
  final Dio _dio;

  Future<ReviewSummaryDto> getReviewSummary(int movieId) async =>
      ReviewSummaryDto.fromJson(
        _data(await _get('/api/v1/reviews/movies/$movieId/summary')),
      );

  Future<List<ReviewDto>> getReviews(
    int movieId, {
    int page = 0,
    int size = 5,
  }) async {
    final data = _data(
      await _get(
        '/api/v1/reviews/movies/$movieId',
        query: {'page': page, 'size': size},
      ),
    );
    final items = data['items'] ?? data['content'] ?? const [];
    if (items is! List) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Invalid review list response.',
      );
    }
    return items
        .map(
          (item) => ReviewDto.fromJson(Map<String, Object?>.from(item as Map)),
        )
        .toList(growable: false);
  }

  Future<List<RecommendationDto>> getRecommendations(int movieId) async {
    final response = await _get('/api/v1/recommendation/content/$movieId');
    final body = response.data;
    final value = body is Map ? body['data'] : body;
    if (value is! List) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Invalid recommendation response.',
      );
    }
    return value
        .map(
          (item) => RecommendationDto.fromJson(
            Map<String, Object?>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<Response<dynamic>> _get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      return await _dio.get(path, queryParameters: query);
    } on DioException catch (error) {
      if (error.error is ApiException) throw error.error! as ApiException;
      rethrow;
    }
  }

  Map<String, Object?> _data(Response<dynamic> response) {
    final body = response.data;
    if (body is! Map || body['success'] != true || body['data'] is! Map) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Invalid movie engagement response.',
      );
    }
    return Map<String, Object?>.from(body['data'] as Map);
  }
}
