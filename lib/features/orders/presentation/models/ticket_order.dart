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
    required this.dateTime,
    required this.seats,
    required this.seatsTypeLabel,
    required this.concessionsSummary,
    required this.totalPrice,
    required this.status,
    required this.statusLabel,
  });

  final String id;
  final String ticketCode;
  final String movieId;
  final String movieTitle;
  final String moviePoster;
  final String ageRating;
  final String format;
  final String cinemaLocation;
  final String roomName;
  final String dateTime;
  final List<String> seats;
  final String seatsTypeLabel;
  final String concessionsSummary;
  final int totalPrice;
  final TicketOrderStatus status;
  final String statusLabel;
}

enum TicketOrderStatus { upcoming, completed }
