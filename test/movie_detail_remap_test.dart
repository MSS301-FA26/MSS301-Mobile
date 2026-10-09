import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/routing/app_router.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/core/theme/app_theme.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';
import 'package:mss301_mobile/features/movie/data/models/recommendation_dto.dart';
import 'package:mss301_mobile/features/movie/data/models/review_dto.dart';
import 'package:mss301_mobile/features/movie/presentation/models/movie.dart';
import 'package:mss301_mobile/features/movie/presentation/pages/movie_detail_page.dart';
import 'package:mss301_mobile/features/movie/presentation/providers/movie_engagement_provider.dart';
import 'package:mss301_mobile/features/movie/presentation/providers/movies_provider.dart';
import 'package:mss301_mobile/features/movie/presentation/widgets/movie_detail_engagement.dart';
import 'package:mss301_mobile/features/movie/presentation/widgets/movie_detail_header.dart';
import 'package:mss301_mobile/features/movie/presentation/widgets/trailer_preview_dialog.dart';
import 'package:mss301_mobile/shared/widgets/app_button.dart';
import 'package:mss301_mobile/shared/widgets/app_image.dart';
import 'package:mss301_mobile/shared/widgets/repository_state_pane.dart';

import 'support/pump_test_app.dart';

const _summary = ReviewSummaryDto(
  averageRating: 8.6,
  totalReviews: 12,
  verifiedRatio: 0.5,
);
const _emptySummary = ReviewSummaryDto(
  averageRating: 0,
  totalReviews: 0,
  verifiedRatio: 0,
);
final _reviews = List.generate(
  4,
  (index) => ReviewDto(
    id: 901 + index,
    userName: 'Khán giả ${index + 1}',
    rating: 9 - index,
    content: 'Nội dung đánh giá thật được cung cấp ${index + 1}.',
    verifiedBooking: index == 0,
    createdAt: DateTime(2026, 10, 9 - index),
  ),
);
const _recommendations = [
  RecommendationDto(
    movieId: 802,
    title: 'Phim gợi ý theo hợp đồng hiện tại',
    posterUrl: 'https://catalog.test/802.jpg',
    averageRating: 7.8,
  ),
  RecommendationDto(
    movieId: 803,
    title: 'Phim chưa có điểm đánh giá',
    averageRating: 0,
  ),
];

Movie _movie({
  MovieStatus status = MovieStatus.nowShowing,
  String? trailerUrl,
}) => Movie(
  id: 701,
  title: 'Hành trình đến hành tinh cát và những bí mật chưa được khám phá',
  ageRating: 'T13',
  duration: '166 phút',
  rating: 0,
  genre: 'Khoa học viễn tưởng',
  genreTags: const [
    'Khoa học viễn tưởng và những chuyến phiêu lưu xuyên không gian',
    'Phiêu lưu',
  ],
  tagline: '',
  description: List.filled(
    8,
    'Một hành trình qua các vì sao với những lựa chọn và bí mật chưa được khám phá.',
  ).join(' '),
  posterAsset: 'https://catalog.test/701.jpg',
  director: 'Đạo diễn được cung cấp',
  cast: 'Diễn viên A, Diễn viên B',
  language: 'Tiếng Anh',
  subtitleLanguage: 'Tiếng Việt',
  releaseDate: DateTime(2026, 10, 1),
  format: '',
  status: status,
  trailerUrl: trailerUrl,
);

Future<void> _open(
  WidgetTester tester, {
  double width = 430,
  Movie? movie,
  Future<Movie?> Function()? movieLoader,
  Future<ReviewSummaryDto> Function()? summaryLoader,
  Future<List<ReviewDto>> Function()? reviewsLoader,
  Future<List<RecommendationDto>> Function()? recommendationsLoader,
}) async {
  await pumpTestApp(
    tester,
    initialLocation: AppRoutes.movieDetail(701),
    size: Size(width, 844),
    providerOverrides: [
      movieProvider(701).overrideWith(
        (ref) => movieLoader != null
            ? movieLoader()
            : Future.value(movie ?? _movie()),
      ),
      movieReviewSummaryProvider(701).overrideWith(
        (ref) =>
            summaryLoader != null ? summaryLoader() : Future.value(_summary),
      ),
      movieReviewsProvider(701).overrideWith(
        (ref) =>
            reviewsLoader != null ? reviewsLoader() : Future.value(_reviews),
      ),
      movieRecommendationsProvider(701).overrideWith(
        (ref) => recommendationsLoader != null
            ? recommendationsLoader()
            : Future.value(_recommendations),
      ),
    ],
  );
}

void main() {
  testWidgets(
    'renders supplied title, metadata and meaningful summary rating',
    (tester) async {
      final movie = _movie();
      await _open(tester, movie: movie);
      expect(find.text(movie.title), findsNWidgets(2));
      expect(find.text('T13'), findsOneWidget);
      expect(find.text('Đang chiếu'), findsOneWidget);
      expect(find.text('166 phút'), findsNWidgets(2));
      expect(find.text('Khởi chiếu 01/10/2026'), findsOneWidget);
      expect(find.text('Tiếng Anh'), findsOneWidget);
      expect(find.text(movie.director!), findsOneWidget);
      expect(find.text(movie.cast!), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('movie-detail-rating')))
            .data,
        '★ 8.6/10',
      );
      final poster = tester.widget<AppImage>(
        find.byKey(const ValueKey('movie-detail-poster')),
      );
      expect(poster.asset, movie.posterAsset);
      expect(poster.aspectRatio, AppSizes.posterAspectRatio);
      expect(find.textContaining('CatalogRepository'), findsNothing);
      final bookingLabel = find.descendant(
        of: find.byKey(const ValueKey('movie-detail-book-701')),
        matching: find.text('Đặt vé'),
      );
      expect(tester.widget<Text>(bookingLabel).style!.fontFamily, 'Inter');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('zero or absent ratings are not presented as a real score', (
    tester,
  ) async {
    await _open(
      tester,
      summaryLoader: () async => _emptySummary,
      reviewsLoader: () async => [],
    );
    expect(find.byKey(const ValueKey('movie-detail-rating')), findsNothing);
    expect(find.textContaining('0.0'), findsNothing);
    expect(find.text('Chưa có đánh giá'), findsOneWidget);
  });

  testWidgets('synopsis expansion changes only local presentation', (
    tester,
  ) async {
    final movie = _movie();
    await _open(tester, movie: movie);
    final synopsis = find.byKey(const ValueKey('movie-detail-synopsis'));
    final toggle = find.byKey(const ValueKey('movie-detail-synopsis-toggle'));
    expect(tester.widget<Text>(synopsis).maxLines, 4);
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(synopsis).maxLines, isNull);
    expect(tester.widget<Text>(synopsis).data, movie.description);
    expect(find.text('Thu gọn'), findsOneWidget);
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(synopsis).maxLines, 4);
  });

  testWidgets(
    'reviews retain supplied summary, names, dates and first-three order',
    (tester) async {
      await _open(tester);
      await tester.ensureVisible(find.byType(MovieDetailReviews));
      await tester.pumpAndSettle();
      expect(find.text('12 lượt đánh giá'), findsNWidgets(2));
      expect(find.text('Khán giả 1'), findsOneWidget);
      expect(find.text('Khán giả 3'), findsOneWidget);
      expect(find.text('Khán giả 4'), findsNothing);
      expect(find.text(_reviews.first.content), findsOneWidget);
      expect(find.text('09/10/2026'), findsOneWidget);
      expect(find.text('9/10'), findsOneWidget);
      expect(find.text('Đã mua vé'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Khán giả 1')).dy,
        lessThan(tester.getTopLeft(find.text('Khán giả 2')).dy),
      );
    },
  );

  testWidgets(
    'recommendations preserve IDs, order, remote posters and meaningful ratings',
    (tester) async {
      await _open(tester);
      await tester.ensureVisible(find.byType(MovieDetailRecommendations));
      await tester.pumpAndSettle();
      final first = find.byKey(
        const ValueKey('movie-detail-recommendation-802'),
      );
      final second = find.byKey(
        const ValueKey('movie-detail-recommendation-803'),
      );
      expect(first, findsOneWidget);
      expect(second, findsOneWidget);
      expect(
        tester.getTopLeft(first).dx,
        lessThan(tester.getTopLeft(second).dx),
      );
      final poster = tester.widget<AppImage>(
        find.descendant(of: first, matching: find.byType(AppImage)),
      );
      expect(poster.asset, _recommendations.first.posterUrl);
      expect(poster.aspectRatio, AppSizes.posterAspectRatio);
      expect(find.text('★ 7.8/10'), findsOneWidget);
      expect(find.textContaining('0.0'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('optional failures retain basic details and booking action', (
    tester,
  ) async {
    await _open(
      tester,
      summaryLoader: () async => throw StateError('summary unavailable'),
      reviewsLoader: () async => throw StateError('reviews unavailable'),
      recommendationsLoader: () async =>
          throw StateError('recommendations unavailable'),
    );
    expect(find.text(_movie().title), findsNWidgets(2));
    expect(find.text('Chưa thể tải tổng hợp đánh giá.'), findsOneWidget);
    expect(find.text('Chưa thể tải phim gợi ý.'), findsOneWidget);
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const ValueKey('movie-detail-book-701')),
          )
          .onPressed,
      isNotNull,
    );
    expect(find.text('Đã xảy ra lỗi'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('review list remains available when summary alone fails', (
    tester,
  ) async {
    await _open(
      tester,
      summaryLoader: () async => throw StateError('summary unavailable'),
    );
    expect(find.text('Khán giả 1'), findsOneWidget);
    expect(find.byKey(const ValueKey('movie-detail-rating')), findsNothing);
  });

  testWidgets('pending optional requests do not block basic detail', (
    tester,
  ) async {
    final summary = Completer<ReviewSummaryDto>();
    final reviews = Completer<List<ReviewDto>>();
    final recommendations = Completer<List<RecommendationDto>>();
    await _open(
      tester,
      summaryLoader: () => summary.future,
      reviewsLoader: () => reviews.future,
      recommendationsLoader: () => recommendations.future,
    );
    expect(find.text('Đang tải tổng hợp đánh giá…'), findsOneWidget);
    expect(find.text('Đang tải đánh giá…'), findsOneWidget);
    expect(find.text('Đang tải phim gợi ý…'), findsOneWidget);
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const ValueKey('movie-detail-book-701')),
          )
          .onPressed,
      isNotNull,
    );
    summary.complete(_summary);
    reviews.complete(_reviews);
    recommendations.complete(_recommendations);
    await tester.pumpAndSettle();
    expect(find.text('Đang tải đánh giá…'), findsNothing);
  });

  for (final trailerUrl in <String?>[null, '', '   ']) {
    testWidgets('unavailable trailer "$trailerUrl" has no dead CTA', (
      tester,
    ) async {
      await _open(tester, movie: _movie(trailerUrl: trailerUrl));
      expect(find.byKey(const ValueKey('movie-detail-trailer')), findsNothing);
    });
  }

  testWidgets('trailer keeps existing preview dialog and original movie', (
    tester,
  ) async {
    final movie = _movie(trailerUrl: 'https://video.test/trailer-701');
    await _open(tester, movie: movie);
    final trailer = find.byKey(const ValueKey('movie-detail-trailer'));
    await tester.ensureVisible(trailer);
    await tester.pumpAndSettle();
    await tester.tap(trailer);
    await tester.pumpAndSettle();
    expect(find.byType(TrailerPreviewDialog), findsOneWidget);
    expect(
      tester
          .widget<TrailerPreviewDialog>(find.byType(TrailerPreviewDialog))
          .movie,
      same(movie),
    );
  });

  testWidgets(
    'booking continues to existing showtimes route with exact movie ID',
    (tester) async {
      await _open(tester);
      await tester.tap(find.byKey(const ValueKey('movie-detail-book-701')));
      expect(
        appRouter.routeInformationProvider.value.uri.toString(),
        AppRoutes.showtimesForMovie(701),
      );
      await tester.pumpAndSettle();
    },
  );

  for (final status in [
    MovieStatus.upcoming,
    MovieStatus.ended,
    MovieStatus.inactive,
    MovieStatus.unknown,
  ]) {
    testWidgets('booking eligibility remains unchanged for ${status.name}', (
      tester,
    ) async {
      await _open(tester, movie: _movie(status: status));
      expect(
        tester
            .widget<AppButton>(
              find.byKey(const ValueKey('movie-detail-book-701')),
            )
            .onPressed,
        isNull,
      );
      expect(find.text('Chưa mở bán'), findsOneWidget);
    });
  }

  for (final width in [320.0, 430.0, 768.0]) {
    testWidgets('long titles, genres and cards fit at $width px', (
      tester,
    ) async {
      await _open(tester, width: width);
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: find.byType(MovieDetailHeader),
                matching: find.text(_movie().title),
              ),
            )
            .maxLines,
        isNull,
      );
      final poster = tester.getSize(
        find.byKey(const ValueKey('movie-detail-poster')),
      );
      expect(
        poster.width / poster.height,
        closeTo(AppSizes.posterAspectRatio, 0.001),
      );
      expect(poster.width, lessThanOrEqualTo(144));
      await tester.ensureVisible(find.byType(MovieDetailRecommendations));
      await tester.pumpAndSettle();
      expect(find.text(_recommendations.first.title), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('recommendation carousel sizes naturally with large text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 844),
            textScaler: TextScaler.linear(2),
          ),
          child: const Scaffold(
            body: SingleChildScrollView(
              child: MovieDetailRecommendations(
                items: AsyncData(_recommendations),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(_recommendations.first.title), findsOneWidget);
    expect(find.text('★ 7.8/10'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('basic-detail error retries the same movie provider', (
    tester,
  ) async {
    var calls = 0;
    await _open(
      tester,
      movieLoader: () async {
        if (++calls == 1) throw StateError('catalog unavailable');
        return _movie();
      },
    );
    expect(find.text('Đã xảy ra lỗi'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byKey(const ValueKey('movie-detail-book-701')), findsOneWidget);
  });

  testWidgets('missing movie retains its empty state without booking CTA', (
    tester,
  ) async {
    await _open(tester, movieLoader: () async => null);
    expect(find.text('Không tìm thấy phim.'), findsOneWidget);
    expect(find.byKey(const ValueKey('movie-detail-book-701')), findsNothing);
    expect(find.text('Về trang chủ'), findsOneWidget);
  });

  testWidgets('basic-detail loading state remains intact', (tester) async {
    final pending = Completer<Movie?>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          movieProvider(701).overrideWith((ref) => pending.future),
          movieReviewSummaryProvider(701).overrideWith((ref) async => _summary),
          movieReviewsProvider(701).overrideWith((ref) async => []),
          movieRecommendationsProvider(701).overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const MovieDetailPage(movieId: 701),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(RepositoryStatePane), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(_movie());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('movie-detail-book-701')), findsOneWidget);
  });
}
