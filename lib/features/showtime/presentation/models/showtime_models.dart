class ShowtimeSlot {
  const ShowtimeSlot({
    required this.id,
    required this.time,
    required this.endTime,
    required this.priceDisplay,
    this.isSoldOut = false,
  });

  final String id;
  final String time;
  final String endTime;
  final String priceDisplay;
  final bool isSoldOut;
}

class ShowtimeRoom {
  const ShowtimeRoom({
    required this.id,
    required this.name,
    required this.formatBadge,
    required this.screenDetail,
    required this.slots,
  });

  final String id;
  final String name;
  final String formatBadge;
  final String screenDetail;
  final List<ShowtimeSlot> slots;
}

class MovieShowtime {
  const MovieShowtime({required this.movieId, required this.rooms});

  final String movieId;
  final List<ShowtimeRoom> rooms;
}
