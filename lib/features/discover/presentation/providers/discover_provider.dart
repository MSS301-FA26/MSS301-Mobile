import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../movie/data/models/catalog_enums.dart';
import '../../../movie/data/models/movie_dto.dart';
import '../../../movie/data/repositories/catalog_providers.dart';

class DiscoverQuery {
  const DiscoverQuery({
    this.keyword = '',
    this.status,
    this.genreId,
    this.page = 0,
    this.size = 20,
  });
  final String keyword;
  final MovieStatus? status;
  final int? genreId;
  final int page;
  final int size;

  @override
  bool operator ==(Object other) =>
      other is DiscoverQuery &&
      other.keyword == keyword &&
      other.status == status &&
      other.genreId == genreId &&
      other.page == page &&
      other.size == size;

  @override
  int get hashCode => Object.hash(keyword, status, genreId, page, size);
}

final discoverPageProvider = FutureProvider.autoDispose
    .family<MoviePageDto, DiscoverQuery>(
      (ref, query) => ref
          .watch(catalogRepositoryProvider)
          .getMoviePage(
            keyword: query.keyword,
            status: query.status,
            genreId: query.genreId,
            page: query.page,
            size: query.size,
          ),
    );
final discoverGenresProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(catalogRepositoryProvider).getGenres(),
);
