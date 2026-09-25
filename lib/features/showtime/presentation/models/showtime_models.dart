import '../../../../core/money/vnd_money.dart';
import '../../../movie/data/models/catalog_enums.dart';
import '../../data/models/showtime_dto.dart';

class ShowtimeSlot {
  const ShowtimeSlot({
    required this.id,
    required this.startAt,
    required this.endAt,
    required this.price,
    required this.status,
  });

  final int id;
  final DateTime startAt;
  final DateTime endAt;
  final VndMoney price;
  final ShowtimeStatus status;

  bool get isSoldOut => status != ShowtimeStatus.open;
  String get time => _time(startAt);
  String get endTime => '~${_time(endAt)}';
  String get priceDisplay => price.format();
}

class ShowtimeRoom {
  const ShowtimeRoom({
    required this.id,
    required this.name,
    required this.formatBadge,
    required this.screenDetail,
    required this.slots,
  });

  final int id;
  final String name;
  final String formatBadge;
  final String screenDetail;
  final List<ShowtimeSlot> slots;
}

class MovieShowtime {
  const MovieShowtime({required this.movieId, required this.rooms});

  final int movieId;
  final List<ShowtimeRoom> rooms;
}

MovieShowtime mapShowtimesToPresentation(
  int movieId,
  List<ShowtimeDto> showtimes,
) {
  final byRoom = <int, List<ShowtimeDto>>{};
  for (final showtime in showtimes) {
    byRoom.putIfAbsent(showtime.roomId, () => []).add(showtime);
  }
  return MovieShowtime(
    movieId: movieId,
    rooms: byRoom.entries
        .map((entry) {
          final first = entry.value.first;
          return ShowtimeRoom(
            id: entry.key,
            name: first.roomName ?? 'Phòng ${entry.key}',
            formatBadge: _formatForRoom(entry.key),
            screenDetail: _detailForRoom(entry.key),
            slots: entry.value
                .map(
                  (item) => ShowtimeSlot(
                    id: item.id,
                    startAt: item.startTime,
                    endAt: item.endTime,
                    price: item.basePrice ?? VndMoney.zero,
                    status: item.status,
                  ),
                )
                .toList(growable: false),
          );
        })
        .toList(growable: false),
  );
}

String _formatForRoom(int roomId) => switch (roomId) {
  1 => 'IMAX Laser',
  3 => 'Dolby Atmos',
  _ => 'Standard 2D',
};

String _detailForRoom(int roomId) => switch (roomId) {
  1 => 'Màn chiếu 22m • Laser 4K',
  3 => 'Âm thanh 64 kênh 3D',
  _ => 'Phụ đề tiếng Việt',
};

String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
