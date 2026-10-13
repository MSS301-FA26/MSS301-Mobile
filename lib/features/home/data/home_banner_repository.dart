import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/network/api_exception.dart';
import '../presentation/providers/home_preview_provider.dart';

class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.image,
    required this.title,
    this.movieId,
    this.ctaType = 'NONE',
    this.url,
    this.focalPoint = 'CENTER',
  });
  final int id;
  final String image;
  final String title;
  final int? movieId;
  final String ctaType;
  final String? url;
  final String focalPoint;

  factory HomeBanner.fromJson(Map<String, dynamic> json, String origin) {
    String first(List<String> keys) => keys
        .map((key) => json[key]?.toString().trim() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    final raw = first([
      'mobileImageUrl',
      'imageMobile',
      'desktopImageUrl',
      'imageDesktop',
    ]);
    final image = raw.isEmpty ? '' : Uri.parse(origin).resolve(raw).toString();
    return HomeBanner(
      id: (json['id'] as num).toInt(),
      image: image,
      title: first(['altText', 'title', 'name']),
      movieId: ((json['linkedMovieId'] ?? json['movieId']) as num?)?.toInt(),
      ctaType: first(['primaryCtaType']),
      url: json['primaryCtaUrl']?.toString() ?? json['ctaUrl']?.toString(),
      focalPoint: first(['focalPoint']),
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
  return ref.watch(homeBannerRepositoryProvider).getBanners();
});
