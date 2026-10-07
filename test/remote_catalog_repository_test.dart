import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mss301_mobile/core/config/api_config.dart';
import 'package:mss301_mobile/core/config/app_config.dart';
import 'package:mss301_mobile/core/network/dio_client.dart';
import 'package:mss301_mobile/core/network/network_providers.dart';
import 'package:mss301_mobile/features/movie/data/repositories/remote_catalog_repository.dart';
import 'package:mss301_mobile/features/movie/data/repositories/catalog_providers.dart';
import 'package:mss301_mobile/features/showtime/data/models/showtime_dto.dart';
import 'package:mss301_mobile/features/showtime/presentation/models/showtime_models.dart';

void main() {
  test(
    'maps gateway movie pages, cinema list, and showtime date filters',
    () async {
      final adapter = _CatalogAdapter();
      final repository = RemoteCatalogRepository(
        Dio()..httpClientAdapter = adapter,
      );

      final movies = await repository.getMovies(keyword: 'Dune');
      final movie = await repository.getMovie(7);
      final cinemas = await repository.getCinemas();
      final showtimes = await repository.getShowtimes(
        movieId: 7,
        date: DateTime(2026, 10, 7),
      );

      expect(movies.single.title, 'Dune');
      expect(movies.single.posterUrl, isNull);
      expect(movie?.id, 7);
      expect(cinemas.single.name, 'Cine Central');
      expect(showtimes.single.status.wireValue, 'OPEN');
      expect(adapter.showtimeQuery['movieId'], '7');
      expect(adapter.showtimeQuery['date'], '2026-10-07');
      expect(adapter.movieQuery['keyword'], 'Dune');
    },
  );

  test(
    'handles an empty page and maps gateway errors to ApiException behavior',
    () async {
      final emptyAdapter = _CatalogAdapter(emptyMovies: true);
      final emptyRepository = RemoteCatalogRepository(
        Dio()..httpClientAdapter = emptyAdapter,
      );
      expect(await emptyRepository.getMovies(), isEmpty);

      final missingAdapter = _CatalogAdapter(missingMovie: true);
      final dio = createDioClient(
        ApiConfig(
          appConfig: AppConfig(
            environment: AppEnvironment.development,
            apiBaseUrl: 'http://catalog.test',
          ),
        ),
      )..httpClientAdapter = missingAdapter;
      final missingRepository = RemoteCatalogRepository(dio);
      expect(await missingRepository.getMovie(404), isNull);
    },
  );

  test('binds the production catalog provider to the remote repository', () {
    final container = ProviderContainer(
      overrides: [dioProvider.overrideWithValue(Dio())],
    );
    addTearDown(container.dispose);
    expect(
      container.read(catalogRepositoryProvider),
      isA<RemoteCatalogRepository>(),
    );
  });

  test('treats only the backend OPEN showtime status as bookable', () {
    for (final status in ['OPEN', 'SCHEDULED', 'CANCELLED', 'COMPLETED']) {
      final dto = ShowtimeDto.fromJson(
        Map<String, Object?>.from({..._showtime, 'status': status}),
      );
      final slot = mapShowtimesToPresentation(dto.movieId, [
        dto,
      ]).rooms.single.slots.single;
      expect(slot.isBookable, status == 'OPEN', reason: status);
    }
  });
}

class _CatalogAdapter implements HttpClientAdapter {
  _CatalogAdapter({this.emptyMovies = false, this.missingMovie = false});

  final bool emptyMovies;
  final bool missingMovie;
  Map<String, String> showtimeQuery = const {};
  Map<String, String> movieQuery = const {};

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/api/v1/movies/404' && missingMovie) {
      return _json({'message': 'Movie not found'}, statusCode: 404);
    }
    if (options.path == '/api/v1/showtimes') {
      showtimeQuery = options.uri.queryParameters;
      return _json({
        'success': true,
        'data': {
          'items': [_showtime],
        },
      });
    }
    if (options.path == '/api/v1/cinemas') {
      return _json({
        'success': true,
        'data': [_cinema],
      });
    }
    if (options.path == '/api/v1/movies/7') {
      return _json({'success': true, 'data': _movie});
    }
    movieQuery = options.uri.queryParameters;
    return _json({
      'success': true,
      'data': {
        'items': emptyMovies ? const [] : [_movie],
      },
    });
  }
}

ResponseBody _json(Object value, {int statusCode = 200}) =>
    ResponseBody.fromString(
      jsonEncode(value),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

const _movie = {
  'id': 7,
  'title': 'Dune',
  'durationMinutes': 155,
  'status': 'NOW_SHOWING',
  'genres': [],
  'actors': [],
  'mainActorIds': [],
};
const _cinema = {
  'id': 3,
  'name': 'Cine Central',
  'address': '1 Main St',
  'city': 'HCM',
  'status': 'ACTIVE',
};
const _showtime = {
  'id': 11,
  'movieId': 7,
  'cinemaId': 3,
  'roomId': 5,
  'startTime': '2026-10-07T10:00:00',
  'endTime': '2026-10-07T12:35:00',
  'movieGenreNames': [],
  'weekendSurcharge': false,
  'holidaySurcharge': false,
  'status': 'OPEN',
  'basePrice': 120000,
};
