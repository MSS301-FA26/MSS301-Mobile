import '../../../../core/contracts/json_parsers.dart';
import '../../../../core/money/vnd_money.dart';
import '../../../movie/data/models/catalog_enums.dart';
import 'booking_enums.dart';

class TicketSelectionDto {
  const TicketSelectionDto({
    required this.seatId,
    this.ticketType = TicketType.adult,
    this.viewerAge,
    this.quantity = 1,
  });

  final int seatId;
  final TicketType ticketType;
  final int? viewerAge;
  final int quantity;
}

class FoodSelectionDto {
  const FoodSelectionDto({
    required this.productId,
    required this.isCombo,
    this.quantity = 1,
  });

  final int productId;
  final bool isCombo;
  final int quantity;
}

class HoldSeatsRequestDto {
  const HoldSeatsRequestDto({
    required this.showtimeId,
    required this.seatIds,
    this.holiday,
    this.tickets = const [],
    this.foods = const [],
    this.loyaltyPointsToRedeem,
  });

  final int showtimeId;
  final List<int> seatIds;
  final bool? holiday;
  final List<TicketSelectionDto> tickets;
  final List<FoodSelectionDto> foods;
  final int? loyaltyPointsToRedeem;
}

class UpdateHoldingBookingRequestDto {
  const UpdateHoldingBookingRequestDto({
    this.tickets = const [],
    this.foods = const [],
    this.loyaltyPointsToRedeem,
  });

  final List<TicketSelectionDto> tickets;
  final List<FoodSelectionDto> foods;
  final int? loyaltyPointsToRedeem;
}

class BookingSeatDto {
  const BookingSeatDto({
    required this.id,
    required this.seatId,
    required this.showtimeId,
    required this.rowLabel,
    required this.seatNumber,
    required this.seatLabel,
    required this.seatType,
    required this.unitPrice,
    required this.status,
    required this.ticketType,
    this.ticketCode,
    this.qrCode,
    this.checkedInAt,
  });

  final int id;
  final int seatId;
  final int showtimeId;
  final String rowLabel;
  final int seatNumber;
  final String seatLabel;
  final BookingSeatType seatType;
  final VndMoney unitPrice;
  final BookingSeatStatus status;
  final String? ticketCode;
  final String? qrCode;
  final TicketType ticketType;
  final DateTime? checkedInAt;

  factory BookingSeatDto.fromJson(Map<String, Object?> json) => BookingSeatDto(
    id: intFromJson(json['id']),
    seatId: intFromJson(json['seatId']),
    showtimeId: intFromJson(json['showtimeId']),
    rowLabel: json['rowLabel']?.toString() ?? '',
    seatNumber: intFromJson(json['seatNumber'] ?? 0),
    seatLabel: json['seatLabel']?.toString() ?? '',
    seatType: BookingSeatType.parse(json['seatType']),
    unitPrice: VndMoney.fromJson(json['unitPrice']),
    status: BookingSeatStatus.parse(json['status']),
    ticketCode: json['ticketCode']?.toString(),
    qrCode: json['qrCode']?.toString(),
    ticketType: TicketType.parse(json['ticketType']),
    checkedInAt: nullableDateTimeFromJson(json['checkedInAt']),
  );

  BookingSeatDto copyWith({BookingSeatStatus? status}) => BookingSeatDto(
    id: id,
    seatId: seatId,
    showtimeId: showtimeId,
    rowLabel: rowLabel,
    seatNumber: seatNumber,
    seatLabel: seatLabel,
    seatType: seatType,
    unitPrice: unitPrice,
    status: status ?? this.status,
    ticketCode: ticketCode,
    qrCode: qrCode,
    ticketType: ticketType,
    checkedInAt: checkedInAt,
  );
}

class BookingTicketDto {
  const BookingTicketDto({
    required this.id,
    required this.seatId,
    required this.ticketType,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.viewerAge,
  });

  final int id;
  final int seatId;
  final TicketType ticketType;
  final int? viewerAge;
  final int quantity;
  final VndMoney unitPrice;
  final VndMoney lineTotal;

  factory BookingTicketDto.fromJson(Map<String, Object?> json) =>
      BookingTicketDto(
        id: intFromJson(json['id']),
        seatId: intFromJson(json['seatId']),
        ticketType: TicketType.parse(json['ticketType']),
        viewerAge: nullableIntFromJson(json['viewerAge']),
        quantity: intFromJson(json['quantity'] ?? 0),
        unitPrice: VndMoney.fromJson(json['unitPrice']),
        lineTotal: VndMoney.fromJson(json['lineTotal']),
      );
}

class BookingFoodDto {
  const BookingFoodDto({
    required this.id,
    required this.productId,
    required this.isCombo,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final int id;
  final int productId;
  final bool isCombo;
  final String productName;
  final int quantity;
  final VndMoney unitPrice;
  final VndMoney lineTotal;

  factory BookingFoodDto.fromJson(Map<String, Object?> json) => BookingFoodDto(
    id: intFromJson(json['id']),
    productId: intFromJson(json['productId']),
    isCombo: boolFromJson(json['isCombo']),
    productName: json['productName']?.toString() ?? '',
    quantity: intFromJson(json['quantity'] ?? 0),
    unitPrice: VndMoney.fromJson(json['unitPrice']),
    lineTotal: VndMoney.fromJson(json['lineTotal']),
  );
}

class BookingDto {
  const BookingDto({
    required this.id,
    required this.bookingCode,
    required this.userId,
    required this.showtimeId,
    required this.movieId,
    required this.subtotal,
    required this.discountAmount,
    required this.loyaltyPointsRedeemed,
    required this.totalAmount,
    required this.status,
    required this.seats,
    required this.tickets,
    required this.foods,
    required this.createdAt,
    this.movieTitle,
    this.movieTitleSnapshot,
    this.posterUrl,
    this.moviePosterSnapshot,
    this.cinemaName,
    this.cinemaNameSnapshot,
    this.roomName,
    this.roomNameSnapshot,
    this.showtimeStart,
    this.showtimeStartSnapshot,
    this.holdExpiresAt,
    this.paidAt,
    this.checkedInAt,
    this.cancelledAt,
    this.refundedAt,
    this.qrCode,
  });

  final int id;
  final String bookingCode;
  final int userId;
  final int showtimeId;
  final int movieId;
  final String? movieTitle;
  final String? movieTitleSnapshot;
  final String? posterUrl;
  final String? moviePosterSnapshot;
  final String? cinemaName;
  final String? cinemaNameSnapshot;
  final String? roomName;
  final String? roomNameSnapshot;
  final DateTime? showtimeStart;
  final DateTime? showtimeStartSnapshot;
  final VndMoney subtotal;
  final VndMoney discountAmount;
  final int loyaltyPointsRedeemed;
  final VndMoney totalAmount;
  final BookingStatus status;
  final DateTime? holdExpiresAt;
  final DateTime? paidAt;
  final DateTime? checkedInAt;
  final DateTime? cancelledAt;
  final DateTime? refundedAt;
  final String? qrCode;
  final List<BookingSeatDto> seats;
  final List<BookingTicketDto> tickets;
  final List<BookingFoodDto> foods;
  final DateTime createdAt;

  factory BookingDto.fromJson(Map<String, Object?> json) => BookingDto(
    id: intFromJson(json['id']),
    bookingCode: json['bookingCode']?.toString() ?? '',
    userId: intFromJson(json['userId']),
    showtimeId: intFromJson(json['showtimeId']),
    movieId: intFromJson(json['movieId']),
    movieTitle: json['movieTitle']?.toString(),
    movieTitleSnapshot: json['movieTitleSnapshot']?.toString(),
    posterUrl: json['posterUrl']?.toString(),
    moviePosterSnapshot: json['moviePosterSnapshot']?.toString(),
    cinemaName: json['cinemaName']?.toString(),
    cinemaNameSnapshot: json['cinemaNameSnapshot']?.toString(),
    roomName: json['roomName']?.toString(),
    roomNameSnapshot: json['roomNameSnapshot']?.toString(),
    showtimeStart: nullableDateTimeFromJson(json['showtimeStart']),
    showtimeStartSnapshot: nullableDateTimeFromJson(
      json['showtimeStartSnapshot'],
    ),
    subtotal: VndMoney.fromJson(json['subtotal']),
    discountAmount: VndMoney.fromJson(json['discountAmount']),
    loyaltyPointsRedeemed: intFromJson(json['loyaltyPointsRedeemed'] ?? 0),
    totalAmount: VndMoney.fromJson(json['totalAmount']),
    status: BookingStatus.parse(json['status']),
    holdExpiresAt: nullableDateTimeFromJson(json['holdExpiresAt']),
    paidAt: nullableDateTimeFromJson(json['paidAt']),
    checkedInAt: nullableDateTimeFromJson(json['checkedInAt']),
    cancelledAt: nullableDateTimeFromJson(json['cancelledAt']),
    refundedAt: nullableDateTimeFromJson(json['refundedAt']),
    qrCode: json['qrCode']?.toString(),
    seats: listFromJson(json['seats'], BookingSeatDto.fromJson),
    tickets: listFromJson(json['tickets'], BookingTicketDto.fromJson),
    foods: listFromJson(json['foods'], BookingFoodDto.fromJson),
    createdAt: dateTimeFromJson(json['createdAt']),
  );

  BookingDto copyWith({
    BookingStatus? status,
    DateTime? holdExpiresAt,
    DateTime? paidAt,
    DateTime? cancelledAt,
    String? qrCode,
    VndMoney? subtotal,
    VndMoney? totalAmount,
    int? loyaltyPointsRedeemed,
    List<BookingSeatDto>? seats,
    List<BookingTicketDto>? tickets,
    List<BookingFoodDto>? foods,
  }) => BookingDto(
    id: id,
    bookingCode: bookingCode,
    userId: userId,
    showtimeId: showtimeId,
    movieId: movieId,
    movieTitle: movieTitle,
    movieTitleSnapshot: movieTitleSnapshot,
    posterUrl: posterUrl,
    moviePosterSnapshot: moviePosterSnapshot,
    cinemaName: cinemaName,
    cinemaNameSnapshot: cinemaNameSnapshot,
    roomName: roomName,
    roomNameSnapshot: roomNameSnapshot,
    showtimeStart: showtimeStart,
    showtimeStartSnapshot: showtimeStartSnapshot,
    subtotal: subtotal ?? this.subtotal,
    discountAmount: discountAmount,
    loyaltyPointsRedeemed: loyaltyPointsRedeemed ?? this.loyaltyPointsRedeemed,
    totalAmount: totalAmount ?? this.totalAmount,
    status: status ?? this.status,
    holdExpiresAt: holdExpiresAt ?? this.holdExpiresAt,
    paidAt: paidAt ?? this.paidAt,
    checkedInAt: checkedInAt,
    cancelledAt: cancelledAt ?? this.cancelledAt,
    refundedAt: refundedAt,
    qrCode: qrCode ?? this.qrCode,
    seats: seats ?? this.seats,
    tickets: tickets ?? this.tickets,
    foods: foods ?? this.foods,
    createdAt: createdAt,
  );
}
