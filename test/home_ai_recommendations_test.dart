import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/features/auth/application/auth_session.dart';
import 'package:mss301_mobile/features/home/presentation/providers/home_preview_provider.dart';
import 'package:mss301_mobile/features/home/presentation/providers/home_recommendations_provider.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';
import 'package:mss301_mobile/features/movie/data/models/recommendation_dto.dart';
import 'package:mss301_mobile/features/movie/data/repositories/movie_engagement_repository.dart';
import 'package:mss301_mobile/features/movie/presentation/models/movie.dart';
import 'package:mss301_mobile/features/movie/presentation/providers/movie_engagement_provider.dart';

import 'support/fake_auth_session.dart';

void main() {
  test('Home shows common AI reasons in Vietnamese', () {
    expect(
      homeRecommendationReason('Trending and popular now showing in cinemas'),
      'Đang được yêu thích tại rạp',
    );
    expect(
      homeRecommendationReason('Based on your recent interest in Action'),
      'Theo sở thích gần đây của bạn: Action',
    );
  });

  test(
    'signed-in Home keeps AI order and only current catalog movies',
    () async {
      final ai = _FakeAi();
      final container = _container(ai, authenticatedCustomerState());
      addTearDown(container.dispose);

      final results = await container.read(homeRecommendationsProvider.future);
      expect(ai.requestedUserId, 5101);
      expect(results.map((item) => item.movie.id), [2, 1]);
      expect(results.first.reason, 'Phù hợp sở thích');
    },
  );

  test('guest Home uses AI trending endpoint', () async {
    final ai = _FakeAi();
    final container = _container(ai, unauthenticatedState);
    addTearDown(container.dispose);

    final results = await container.read(homeRecommendationsProvider.future);
    expect(ai.requestedUserId, isNull);
    expect(ai.trendingRequested, isTrue);
    expect(results.map((item) => item.movie.id), [2, 1]);
  });
}

ProviderContainer _container(_FakeAi ai, AuthState auth) => ProviderContainer(
  overrides: [
    authSessionProvider.overrideWith(() => FakeAuthSessionController(auth)),
    movieEngagementRepositoryProvider.overrideWithValue(ai),
    homeCategoryMoviesProvider(MovieStatus.nowShowing)
        .overrideWith((ref) async => [_movie(1), _movie(2)]),
  ],
);

Movie _movie(int id) => Movie(
  id: id,
  title: 'Phim $id',
  ageRating: 'P',
  duration: '120 phút',
  rating: null,
  genre: 'Phiêu lưu',
  tagline: '',
  posterAsset: '',
  status: MovieStatus.nowShowing,
);

class _FakeAi extends MovieEngagementRepository {
  _FakeAi() : super(Dio());

  int? requestedUserId;
  bool trendingRequested = false;

  List<RecommendationDto> get items => const [
    RecommendationDto(movieId: 2, title: 'Phim 2', reason: 'Phù hợp sở thích'),
    RecommendationDto(movieId: 99, title: 'Phim không còn chiếu'),
    RecommendationDto(movieId: 2, title: 'Phim 2 trùng'),
    RecommendationDto(movieId: 1, title: 'Phim 1'),
  ];

  @override
  Future<List<RecommendationDto>> getUserRecommendations(int userId) async {
    requestedUserId = userId;
    return items;
  }

  @override
  Future<List<RecommendationDto>> getTrendingRecommendations() async {
    trendingRequested = true;
    return items;
  }
}
