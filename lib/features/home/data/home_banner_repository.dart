import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/network/api_exception.dart';
import '../../movie/data/models/catalog_enums.dart';
import '../../movie/data/models/movie_dto.dart';
import '../../movie/data/repositories/catalog_providers.dart';
import '../presentation/providers/home_preview_provider.dart';
import 'fe_banner_image_overrides.dart';

class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.image,
    required this.title,
    this.movieId,
    this.ctaType = 'NONE',
    this.url,
    this.focalPoint = 'CENTER',
    this.isDefaultTemplate = false,
  });
  final int id;
  final String image;
  final String title;
  final int? movieId;
  final String ctaType;
  final String? url;
  final String focalPoint;
  final bool isDefaultTemplate;

  factory HomeBanner.fromJson(Map<String, dynamic> json, String origin) {
    String first(List<String> keys) => keys
        .map((key) => json[key]?.toString().trim() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    final raw = first([
      'imageDesktop',
      'desktopImageUrl',
      'imageMobile',
      'mobileImageUrl',
    ]);
    final image = raw.isEmpty ? '' : Uri.parse(origin).resolve(raw).toString();
    return HomeBanner(
      id: (json['id'] as num).toInt(),
      image: image,
      title: first(['title', 'altText', 'name']),
      movieId: ((json['linkedMovieId'] ?? json['movieId']) as num?)?.toInt(),
      ctaType: first(['primaryCtaType']),
      url: json['primaryCtaUrl']?.toString() ?? json['ctaUrl']?.toString(),
      focalPoint: first(['focalPoint']),
      isDefaultTemplate:
          (json['name']?.toString() ?? '').contains('Default Experience') ||
          (json['title']?.toString() ?? '').contains('CINEPREMIER CINEMAS'),
    );
  }
}

class HomeBannerRepository {
  HomeBannerRepository(this.dio);
  final Dio dio;
  Future<List<HomeBanner>> getBanners() async {
    final body = (await dio.get('/api/v1/hero-banners')).data;
    if (body is! Map || body['success'] != true || body['data'] is! List) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Invalid banner response',
      );
    }
    return (body['data'] as List)
        .map(
          (item) => HomeBanner.fromJson(
            Map<String, dynamic>.from(item as Map),
            dio.options.baseUrl,
          ),
        )
        .where((banner) => banner.image.isNotEmpty)
        .toList(growable: false);
  }
}

final homeBannerRepositoryProvider = Provider(
  (ref) => HomeBannerRepository(ref.watch(dioProvider)),
);
// Match FE HomePage's editorial-first feed and newest-film supplementation.
List<HomeBanner> selectHomeBanners(
  List<HomeBanner> backend,
  List<MovieDto> movies,
  String origin,
) {
  final editorial = backend
      .where((banner) => banner.id > 0 && !banner.isDefaultTemplate)
      .toList();
  if (editorial.length >= 5) return editorial;
  final seenTitles = <String>{};
  final candidates =
      movies.where((movie) {
        if (![
          MovieStatus.nowShowing,
          MovieStatus.upcoming,
        ].contains(movie.status)) {
          return false;
        }
        final title = movie.title
            .toLowerCase()
            .replaceFirst(RegExp(r'\s+[a-z]$', caseSensitive: false), '')
            .trim();
        return seenTitles.add(title);
      }).toList()..sort((a, b) {
        final created = (b.createdAt?.millisecondsSinceEpoch ?? 0).compareTo(
          a.createdAt?.millisecondsSinceEpoch ?? 0,
        );
        if (created != 0) return created;
        final id = b.id.compareTo(a.id);
        if (id != 0) return id;
        return (b.releaseDate?.millisecondsSinceEpoch ?? 0).compareTo(
          a.releaseDate?.millisecondsSinceEpoch ?? 0,
        );
      });
  final existingIds = editorial.map((banner) => banner.movieId).toSet();
  final existingTitles = editorial
      .map((banner) => banner.title.toUpperCase().trim())
      .toSet();
  final result = [...editorial];
  for (final movie in candidates.take(20)) {
    if (result.length >= 5) break;
    if (existingIds.contains(movie.id) ||
        existingTitles.contains(movie.title.toUpperCase().trim())) {
      continue;
    }
    final horizontal = [movie.bannerUrl, movie.avatarUrl]
        .whereType<String>()
        .where(
          (value) => value.trim().isNotEmpty && !value.contains('placeholder'),
        )
        .firstOrNull;
    final raw =
        feBannerImageOverrides[movie.id] ?? horizontal ?? movie.posterUrl ?? '';
    if (raw.trim().isEmpty) continue;
    result.add(
      HomeBanner(
        id: -movie.id,
        image: Uri.parse(origin).resolve(raw.trim()).toString(),
        title: movie.title.toUpperCase(),
        movieId: movie.id,
        ctaType: movie.status == MovieStatus.nowShowing
            ? 'BOOK_NOW'
            : 'VIEW_MOVIE',
      ),
    );
  }
  return result.isNotEmpty ? result : backend;
}

final homeBannersProvider = FutureProvider<List<HomeBanner>>((ref) async {
  if (ref.watch(homeUiPreviewProvider)) {
    // Explicit UI preview only; production always uses the public banner API.
    return const [
      HomeBanner(
        id: -1,
        image: 'assets/mock/movies/inception-banner.jpg',
        title: 'Inception — Dữ liệu mẫu',
      ),
      HomeBanner(
        id: -2,
        image: 'assets/mock/movies/avengers-endgame-poster.jpg',
        title: 'Avengers — Dữ liệu mẫu',
      ),
    ];
  }
  final bannersRepository = ref.watch(homeBannerRepositoryProvider);
  final catalog = ref.watch(catalogRepositoryProvider);
  List<HomeBanner> backend = const [];
  Object? bannerError;
  try {
    backend = await bannersRepository.getBanners();
  } catch (error) {
    bannerError = error;
  }
  if (backend.where((b) => b.id > 0 && !b.isDefaultTemplate).length >= 5) {
    return selectHomeBanners(
      backend,
      const [],
      bannersRepository.dio.options.baseUrl,
    );
  }
  final movies = <MovieDto>[];
  try {
    var page = 0;
    while (true) {
      final response = await catalog.getMoviePage(page: page, size: 100);
      movies.addAll(response.items);
      if (response.items.isEmpty || page + 1 >= response.totalPages) break;
      page++;
    }
  } catch (_) {
    if (backend.isEmpty) rethrow;
  }
  final result = selectHomeBanners(
    backend,
    movies,
    bannersRepository.dio.options.baseUrl,
  );
  if (result.isEmpty && bannerError != null) throw bannerError;
  return result;
});
