import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../data/models/recommendation_dto.dart';
import '../../data/models/review_dto.dart';
import '../../data/repositories/movie_engagement_repository.dart';

final movieEngagementRepositoryProvider = Provider(
  (ref) => MovieEngagementRepository(ref.watch(dioProvider)),
);
final movieReviewSummaryProvider = FutureProvider.family<ReviewSummaryDto, int>(
  (ref, id) =>
      ref.watch(movieEngagementRepositoryProvider).getReviewSummary(id),
);
final movieReviewsProvider = FutureProvider.family<List<ReviewDto>, int>(
  (ref, id) => ref.watch(movieEngagementRepositoryProvider).getReviews(id),
);
final movieRecommendationsProvider =
    FutureProvider.family<List<RecommendationDto>, int>(
      (ref, id) =>
          ref.watch(movieEngagementRepositoryProvider).getRecommendations(id),
    );
