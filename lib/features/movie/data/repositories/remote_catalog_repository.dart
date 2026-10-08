import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../showtime/data/models/showtime_dto.dart';
import '../models/catalog_enums.dart';
import '../models/cinema_dto.dart';
import '../models/food_quote_dto.dart';
import '../models/movie_dto.dart';
import 'catalog_repository.dart';

class RemoteCatalogRepository implements CatalogRepository {
  RemoteCatalogRepository(this._dio);
  final Dio _dio;

  @override
  Future<List<MovieDto>> getMovies({
    MovieStatus? status,
    String? keyword,
  }) async {
    return (await getMoviePage(
      status: status,
      keyword: keyword,
      size: 100,
    )).items;
  }

  @override
  Future<MoviePageDto> getMoviePage({
    MovieStatus? status,
    String? keyword,
    int? genreId,
    int page = 0,
    int size = 20,
  }) async {
    final queryParameters = <String, dynamic>{
      if (status != null && status != MovieStatus.unknown)
        'status': status.wireValue,
      if (keyword != null && keyword.trim().isNotEmpty)
        'keyword': keyword.trim(),
      'page': page,
      'size': size,
    };
    if (genreId != null) queryParameters['genreId'] = genreId;
    final response = await _get(
      '/api/v1/movies',
      queryParameters: queryParameters,
    );
    return MoviePageDto.fromJson(_data(response));
  }

  @override
  Future<List<GenreDto>> getGenres({int page = 0, int size = 100}) async {
    final response = await _get(
      '/api/v1/genres',
      queryParameters: {'page': page, 'size': size},
    );
    final data = _data(response);
    final items = data['items'];
    return _list(items, GenreDto.fromJson);
  }

  @override
  Future<MovieDto?> getMovie(int movieId) async {
    try {
      return MovieDto.fromJson(_data(await _get('/api/v1/movies/$movieId')));
    } on ApiException catch (error) {
      if (error.type == ApiErrorType.notFound) return null;
      rethrow;
    }
  }

  @override
  Future<List<CinemaDto>> getCinemas() async =>
      _list(_data(await _get('/api/v1/cinemas'))['items'], CinemaDto.fromJson);

  @override
  Future<List<ShowtimeDto>> getShowtimes({int? movieId, DateTime? date}) async {
    final queryParameters = <String, Object>{'page': 0, 'size': 100};
    if (movieId != null) queryParameters['movieId'] = movieId;
    if (date != null) queryParameters['date'] = _date(date);
    final response = await _get(
      '/api/v1/showtimes',
      queryParameters: queryParameters,
    );
    return _list(_data(response)['items'], ShowtimeDto.fromJson);
  }

  @override
  Future<ShowtimeDto?> getShowtime(int showtimeId) async {
    try {
      return ShowtimeDto.fromJson(
        _data(await _get('/api/v1/showtimes/$showtimeId')),
      );
    } on ApiException catch (error) {
      if (error.type == ApiErrorType.notFound) return null;
      rethrow;
    }
  }

  @override
  Future<ShowtimeSeatMapDto> getSeatMap(int showtimeId) async =>
      ShowtimeSeatMapDto.fromJson(
        _data(await _get('/api/v1/showtimes/$showtimeId/seat-map')),
      );
  @override
  Future<List<FoodProductDto>> getFoodItems() => _outOfScope();
  @override
  Future<List<FoodProductDto>> getFoodCombos() => _outOfScope();
  @override
  Future<CheckoutQuoteDto> createCheckoutQuote(
    CheckoutQuoteRequestDto request,
  ) async {
    final response = await _post(
      '/api/v1/catalog/checkout-quote',
      data: {
        'showtimeId': request.showtimeId,
        'seatIds': request.seatIds,
        'tickets': request.tickets
            .map(
              (ticket) => {
                if (ticket.seatId != null) 'seatId': ticket.seatId,
                'ticketType': ticket.ticketType.wireValue,
                'viewerAge': ticket.viewerAge,
                'quantity': ticket.quantity,
              },
            )
            .toList(growable: false),
        'foods': request.foods
            .map(
              (food) => {
                'productId': food.productId,
                'isCombo': food.isCombo,
                'quantity': food.quantity,
              },
            )
            .toList(growable: false),
        if (request.voucherCode != null) 'voucherCode': request.voucherCode,
        if (request.cinePointsToUse != null)
          'cinePointsToUse': request.cinePointsToUse,
        if (request.bookingSessionId != null)
          'bookingSessionId': request.bookingSessionId,
      },
    );
    return CheckoutQuoteDto.fromJson(_data(response));
  }

  Future<T> _outOfScope<T>() => Future<T>.error(
    const ApiException(
      type: ApiErrorType.unknown,
      message: 'This catalog capability remains mock until Batch 05.',
    ),
  );

  Future<Response<dynamic>> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (error) {
      final mapped = error.error;
      if (mapped is ApiException) throw mapped;
      rethrow;
    }
  }

  Future<Response<dynamic>> _post(
    String path, {
    required Map<String, Object?> data,
  }) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (error) {
      final mapped = error.error;
      if (mapped is ApiException) throw mapped;
      rethrow;
    }
  }

  Map<String, Object?> _data(Response<dynamic> response) {
    final body = response.data;
    if (body is! Map ||
        body['success'] != true ||
        body['data'] is! Map && body['data'] is! List) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Invalid catalog API response.',
      );
    }
    final value = body['data'];
    return value is Map ? Map<String, Object?>.from(value) : {'items': value};
  }

  List<T> _list<T>(Object? value, T Function(Map<String, Object?>) fromJson) {
    if (value is! List) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Invalid catalog list response.',
      );
    }
    return value
        .map((item) => fromJson(Map<String, Object?>.from(item as Map)))
        .toList(growable: false);
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
