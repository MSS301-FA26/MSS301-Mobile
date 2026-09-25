import '../../../../core/demo/demo_scenario.dart';
import '../../../../core/money/vnd_money.dart';
import '../../../showtime/data/models/showtime_dto.dart';
import '../models/catalog_enums.dart';
import '../models/food_quote_dto.dart';
import '../models/movie_dto.dart';

class CatalogFixtures {
  CatalogFixtures(this.scenario);

  final DemoScenario scenario;

  List<MovieDto> movies() => [
    MovieDto(
      id: DemoIds.movieInception,
      title: 'Inception',
      description: 'Một phi vụ diễn ra bên trong nhiều tầng giấc mơ.',
      trailerUrl: 'mock://trailers/inception',
      posterUrl: 'assets/mock/movies/inception-poster.jpg',
      avatarUrl: 'assets/mock/movies/inception-poster.jpg',
      durationMinutes: 148,
      releaseDate: scenario.clock.now().subtract(const Duration(days: 7)),
      endDate: scenario.clock.now().add(const Duration(days: 30)),
      language: 'Tiếng Anh',
      subtitleLanguage: 'Tiếng Việt',
      status: MovieStatus.nowShowing,
      ageRating: '16+',
      director: 'Christopher Nolan',
      mainActors: 'Leonardo DiCaprio',
      castList: 'Leonardo DiCaprio, Joseph Gordon-Levitt',
      genres: const [GenreDto(id: 1, name: 'Khoa học viễn tưởng')],
      actors: const [ActorDto(id: 1, name: 'Leonardo DiCaprio', movieCount: 1)],
      mainActorIds: const [1],
    ),
    MovieDto(
      id: DemoIds.movieAvengers,
      title: 'Avengers: Endgame',
      description: 'Các Avengers tập hợp cho trận chiến cuối cùng.',
      posterUrl: 'assets/mock/movies/avengers-endgame-poster.jpg',
      avatarUrl: 'assets/mock/movies/avengers-endgame-poster.jpg',
      durationMinutes: 181,
      releaseDate: scenario.clock.now().subtract(const Duration(days: 3)),
      endDate: scenario.clock.now().add(const Duration(days: 27)),
      language: 'Tiếng Anh',
      subtitleLanguage: 'Tiếng Việt',
      status: MovieStatus.nowShowing,
      ageRating: '13+',
      director: 'Anthony Russo, Joe Russo',
      mainActors: 'Robert Downey Jr.',
      castList: 'Robert Downey Jr., Chris Evans',
      genres: const [GenreDto(id: 2, name: 'Hành động')],
      actors: const [ActorDto(id: 2, name: 'Robert Downey Jr.', movieCount: 1)],
      mainActorIds: const [2],
    ),
  ];

  List<ShowtimeDto> showtimes() => [
    ShowtimeDto(
      id: DemoIds.showtimeInception,
      movieId: DemoIds.movieInception,
      movieTitle: 'Inception',
      movieAgeRating: '16+',
      movieGenreNames: const ['Khoa học viễn tưởng'],
      cinemaId: DemoIds.cinemaCentral,
      cinemaName: 'CineAI Central',
      roomId: DemoIds.roomC,
      roomName: 'Phòng C',
      startTime: scenario.showtimeStart,
      endTime: scenario.showtimeEnd,
      basePrice: const VndMoney(90000),
      vipPrice: const VndMoney(90000),
      couplePrice: const VndMoney(180000),
      adultStandardPrice: const VndMoney(90000),
      childStandardPrice: const VndMoney(70000),
      studentStandardPrice: const VndMoney(80000),
      adultVipPrice: const VndMoney(110000),
      childVipPrice: const VndMoney(90000),
      studentVipPrice: const VndMoney(100000),
      adultCouplePrice: const VndMoney(180000),
      childCouplePrice: const VndMoney(150000),
      studentCouplePrice: const VndMoney(170000),
      weekendSurcharge: false,
      holidaySurcharge: false,
      lateNightSurchargeAmount: VndMoney.zero,
      surchargeAmount: VndMoney.zero,
      status: ShowtimeStatus.open,
    ),
  ];

  ShowtimeSeatMapDto seatMap() {
    final showtime = showtimes().single;
    return ShowtimeSeatMapDto(
      showtime: showtime,
      rowCount: 3,
      columnCount: 6,
      seats: [
        ShowtimeSeatDto(
          seatId: DemoIds.seatC4,
          seatRowId: 303,
          rowLabel: 'C',
          displayOrder: 4,
          seatNumber: 4,
          displayColumn: 4,
          startColumn: 4,
          seatType: CatalogSeatType.vip,
          seatStatus: SeatStatus.available,
          runtimeStatus: SeatRuntimeStatus.available,
          unitPrice: const VndMoney(90000),
        ),
        ShowtimeSeatDto(
          seatId: DemoIds.seatC5,
          seatRowId: 303,
          rowLabel: 'C',
          displayOrder: 5,
          seatNumber: 5,
          displayColumn: 5,
          startColumn: 5,
          seatType: CatalogSeatType.vip,
          seatStatus: SeatStatus.available,
          runtimeStatus: SeatRuntimeStatus.available,
          unitPrice: const VndMoney(90000),
        ),
        const ShowtimeSeatDto(
          seatId: 3006,
          seatRowId: 303,
          rowLabel: 'C',
          displayOrder: 6,
          seatNumber: 6,
          displayColumn: 6,
          startColumn: 6,
          seatType: CatalogSeatType.normal,
          seatStatus: SeatStatus.maintenance,
          runtimeStatus: SeatRuntimeStatus.unknown,
          unitPrice: VndMoney(90000),
        ),
      ],
    );
  }

  List<FoodProductDto> foodItems() => const [
    FoodProductDto(
      id: 4001,
      name: 'Bắp rang caramel',
      price: VndMoney(59000),
      status: FoodItemStatus.active,
      isCombo: false,
    ),
  ];

  List<FoodProductDto> foodCombos() => const [
    FoodProductDto(
      id: 4101,
      name: 'Combo Couple',
      price: VndMoney(89000),
      status: FoodItemStatus.active,
      isCombo: true,
    ),
  ];
}
