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
    FutureProvider.family<List<RecommendationDto>, int>((ref, id) async {
      final items = await ref
          .watch(movieEngagementRepositoryProvider)
          .getRecommendations(id);
      final seen = <int>{id};
      return items
          .where((item) => item.movieId > 0 && seen.add(item.movieId))
          .take(12)
          .toList(growable: false);
    });
