import '../../../../core/money/vnd_money.dart';
import '../../data/models/booking_dto.dart';
import '../../data/models/booking_enums.dart';

class TicketOrder {
  const TicketOrder({
    required this.id,
    required this.ticketCode,
    required this.movieId,
    required this.movieTitle,
    required this.moviePoster,
    required this.ageRating,
    required this.format,
    required this.cinemaLocation,
    required this.roomName,
    required this.showtimeAt,
    required this.seats,
    required this.seatsTypeLabel,
    required this.concessionsSummary,
    required this.totalPrice,
    required this.status,
  });

  final int id;
  final String ticketCode;
  final int movieId;
  final String movieTitle;
  final String moviePoster;
  final String ageRating;
  final String format;
  final String cinemaLocation;
  final String roomName;
  final DateTime? showtimeAt;
  final List<String> seats;
  final String seatsTypeLabel;
  final String concessionsSummary;
  final VndMoney totalPrice;
  final BookingStatus status;

  bool get isUpcoming => switch (status) {
    BookingStatus.holding ||
    BookingStatus.pendingPayment ||
    BookingStatus.paid => true,
    _ => false,
  };

  String get statusLabel => switch (status) {
    BookingStatus.holding => 'Đang giữ ghế',
    BookingStatus.pendingPayment => 'Chờ thanh toán',
    BookingStatus.paid => 'Sắp chiếu',
    BookingStatus.used => 'Đã xem',
    BookingStatus.cancelled => 'Đã hủy',
    BookingStatus.expired => 'Đã hết hạn',
    BookingStatus.refunded => 'Đã hoàn tiền',
    BookingStatus.unknown => 'Không xác định',
  };

  String get dateTime {
    final value = showtimeAt;
    if (value == null) return 'Chưa có thời gian';
    return '${_two(value.hour)}:${_two(value.minute)} • ${_two(value.day)}/${_two(value.month)}/${value.year}';
  }
}

TicketOrder mapBookingToOrder(
  BookingDto booking, {
  required String moviePoster,
  required String ageRating,
}) {
  final seatTypes = booking.seats
      .map((seat) => seat.seatType.wireValue)
      .toSet();
  final foods = booking.foods
      .map((food) => '${food.quantity}x ${food.productName}')
      .join(', ');
  final room = booking.roomNameSnapshot ?? booking.roomName ?? 'Phòng chiếu';
  final cinema =
      booking.cinemaNameSnapshot ?? booking.cinemaName ?? 'CineAI Central';
  return TicketOrder(
    id: booking.id,
    ticketCode: booking.bookingCode,
    movieId: booking.movieId,
    movieTitle: booking.movieTitleSnapshot ?? booking.movieTitle ?? 'Phim',
    moviePoster:
        booking.moviePosterSnapshot ?? booking.posterUrl ?? moviePoster,
    ageRating: ageRating,
    format: '2D • Phụ đề',
    cinemaLocation: '$cinema • $room',
    roomName: room,
    showtimeAt: booking.showtimeStartSnapshot ?? booking.showtimeStart,
    seats: booking.seats.map((seat) => seat.seatLabel).toList(growable: false),
    seatsTypeLabel:
        '${booking.seats.length} vé${seatTypes.isEmpty ? '' : ' (${seatTypes.join(', ')})'}',
    concessionsSummary: foods.isEmpty ? 'Không kèm F&B' : foods,
    totalPrice: booking.totalAmount,
    status: booking.status,
  );
}

String _two(int value) => value.toString().padLeft(2, '0');
