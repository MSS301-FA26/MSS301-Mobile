import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_session.dart';
import '../../../movie/data/models/catalog_enums.dart';
import '../../../movie/presentation/models/movie.dart';
import '../../../movie/presentation/providers/movie_engagement_provider.dart';
import 'home_preview_provider.dart';

class HomeRecommendation {
  const HomeRecommendation({required this.movie, required this.reason});

  final Movie movie;
  final String reason;
}

String homeRecommendationReason(String? value) {
  final reason = value?.trim() ?? '';
  if (reason.startsWith('Based on your recent interest in ')) {
    final genre = reason.substring('Based on your recent interest in '.length);
    return 'Theo sở thích gần đây của bạn: $genre';
  }
  if (reason.startsWith('Featuring ') &&
      reason.endsWith(' whose performances you liked')) {
    final actor = reason.substring(
      'Featuring '.length,
      reason.length - ' whose performances you liked'.length,
    );
    return 'Có diễn viên $actor mà bạn yêu thích';
  }
  return switch (reason) {
    'Trending and popular now showing in cinemas' =>
      'Đang được yêu thích tại rạp',
    'Personalized recommendation matching your taste profile' =>
      'Phù hợp với sở thích xem phim của bạn',
    'Similar to movies you rated highly' =>
      'Tương tự những phim bạn đánh giá cao',
    'Popular among moviegoers with similar tastes' =>
      'Được yêu thích bởi người có cùng gu phim',
    'Popular at your selected cinema location' =>
      'Được yêu thích tại rạp bạn đã chọn',
    'High semantic similarity in content, genre, and themes' =>
      'Có nội dung và thể loại gần với phim bạn thích',
    _ => reason,
  };
}

/// AI orders the candidates; Catalog supplies the current movie status and art.
final homeRecommendationsProvider = FutureProvider<List<HomeRecommendation>>((
  ref,
) async {
  final userId = ref.watch(
    authSessionProvider.select((state) => state.session?.user.id),
  );
  final ai = ref.watch(movieEngagementRepositoryProvider);
  final (recommendations, showing) = await (
    userId == null
        ? ai.getTrendingRecommendations()
        : ai.getUserRecommendations(userId),
    ref.watch(homeCategoryMoviesProvider(MovieStatus.nowShowing).future),
  ).wait;

  final current = {for (final movie in showing) movie.id: movie};
  final seen = <int>{};
  return [
    for (final item in recommendations)
      if (seen.add(item.movieId) && current.containsKey(item.movieId))
        HomeRecommendation(
          movie: current[item.movieId]!,
          reason: homeRecommendationReason(item.reason),
        ),
  ];
}, retry: (retryCount, error) => null);
