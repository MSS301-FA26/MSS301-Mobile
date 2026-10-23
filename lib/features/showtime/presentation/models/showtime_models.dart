import '../../../../core/time/vietnam_time.dart';
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

  bool get isBookable => status == ShowtimeStatus.open;
  bool isBookableAt(DateTime now) => isBookable && startAt.isAfter(now);
  String? unavailableReason(DateTime now) {
    if (status == ShowtimeStatus.cancelled) return 'Đã hủy';
    if (status == ShowtimeStatus.completed) return 'Đã kết thúc';
    if (!startAt.isAfter(now)) return 'Đã qua giờ';
    if (status == ShowtimeStatus.scheduled) return 'Chưa mở bán';
    if (status != ShowtimeStatus.open) return 'Không khả dụng';
    return null;
  }

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
    this.cinemaId,
    this.cinemaName,
  });

  final int id;
  final String name;
  final String formatBadge;
  final String screenDetail;
  final List<ShowtimeSlot> slots;
  final int? cinemaId;
  final String? cinemaName;
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
  final byRoom = <(int, int), List<ShowtimeDto>>{};
  for (final showtime in showtimes) {
    byRoom
        .putIfAbsent((showtime.cinemaId, showtime.roomId), () => [])
        .add(showtime);
  }
  return MovieShowtime(
    movieId: movieId,
    rooms: byRoom.entries
        .map((entry) {
          final first = entry.value.first;
          return ShowtimeRoom(
            id: first.roomId,
            name: first.roomName ?? 'Phòng ${first.roomId}',
            formatBadge: '',
            screenDetail: '',
            cinemaId: first.cinemaId,
            cinemaName: first.cinemaName,
            slots:
                (entry.value.toList()
                      ..sort((a, b) => a.startTime.compareTo(b.startTime)))
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

String _time(DateTime value) => formatVietnamTime(value);
