import '../../../showtime/data/models/showtime_dto.dart';
import '../models/catalog_enums.dart';
import '../models/cinema_dto.dart';
import '../models/food_quote_dto.dart';
import '../models/movie_dto.dart';

abstract interface class CatalogRepository {
  Future<List<MovieDto>> getMovies({MovieStatus? status, String? keyword});

  Future<MovieDto?> getMovie(int movieId);

  Future<List<CinemaDto>> getCinemas();

  Future<List<ShowtimeDto>> getShowtimes({int? movieId, DateTime? date});

  Future<ShowtimeDto?> getShowtime(int showtimeId);

  Future<ShowtimeSeatMapDto> getSeatMap(int showtimeId);

  Future<List<FoodProductDto>> getFoodItems();

  Future<List<FoodProductDto>> getFoodCombos();

  Future<CheckoutQuoteDto> createCheckoutQuote(CheckoutQuoteRequestDto request);
}

class CatalogNotFoundException implements Exception {
  const CatalogNotFoundException(this.message);
  final String message;

  @override
  String toString() => message;
}

class CatalogConflictException implements Exception {
  const CatalogConflictException(this.message);
  final String message;

  @override
  String toString() => message;
}
