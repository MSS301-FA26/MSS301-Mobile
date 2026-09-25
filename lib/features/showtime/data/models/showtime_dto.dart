import '../../../../core/contracts/json_parsers.dart';
import '../../../../core/money/vnd_money.dart';
import '../../../movie/data/models/catalog_enums.dart';

VndMoney? _money(Object? value, String field) =>
    value == null ? null : VndMoney.fromJson(value, field: field);

class ShowtimeDto {
  const ShowtimeDto({
    required this.id,
    required this.movieId,
    required this.cinemaId,
    required this.roomId,
    required this.startTime,
    required this.endTime,
    required this.movieGenreNames,
    required this.weekendSurcharge,
    required this.holidaySurcharge,
    required this.status,
    this.movieTitle,
    this.movieAgeRating,
    this.cinemaName,
    this.roomName,
    this.basePrice,
    this.vipPrice,
    this.couplePrice,
    this.adultStandardPrice,
    this.childStandardPrice,
    this.studentStandardPrice,
    this.adultVipPrice,
    this.childVipPrice,
    this.studentVipPrice,
    this.adultCouplePrice,
    this.childCouplePrice,
    this.studentCouplePrice,
    this.lateNightSurchargeAmount,
    this.surchargeAmount,
    this.cancellationReason,
    this.cancelledAt,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int movieId;
  final String? movieTitle;
  final String? movieAgeRating;
  final List<String> movieGenreNames;
  final int cinemaId;
  final String? cinemaName;
  final int roomId;
  final String? roomName;
  final DateTime startTime;
  final DateTime endTime;
  final VndMoney? basePrice;
  final VndMoney? vipPrice;
  final VndMoney? couplePrice;
  final VndMoney? adultStandardPrice;
  final VndMoney? childStandardPrice;
  final VndMoney? studentStandardPrice;
  final VndMoney? adultVipPrice;
  final VndMoney? childVipPrice;
  final VndMoney? studentVipPrice;
  final VndMoney? adultCouplePrice;
  final VndMoney? childCouplePrice;
  final VndMoney? studentCouplePrice;
  final bool weekendSurcharge;
  final bool holidaySurcharge;
  final VndMoney? lateNightSurchargeAmount;
  final VndMoney? surchargeAmount;
  final ShowtimeStatus status;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ShowtimeDto.fromJson(Map<String, Object?> json) => ShowtimeDto(
    id: intFromJson(json['id'], field: 'showtime.id'),
    movieId: intFromJson(json['movieId'], field: 'showtime.movieId'),
    movieTitle: json['movieTitle']?.toString(),
    movieAgeRating: json['movieAgeRating']?.toString(),
    movieGenreNames: stringListFromJson(json['movieGenreNames']),
    cinemaId: intFromJson(json['cinemaId'], field: 'showtime.cinemaId'),
    cinemaName: json['cinemaName']?.toString(),
    roomId: intFromJson(json['roomId'], field: 'showtime.roomId'),
    roomName: json['roomName']?.toString(),
    startTime: dateTimeFromJson(json['startTime'], field: 'startTime'),
    endTime: dateTimeFromJson(json['endTime'], field: 'endTime'),
    basePrice: _money(json['basePrice'], 'basePrice'),
    vipPrice: _money(json['vipPrice'], 'vipPrice'),
    couplePrice: _money(json['couplePrice'], 'couplePrice'),
    adultStandardPrice: _money(
      json['adultStandardPrice'],
      'adultStandardPrice',
    ),
    childStandardPrice: _money(
      json['childStandardPrice'],
      'childStandardPrice',
    ),
    studentStandardPrice: _money(
      json['studentStandardPrice'],
      'studentStandardPrice',
    ),
    adultVipPrice: _money(json['adultVipPrice'], 'adultVipPrice'),
    childVipPrice: _money(json['childVipPrice'], 'childVipPrice'),
    studentVipPrice: _money(json['studentVipPrice'], 'studentVipPrice'),
    adultCouplePrice: _money(json['adultCouplePrice'], 'adultCouplePrice'),
    childCouplePrice: _money(json['childCouplePrice'], 'childCouplePrice'),
    studentCouplePrice: _money(
      json['studentCouplePrice'],
      'studentCouplePrice',
    ),
    weekendSurcharge: boolFromJson(json['weekendSurcharge']),
    holidaySurcharge: boolFromJson(json['holidaySurcharge']),
    lateNightSurchargeAmount: _money(
      json['lateNightSurchargeAmount'],
      'lateNightSurchargeAmount',
    ),
    surchargeAmount: _money(json['surchargeAmount'], 'surchargeAmount'),
    status: ShowtimeStatus.parse(json['status']),
    cancellationReason: json['cancellationReason']?.toString(),
    cancelledAt: nullableDateTimeFromJson(json['cancelledAt']),
    createdAt: nullableDateTimeFromJson(json['createdAt']),
    updatedAt: nullableDateTimeFromJson(json['updatedAt']),
  );
}

class ShowtimeSeatDto {
  const ShowtimeSeatDto({
    required this.seatId,
    required this.seatRowId,
    required this.rowLabel,
    required this.displayOrder,
    required this.seatNumber,
    required this.displayColumn,
    required this.startColumn,
    required this.seatType,
    required this.seatStatus,
    required this.runtimeStatus,
    this.holdExpiresAt,
    this.unitPrice,
  });

  final int seatId;
  final int seatRowId;
  final String rowLabel;
  final int displayOrder;
  final int seatNumber;
  final int displayColumn;
  final int startColumn;
  final CatalogSeatType seatType;
  final SeatStatus seatStatus;
  final SeatRuntimeStatus runtimeStatus;
  final DateTime? holdExpiresAt;
  final VndMoney? unitPrice;

  bool get selectable =>
      seatStatus == SeatStatus.available &&
      runtimeStatus == SeatRuntimeStatus.available;

  factory ShowtimeSeatDto.fromJson(Map<String, Object?> json) =>
      ShowtimeSeatDto(
        seatId: intFromJson(json['seatId'], field: 'seatId'),
        seatRowId: intFromJson(json['seatRowId'], field: 'seatRowId'),
        rowLabel: json['rowLabel']?.toString() ?? '',
        displayOrder: intFromJson(json['displayOrder'] ?? 0),
        seatNumber: intFromJson(json['seatNumber'] ?? 0),
        displayColumn: intFromJson(json['displayColumn'] ?? 0),
        startColumn: intFromJson(json['startColumn'] ?? 0),
        seatType: CatalogSeatType.parse(json['seatType']),
        seatStatus: SeatStatus.parse(json['seatStatus']),
        runtimeStatus: SeatRuntimeStatus.parse(json['runtimeStatus']),
        holdExpiresAt: nullableDateTimeFromJson(json['holdExpiresAt']),
        unitPrice: _money(json['unitPrice'], 'unitPrice'),
      );
}

class ShowtimeSeatMapDto {
  const ShowtimeSeatMapDto({
    required this.showtime,
    required this.rowCount,
    required this.columnCount,
    required this.seats,
  });

  final ShowtimeDto showtime;
  final int rowCount;
  final int columnCount;
  final List<ShowtimeSeatDto> seats;

  factory ShowtimeSeatMapDto.fromJson(Map<String, Object?> json) =>
      ShowtimeSeatMapDto(
        showtime: ShowtimeDto.fromJson(
          Map<String, Object?>.from(json['showtime']! as Map),
        ),
        rowCount: intFromJson(json['rowCount'] ?? 0),
        columnCount: intFromJson(json['columnCount'] ?? 0),
        seats: listFromJson(json['seats'], ShowtimeSeatDto.fromJson),
      );
}
