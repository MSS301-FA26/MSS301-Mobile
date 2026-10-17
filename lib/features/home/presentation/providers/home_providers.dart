import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../movie/data/models/cinema_dto.dart';
import '../../../movie/data/repositories/catalog_providers.dart';
import '../../../movie/data/models/catalog_enums.dart';

final quickBookingMoviesProvider = FutureProvider((ref) {
  return ref
      .watch(catalogRepositoryProvider)
      .getMovies(status: MovieStatus.nowShowing);
});

/// Presentation consumer of the existing public catalog repository.
final homeCinemasProvider = FutureProvider<List<CinemaDto>>((ref) {
  return ref.watch(catalogRepositoryProvider).getCinemas();
});
