import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/routing/app_router.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';
import 'package:mss301_mobile/features/movie/data/models/movie_dto.dart';
import 'package:mss301_mobile/features/movie/data/models/recommendation_dto.dart';
import 'package:mss301_mobile/features/movie/data/models/review_dto.dart';
import 'package:mss301_mobile/features/movie/data/repositories/movie_engagement_repository.dart';
import 'package:mss301_mobile/features/movie/presentation/models/movie.dart';
import 'package:mss301_mobile/features/movie/presentation/providers/movie_engagement_provider.dart';
import 'package:mss301_mobile/features/movie/presentation/providers/movies_provider.dart';
import 'package:mss301_mobile/features/movie/presentation/widgets/trailer_preview_dialog.dart';
import 'package:mss301_mobile/shared/widgets/app_button.dart';

import 'support/pump_test_app.dart';

Movie film({
  int id = 1,
  MovieStatus status = MovieStatus.nowShowing,
  String? trailer = 'https://example.test/trailer',
  String poster = 'assets/mock/movies/inception-poster.jpg',
}) => Movie(
  id: id,
  title: id == 1
      ? 'Tên phim rất dài dành cho thử nghiệm giao diện chi tiết điện ảnh'
      : 'Phim B',
  ageRating: 'T18',
  duration: '128 phút',
  rating: null,
  genre: 'Hành động, Phiêu lưu, Tâm lý',
  tagline: '',
  description: List.filled(
    35,
    'Đây là phần nội dung dài của phim để đọc và mở rộng. ',
  ).join(),
  director: 'Đạo diễn với tên rất dài cần hiển thị đầy đủ',
  cast: List.filled(8, 'Diễn viên có tên dài').join(', '),
  language: 'Tiếng Việt',
  releaseDate: DateTime(2026, 10, 16),
  trailerUrl: trailer,
  posterAsset: poster,
  bannerAsset: 'assets/mock/movies/inception-banner.jpg',
  format: '',
  status: status,
);

class Engagement extends MovieEngagementRepository {
  Engagement() : super(Dio());
  int relatedCalls = 0, reviewCalls = 0;
  bool failRelated = false, failReviews = false;
  Completer<List<RecommendationDto>>? pending;
  List<RecommendationDto> items = const [
    RecommendationDto(
      movieId: 2,
      title: 'Phim liên quan B',
      averageRating: null,
      reason: 'Cùng thể loại',
    ),
  ];
  @override
  Future<ReviewSummaryDto> getReviewSummary(int movieId) async =>
      const ReviewSummaryDto(
        averageRating: 0,
        totalReviews: 0,
        verifiedRatio: 0,
      );
  @override
  Future<List<ReviewDto>> getReviews(
    int movieId, {
    int page = 0,
    int size = 5,
  }) async {
    reviewCalls++;
    if (failReviews) throw Exception('reviews offline');
    return [];
  }

  @override
  Future<List<RecommendationDto>> getRecommendations(int movieId) async {
    relatedCalls++;
    if (failRelated) throw Exception('recommendation offline');
    if (pending != null && movieId == 1) return pending!.future;
    return movieId == 1 ? items : [];
  }
}

Future<void> open(
  WidgetTester tester,
  Engagement repo, {
  Movie? movie,
  double width = 390,
  double scale = 1,
  bool reviews = false,
  Future<bool> Function(Uri)? launcher,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await pumpTestApp(
    tester,
    initialLocation: reviews
        ? AppRoutes.movieReviews(1)
        : AppRoutes.movieDetail(1),
    size: Size(width, 850),
    providerOverrides: [
      movieEngagementRepositoryProvider.overrideWithValue(repo),
      movieProvider(1).overrideWith((ref) async => movie ?? film()),
      movieProvider(2).overrideWith((ref) async => film(id: 2)),
      if (launcher != null)
        movieTrailerLauncherProvider.overrideWithValue(launcher),
    ],
  );
}

Finder get scroll => find.byKey(const PageStorageKey('movie-detail-scroll-1'));
Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  test(
    'movie mapping preserves API banner and does not invent formats or score',
    () {
      final movie = mapMovieToPresentation(
        MovieDto.fromJson({
          'id': 1,
          'title': 'A',
          'status': 'NOW_SHOWING',
          'bannerUrl': 'https://example.test/banner.jpg',
        }),
      );
      expect(movie.bannerAsset, 'https://example.test/banner.jpg');
      expect(movie.format, isEmpty);
      expect(movie.rating, isNull);
    },
  );

  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    testWidgets(
      'detail long content, images, synopsis and related fit $width at large text',
      (tester) async {
        await open(
          tester,
          Engagement(),
          width: width,
          scale: 1.6,
          movie: film(
            poster: width == 320
                ? 'assets/mock/movies/inception-banner.jpg'
                : 'assets/missing.jpg',
          ),
        );
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('movie-detail-title-1')),
          findsOneWidget,
        );
        expect(find.textContaining('từ đủ 18 tuổi'), findsOneWidget);
        final book = find.byKey(const ValueKey('movie-detail-book-1'));
        expect(book.hitTestable(), findsOneWidget);
        final toggle = find.byKey(const ValueKey('movie-synopsis-toggle'));
        await reveal(tester, toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(find.text('Thu gọn'), findsOneWidget);
        await reveal(tester, toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(find.text('Xem thêm'), findsOneWidget);
        await reveal(tester, find.byKey(const ValueKey('related-movie-2')));
        expect(book.hitTestable(), findsOneWidget);
        expect(find.text('0.0/10'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'related error and retry stay local; dedupe and remove current and invalid ids',
    (tester) async {
      final repo = Engagement()..failRelated = true;
      repo.items = const [
        RecommendationDto(movieId: 1, title: 'Self'),
        RecommendationDto(movieId: 2, title: 'Related'),
        RecommendationDto(movieId: 2, title: 'Duplicate'),
        RecommendationDto(movieId: 0, title: 'Invalid'),
      ];
      await open(tester, repo);
      final retry = find.byKey(const ValueKey('movie-related-retry'));
      await reveal(tester, retry);
      expect(
        find.byKey(const ValueKey('movie-detail-book-1')).hitTestable(),
        findsOneWidget,
      );
      repo.failRelated = false;
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(repo.relatedCalls, 2);
      expect(find.byKey(const ValueKey('related-movie-2')), findsOneWidget);
      expect(find.text('Self'), findsNothing);
      expect(find.text('Duplicate'), findsNothing);
      expect(find.text('Invalid'), findsNothing);
    },
  );

  testWidgets('related A to B and Back restores A scroll and its own content', (
    tester,
  ) async {
    await open(tester, Engagement());
    final related = find.byKey(const ValueKey('related-movie-2'));
    await reveal(tester, related);
    final position = tester
        .widget<SingleChildScrollView>(scroll)
        .controller!
        .offset;
    await tester.tap(related);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('movie-detail-title-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('movie-detail-title-1')), findsNothing);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('movie-detail-title-1')), findsOneWidget);
    expect(
      tester.widget<SingleChildScrollView>(scroll).controller!.offset,
      closeTo(position, 1),
    );
    expect(related.hitTestable(), findsOneWidget);
  });

  testWidgets(
    'late A recommendation cannot appear on B; empty results hide section',
    (tester) async {
      final repo = Engagement()..pending = Completer<List<RecommendationDto>>();
      await open(tester, repo);
      expect(find.text('Đang tìm phim liên quan…'), findsOneWidget);
      unawaited(appRouter.push(AppRoutes.movieDetail(2)));
      await tester.pumpAndSettle();
      repo.pending!.complete(const [
        RecommendationDto(movieId: 9, title: 'Only A recommendation'),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Phim liên quan'), findsNothing);
      expect(find.text('Only A recommendation'), findsNothing);
      expect(
        find.byKey(const ValueKey('movie-detail-title-2')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'review list errors can retry independently of zero review summary',
    (tester) async {
      final repo = Engagement()..failReviews = true;
      await open(tester, repo, reviews: true);
      final retry = find.byKey(const ValueKey('movie-reviews-retry'));
      await reveal(tester, retry);
      expect(find.text('0.0/10'), findsNothing);
      repo.failReviews = false;
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(repo.reviewCalls, 2);
      expect(retry, findsNothing);
    },
  );

  testWidgets('upcoming film and missing trailer have disabled actions', (
    tester,
  ) async {
    await open(
      tester,
      Engagement()..items = [],
      movie: film(status: MovieStatus.upcoming, trailer: null),
    );
    expect(
      tester
          .widget<AppButton>(find.byKey(const ValueKey('movie-detail-book-1')))
          .onPressed,
      isNull,
    );
    expect(find.text('Chưa mở bán'), findsOneWidget);
    expect(find.text('Chưa có trailer'), findsOneWidget);
    expect(find.text('Phim liên quan'), findsNothing);
  });

  testWidgets('booking opens showtimes filtered for exact current movie', (
    tester,
  ) async {
    await open(tester, Engagement());
    await tester.tap(find.byKey(const ValueKey('movie-detail-book-1')));
    await tester.pumpAndSettle();
    expect(
      appRouter.routeInformationProvider.value.uri.queryParameters['movieId'],
      '1',
    );
  });

  for (final invalid in [false, true]) {
    testWidgets(
      'trailer handles invalid=$invalid and actual launch failure with retry',
      (tester) async {
        var calls = 0;
        await open(
          tester,
          Engagement(),
          width: 320,
          scale: 1.6,
          movie: film(
            trailer: invalid
                ? 'javascript:alert(1)'
                : 'https://example.test/trailer',
          ),
          launcher: (uri) async {
            calls++;
            expect(uri.scheme, 'https');
            return calls > 1;
          },
        );
        await tester.tap(find.byKey(const ValueKey('movie-detail-trailer')));
        await tester.pumpAndSettle();
        final openButton = find.byKey(const ValueKey('movie-trailer-open'));
        await reveal(tester, openButton);
        await tester.tap(openButton);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('movie-trailer-error')),
          findsOneWidget,
        );
        if (invalid) {
          expect(calls, 0);
        } else {
          expect(calls, 1);
          await reveal(tester, openButton);
          await tester.tap(openButton);
          await tester.pumpAndSettle();
          expect(calls, 2);
          expect(
            find.byKey(const ValueKey('movie-trailer-error')),
            findsNothing,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final missing in [false, true]) {
    testWidgets(
      'movie detail error/missing=$missing retains Back and no booking action',
      (tester) async {
        await pumpTestApp(
          tester,
          initialLocation: AppRoutes.movieDetail(55),
          providerOverrides: [
            movieProvider(55).overrideWith((ref) async {
              if (missing) return null;
              throw Exception('not available');
            }),
            movieEngagementRepositoryProvider.overrideWithValue(Engagement()),
          ],
        );
        expect(find.byTooltip('Quay lại'), findsOneWidget);
        expect(
          find
              .byType(AppButton)
              .evaluate()
              .any(
                (e) =>
                    (e.widget as AppButton).key ==
                    const ValueKey('movie-detail-book-55'),
              ),
          isFalse,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
