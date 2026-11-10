import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/features/home/data/home_banner_repository.dart';
import 'package:mss301_mobile/features/movie/data/models/movie_dto.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';

HomeBanner banner(
  int id, {
  String title = 'Editorial',
  int? movieId,
  bool template = false,
}) => HomeBanner(
  id: id,
  image: 'https://qa.invalid/$id.jpg',
  title: title,
  movieId: movieId,
  isDefaultTemplate: template,
);
MovieDto movie(
  int id, {
  String? title,
  MovieStatus status = MovieStatus.nowShowing,
  DateTime? created,
  String? avatar,
}) => MovieDto(
  id: id,
  title: title ?? 'Film $id',
  durationMinutes: 100,
  status: status,
  genres: const [],
  actors: const [],
  mainActorIds: const [],
  bannerUrl: '/horizontal-$id.jpg',
  avatarUrl: avatar,
  createdAt: created,
);

void main() {
  test(
    'FE feed replaces negative/template banners with newest eligible films',
    () {
      final selected = selectHomeBanners(
        [banner(1), banner(-7), banner(9, template: true)],
        [
          movie(2),
          movie(4),
          movie(7, status: MovieStatus.upcoming),
          movie(5, status: MovieStatus.ended),
          movie(6, status: MovieStatus.inactive),
          movie(8, created: DateTime(2026, 10, 14)),
        ],
        'https://qa.invalid',
      );
      expect(selected.map((b) => b.id), [1, -8, -7, -4, -2]);
      expect(
        selected[1].image,
        'https://image.tmdb.org/t/p/w1280/4HodYYKEIsGOdinkGi2Ucz6X9i0.jpg',
      );
      expect(selected[2].ctaType, 'VIEW_MOVIE');
      expect(selected[3].ctaType, 'BOOK_NOW');
    },
  );
  test('does not truncate five or more editorial banners', () {
    final selected = selectHomeBanners(List.generate(6, (i) => banner(i + 1)), [
      movie(99),
    ], 'https://qa.invalid');
    expect(selected.map((b) => b.id), [1, 2, 3, 4, 5, 6]);
  });
  test(
    'deduplicates film title variants and films already linked by admin',
    () {
      final selected = selectHomeBanners(
        [banner(1, title: 'Film 4', movieId: 4)],
        [
          movie(4),
          movie(9, title: 'Same Film A'),
          movie(8, title: 'Same Film'),
          movie(7),
        ],
        'https://qa.invalid',
      );
      expect(selected.map((b) => b.id), [1, -9, -7]);
    },
  );
  test('keeps BE fallback when no editorial banner or movie is available', () {
    expect(
      selectHomeBanners([banner(-7)], const [], 'https://qa.invalid').single.id,
      -7,
    );
    expect(
      selectHomeBanners(const [], const [], 'https://qa.invalid'),
      isEmpty,
    );
  });
}
