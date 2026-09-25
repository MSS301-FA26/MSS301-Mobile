import '../../../../core/contracts/json_parsers.dart';
import '../../../../core/money/vnd_money.dart';
import 'catalog_enums.dart';

class FoodProductDto {
  const FoodProductDto({
    required this.id,
    required this.name,
    required this.price,
    required this.status,
    required this.isCombo,
    this.description,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String? description;
  final VndMoney price;
  final String? imageUrl;
  final FoodItemStatus status;
  final bool isCombo;

  factory FoodProductDto.fromJson(
    Map<String, Object?> json, {
    required bool isCombo,
  }) => FoodProductDto(
    id: intFromJson(json['id'], field: 'food.id'),
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString(),
    price: VndMoney.fromJson(json['price'], field: 'food.price'),
    imageUrl: json['imageUrl']?.toString(),
    status: FoodItemStatus.parse(json['status']),
    isCombo: isCombo,
  );
}

class QuoteTicketRequestDto {
  const QuoteTicketRequestDto({
    this.seatId,
    this.ticketType = TicketType.adult,
    this.viewerAge = 22,
    this.quantity = 1,
  });

  final int? seatId;
  final TicketType ticketType;
  final int viewerAge;
  final int quantity;
}

class QuoteFoodRequestDto {
  const QuoteFoodRequestDto({
    required this.productId,
    required this.isCombo,
    this.quantity = 1,
  });

  final int productId;
  final bool isCombo;
  final int quantity;
}

class CheckoutQuoteRequestDto {
  const CheckoutQuoteRequestDto({
    required this.showtimeId,
    required this.seatIds,
    this.tickets = const [],
    this.foods = const [],
    this.voucherCode,
    this.cinePointsToUse,
    this.bookingSessionId,
  });

  final int showtimeId;
  final List<int> seatIds;
  final List<QuoteTicketRequestDto> tickets;
  final List<QuoteFoodRequestDto> foods;
  final String? voucherCode;
  final int? cinePointsToUse;
  final int? bookingSessionId;
}

class QuoteShowtimeSnapshotDto {
  const QuoteShowtimeSnapshotDto({
    required this.showtimeId,
    required this.movieId,
    required this.startTime,
    this.movieTitle,
    this.posterUrl,
    this.cinemaName,
    this.roomName,
  });

  final int showtimeId;
  final int movieId;
  final String? movieTitle;
  final String? posterUrl;
  final String? cinemaName;
  final String? roomName;
  final DateTime startTime;

  factory QuoteShowtimeSnapshotDto.fromJson(Map<String, Object?> json) =>
      QuoteShowtimeSnapshotDto(
        showtimeId: intFromJson(json['showtimeId']),
        movieId: intFromJson(json['movieId']),
        movieTitle: json['movieTitle']?.toString(),
        posterUrl: json['posterUrl']?.toString(),
        cinemaName: json['cinemaName']?.toString(),
        roomName: json['roomName']?.toString(),
        startTime: dateTimeFromJson(json['startTime']),
      );
}

class QuoteSeatSnapshotDto {
  const QuoteSeatSnapshotDto({
    required this.seatId,
    required this.seatLabel,
    required this.seatType,
    required this.unitPrice,
  });

  final int seatId;
  final String seatLabel;
  final CatalogSeatType seatType;
  final VndMoney unitPrice;

  factory QuoteSeatSnapshotDto.fromJson(Map<String, Object?> json) =>
      QuoteSeatSnapshotDto(
        seatId: intFromJson(json['seatId']),
        seatLabel: json['seatLabel']?.toString() ?? '',
        seatType: CatalogSeatType.parse(json['seatType']),
        unitPrice: VndMoney.fromJson(json['unitPrice']),
      );
}

class QuoteTicketSnapshotDto {
  const QuoteTicketSnapshotDto({
    required this.seatId,
    required this.ticketType,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final int seatId;
  final TicketType ticketType;
  final int quantity;
  final VndMoney unitPrice;
  final VndMoney lineTotal;

  factory QuoteTicketSnapshotDto.fromJson(Map<String, Object?> json) =>
      QuoteTicketSnapshotDto(
        seatId: intFromJson(json['seatId']),
        ticketType: TicketType.parse(json['ticketType']),
        quantity: intFromJson(json['quantity'] ?? 0),
        unitPrice: VndMoney.fromJson(json['unitPrice']),
        lineTotal: VndMoney.fromJson(json['lineTotal']),
      );
}

class QuoteFoodSnapshotDto {
  const QuoteFoodSnapshotDto({
    required this.productId,
    required this.isCombo,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  final int productId;
  final bool isCombo;
  final String productName;
  final VndMoney unitPrice;
  final int quantity;
  final VndMoney lineTotal;

  factory QuoteFoodSnapshotDto.fromJson(Map<String, Object?> json) =>
      QuoteFoodSnapshotDto(
        productId: intFromJson(json['productId']),
        isCombo: boolFromJson(json['isCombo']),
        productName: json['productName']?.toString() ?? '',
        unitPrice: VndMoney.fromJson(json['unitPrice']),
        quantity: intFromJson(json['quantity'] ?? 0),
        lineTotal: VndMoney.fromJson(json['lineTotal']),
      );
}

class QuoteMovieSummaryDto {
  const QuoteMovieSummaryDto({
    required this.id,
    required this.title,
    this.posterUrl,
    this.ageRating,
    this.durationMinutes,
  });

  final int id;
  final String title;
  final String? posterUrl;
  final String? ageRating;
  final int? durationMinutes;

  factory QuoteMovieSummaryDto.fromJson(Map<String, Object?> json) =>
      QuoteMovieSummaryDto(
        id: intFromJson(json['id']),
        title: json['title']?.toString() ?? '',
        posterUrl: json['posterUrl']?.toString(),
        ageRating: json['ageRating']?.toString(),
        durationMinutes: nullableIntFromJson(json['durationMinutes']),
      );
}

class QuoteCinemaSummaryDto {
  const QuoteCinemaSummaryDto({
    this.id,
    required this.name,
    this.address,
    this.roomName,
  });

  final int? id;
  final String name;
  final String? address;
  final String? roomName;

  factory QuoteCinemaSummaryDto.fromJson(Map<String, Object?> json) =>
      QuoteCinemaSummaryDto(
        id: nullableIntFromJson(json['id']),
        name: json['name']?.toString() ?? '',
        address: json['address']?.toString(),
        roomName: json['roomName']?.toString(),
      );
}

class CheckoutQuoteDto {
  const CheckoutQuoteDto({
    required this.quoteId,
    required this.validUntil,
    required this.showtime,
    required this.seats,
    required this.tickets,
    required this.foods,
    required this.foodItems,
    required this.ticketSubtotal,
    required this.foodSubtotal,
    required this.subtotal,
    required this.discount,
    required this.cinePointsDiscount,
    required this.fees,
    required this.tax,
    required this.total,
    this.voucherMessage,
    this.movie,
    this.cinema,
  });

  final String quoteId;
  final DateTime validUntil;
  final QuoteShowtimeSnapshotDto showtime;
  final List<QuoteSeatSnapshotDto> seats;
  final List<QuoteTicketSnapshotDto> tickets;
  final List<QuoteFoodSnapshotDto> foods;
  final List<QuoteFoodSnapshotDto> foodItems;
  final VndMoney ticketSubtotal;
  final VndMoney foodSubtotal;
  final VndMoney subtotal;
  final VndMoney discount;
  final VndMoney cinePointsDiscount;
  final VndMoney fees;
  final VndMoney tax;
  final VndMoney total;
  final String? voucherMessage;
  final QuoteMovieSummaryDto? movie;
  final QuoteCinemaSummaryDto? cinema;

  factory CheckoutQuoteDto.fromJson(Map<String, Object?> json) =>
      CheckoutQuoteDto(
        quoteId: json['quoteId']?.toString() ?? '',
        validUntil: dateTimeFromJson(json['validUntil']),
        showtime: QuoteShowtimeSnapshotDto.fromJson(
          Map<String, Object?>.from(json['showtime']! as Map),
        ),
        seats: listFromJson(json['seats'], QuoteSeatSnapshotDto.fromJson),
        tickets: listFromJson(json['tickets'], QuoteTicketSnapshotDto.fromJson),
        foods: listFromJson(json['foods'], QuoteFoodSnapshotDto.fromJson),
        foodItems: listFromJson(
          json['foodItems'],
          QuoteFoodSnapshotDto.fromJson,
        ),
        ticketSubtotal: VndMoney.fromJson(json['ticketSubtotal']),
        foodSubtotal: VndMoney.fromJson(json['foodSubtotal']),
        subtotal: VndMoney.fromJson(json['subtotal']),
        discount: VndMoney.fromJson(json['discount']),
        cinePointsDiscount: VndMoney.fromJson(json['cinePointsDiscount']),
        fees: VndMoney.fromJson(json['fees']),
        tax: VndMoney.fromJson(json['tax']),
        total: VndMoney.fromJson(json['total']),
        voucherMessage: json['voucherMessage']?.toString(),
        movie: json['movie'] == null
            ? null
            : QuoteMovieSummaryDto.fromJson(
                Map<String, Object?>.from(json['movie']! as Map),
              ),
        cinema: json['cinema'] == null
            ? null
            : QuoteCinemaSummaryDto.fromJson(
                Map<String, Object?>.from(json['cinema']! as Map),
              ),
      );
}
