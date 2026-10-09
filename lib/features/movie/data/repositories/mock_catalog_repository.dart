import '../../../../core/demo/demo_scenario.dart';
import '../../../../core/money/vnd_money.dart';
import '../../../showtime/data/models/showtime_dto.dart';
import '../mock/catalog_fixtures.dart';
import '../models/catalog_enums.dart';
import '../models/cinema_dto.dart';
import '../models/food_quote_dto.dart';
import '../models/movie_dto.dart';
import 'catalog_repository.dart';

class MockCatalogRepository implements CatalogRepository {
  MockCatalogRepository({
    required DemoScenario scenario,
    this.delay = Duration.zero,
  }) : _scenario = scenario,
       _fixtures = CatalogFixtures(scenario);

  final DemoScenario _scenario;
  final CatalogFixtures _fixtures;
  final Duration delay;

  Future<void> _wait() => Future<void>.delayed(delay);

  @override
  Future<List<MovieDto>> getMovies({
    MovieStatus? status,
    String? keyword,
  }) async {
    await _wait();
    return _fixtures
        .movies()
        .where((movie) {
          if (status != null && movie.status != status) return false;
          final normalized = keyword?.trim().toLowerCase();
          if (normalized == null || normalized.isEmpty) return true;
          return movie.title.toLowerCase().contains(normalized) ||
              movie.genres.any(
                (genre) => genre.name.toLowerCase().contains(normalized),
              );
        })
        .toList(growable: false);
  }

  @override
  Future<MoviePageDto> getMoviePage({
    MovieStatus? status,
    String? keyword,
    int? genreId,
    int page = 0,
    int size = 20,
  }) async {
    final movies = await getMovies(status: status, keyword: keyword);
    final start = page * size;
    final items = start >= movies.length
        ? <MovieDto>[]
        : movies.skip(start).take(size).toList(growable: false);
    return MoviePageDto(
      items: items,
      page: page,
      size: size,
      totalItems: movies.length,
      totalPages: (movies.length / size).ceil(),
      first: page == 0,
      last: start + items.length >= movies.length,
    );
  }

  @override
  Future<List<GenreDto>> getGenres({int page = 0, int size = 100}) async {
    await _wait();
    final genres = <int, GenreDto>{};
    for (final movie in _fixtures.movies()) {
      for (final genre in movie.genres) {
        genres[genre.id] = genre;
      }
    }
    return genres.values.skip(page * size).take(size).toList(growable: false);
  }

  @override
  Future<MovieDto?> getMovie(int movieId) async {
    await _wait();
    for (final movie in _fixtures.movies()) {
      if (movie.id == movieId) return movie;
    }
    return null;
  }

  @override
  Future<List<CinemaDto>> getCinemas() async {
    await _wait();
    final cinemas = <int, CinemaDto>{};
    for (final showtime in _fixtures.showtimes()) {
      cinemas.putIfAbsent(
        showtime.cinemaId,
        () => CinemaDto(
          id: showtime.cinemaId,
          name: showtime.cinemaName ?? 'Cinema ${showtime.cinemaId}',
          address: '',
          city: '',
          active: true,
        ),
      );
    }
    return cinemas.values.toList(growable: false);
  }

  @override
  Future<List<ShowtimeDto>> getShowtimes({int? movieId, DateTime? date}) async {
    await _wait();
    return _fixtures
        .showtimes()
        .where((showtime) {
          if (movieId != null && showtime.movieId != movieId) return false;
          if (date == null) return true;
          final start = showtime.startTime;
          return start.year == date.year &&
              start.month == date.month &&
              start.day == date.day;
        })
        .toList(growable: false);
  }

  @override
  Future<ShowtimeDto?> getShowtime(int showtimeId) async {
    await _wait();
    for (final showtime in _fixtures.showtimes()) {
      if (showtime.id == showtimeId) return showtime;
    }
    return null;
  }

  @override
  Future<ShowtimeSeatMapDto> getSeatMap(int showtimeId) async {
    await _wait();
    try {
      return _fixtures.seatMap(showtimeId);
    } on StateError {
      throw const CatalogNotFoundException('Không tìm thấy suất chiếu.');
    }
  }

  @override
  Future<List<FoodProductDto>> getFoodItems() async {
    await _wait();
    return _fixtures.foodItems();
  }

  @override
  Future<List<FoodProductDto>> getFoodCombos() async {
    await _wait();
    return _fixtures.foodCombos();
  }

  @override
  Future<CheckoutQuoteDto> createCheckoutQuote(
    CheckoutQuoteRequestDto request,
  ) async {
    await _wait();
    final seatMap = await getSeatMap(request.showtimeId);
    final selectedSeats = seatMap.seats
        .where((seat) => request.seatIds.contains(seat.seatId))
        .toList(growable: false);
    if (selectedSeats.length != request.seatIds.length ||
        selectedSeats.any((seat) => !seat.selectable)) {
      throw const CatalogConflictException('Ghế không còn khả dụng.');
    }

    final requestedTickets = request.tickets.isEmpty
        ? selectedSeats
              .map(
                (seat) => QuoteTicketRequestDto(
                  seatId: seat.seatId,
                  ticketType: TicketType.adult,
                  viewerAge: 30,
                ),
              )
              .toList(growable: false)
        : request.tickets;
    final ticketSeatIds = requestedTickets
        .expand((ticket) => List<int?>.filled(ticket.quantity, ticket.seatId))
        .whereType<int>()
        .toList(growable: false);
    if (ticketSeatIds.length != selectedSeats.length ||
        ticketSeatIds.toSet().length != selectedSeats.length ||
        !request.seatIds.every(ticketSeatIds.contains)) {
      throw const CatalogConflictException(
        'Mỗi ghế phải được gán đúng một loại vé.',
      );
    }

    final products = [..._fixtures.foodItems(), ..._fixtures.foodCombos()];
    final seatSnapshots = selectedSeats
        .map(
          (seat) => QuoteSeatSnapshotDto(
            seatId: seat.seatId,
            seatLabel: '${seat.rowLabel}${seat.seatNumber}',
            seatType: seat.seatType.normalized,
            unitPrice: seat.unitPrice ?? VndMoney.zero,
          ),
        )
        .toList(growable: false);
    final ticketSnapshots = requestedTickets
        .map((ticket) {
          final seat = selectedSeats.firstWhere(
            (item) => item.seatId == ticket.seatId,
          );
          final unitPrice =
              _ticketPrice(
                seatMap.showtime,
                seat.seatType.normalized,
                ticket.ticketType,
              ) ??
              seat.unitPrice ??
              VndMoney.zero;
          return QuoteTicketSnapshotDto(
            seatId: seat.seatId,
            ticketType: ticket.ticketType,
            quantity: ticket.quantity,
            unitPrice: unitPrice,
            lineTotal: unitPrice.multiply(ticket.quantity),
          );
        })
        .toList(growable: false);
    final foodSnapshots = request.foods
        .map((selection) {
          final product = products.firstWhere(
            (item) =>
                item.id == selection.productId &&
                item.isCombo == selection.isCombo,
            orElse: () => throw const CatalogNotFoundException(
              'Không tìm thấy sản phẩm bắp nước.',
            ),
          );
          return QuoteFoodSnapshotDto(
            productId: product.id,
            isCombo: product.isCombo,
            productName: product.name,
            unitPrice: product.price,
            quantity: selection.quantity,
            lineTotal: product.price.multiply(selection.quantity),
          );
        })
        .toList(growable: false);

    final ticketSubtotal = ticketSnapshots.fold(
      VndMoney.zero,
      (total, ticket) => total + ticket.lineTotal,
    );
    final foodSubtotal = foodSnapshots.fold(
      VndMoney.zero,
      (total, food) => total + food.lineTotal,
    );
    final subtotal = ticketSubtotal + foodSubtotal;
    final showtime = seatMap.showtime;
    final movie = await getMovie(showtime.movieId);
    return CheckoutQuoteDto(
      quoteId: 'mock-quote-${request.showtimeId}',
      validUntil: _scenario.clock.now().add(const Duration(minutes: 3)),
      showtime: QuoteShowtimeSnapshotDto(
        showtimeId: showtime.id,
        movieId: showtime.movieId,
        movieTitle: showtime.movieTitle,
        cinemaName: showtime.cinemaName,
        roomName: showtime.roomName,
        startTime: showtime.startTime,
      ),
      seats: seatSnapshots,
      tickets: ticketSnapshots,
      foods: foodSnapshots,
      foodItems: foodSnapshots,
      ticketSubtotal: ticketSubtotal,
      foodSubtotal: foodSubtotal,
      subtotal: subtotal,
      discount: VndMoney.zero,
      cinePointsDiscount: VndMoney.zero,
      fees: VndMoney.zero,
      tax: VndMoney.zero,
      total: subtotal,
      movie: QuoteMovieSummaryDto(
        id: showtime.movieId,
        title: showtime.movieTitle ?? movie?.title ?? '',
        posterUrl: movie?.posterUrl,
        ageRating: movie?.ageRating,
        durationMinutes: movie?.durationMinutes,
      ),
      cinema: QuoteCinemaSummaryDto(
        id: showtime.cinemaId,
        name: showtime.cinemaName ?? '',
        roomName: showtime.roomName,
      ),
    );
  }
}

VndMoney? _ticketPrice(
  ShowtimeDto showtime,
  CatalogSeatType seatType,
  TicketType ticketType,
) => switch ((ticketType, seatType)) {
  (TicketType.adult, CatalogSeatType.standard) => showtime.adultStandardPrice,
  (TicketType.child, CatalogSeatType.standard) => showtime.childStandardPrice,
  (TicketType.student, CatalogSeatType.standard) =>
    showtime.studentStandardPrice,
  (TicketType.adult, CatalogSeatType.vip) => showtime.adultVipPrice,
  (TicketType.child, CatalogSeatType.vip) => showtime.childVipPrice,
  (TicketType.student, CatalogSeatType.vip) => showtime.studentVipPrice,
  (TicketType.adult, CatalogSeatType.couple) => showtime.adultCouplePrice,
  (TicketType.child, CatalogSeatType.couple) => showtime.childCouplePrice,
  (TicketType.student, CatalogSeatType.couple) => showtime.studentCouplePrice,
  _ => null,
};
