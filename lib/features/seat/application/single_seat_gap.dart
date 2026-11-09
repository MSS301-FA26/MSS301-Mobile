import '../../showtime/data/models/showtime_dto.dart';
import '../../movie/data/models/catalog_enums.dart';

/// Returns the first newly orphaned seat. Existing gaps created by another
/// booking do not prevent a customer from changing an unrelated selection.
ShowtimeSeatDto? newlyOrphanedSeat(
  List<ShowtimeSeatDto> seats,
  Set<int> before,
  Set<int> after,
) {
  final previous = _orphanedSeats(seats, before);
  for (final seat in _orphanedSeats(seats, after)) {
    if (!previous.contains(seat)) return seat;
  }
  return null;
}

ShowtimeSeatDto? orphanedSeat(List<ShowtimeSeatDto> seats, Set<int> selected) =>
    _orphanedSeats(seats, selected).firstOrNull;

Set<ShowtimeSeatDto> _orphanedSeats(
  List<ShowtimeSeatDto> seats,
  Set<int> selected,
) {
  final rows = <String, List<ShowtimeSeatDto>>{};
  for (final seat in seats) {
    if (seat.displayColumn <= 0) {
      continue;
    }
    rows.putIfAbsent(seat.rowLabel.toUpperCase(), () => []).add(seat);
  }
  final result = <ShowtimeSeatDto>{};
  for (final row in rows.values) {
    row.sort((a, b) => a.displayColumn.compareTo(b.displayColumn));
    // An unavailable physical seat divides the row. A booked/held seat does
    // not: it acts as an occupied boundary for the empty run.
    final segment = <ShowtimeSeatDto>[];
    void inspect() {
      for (var index = 1; index + 1 < segment.length; index++) {
        final seat = segment[index];
        if (!seat.selectable || selected.contains(seat.seatId)) continue;
        final left = segment[index - 1];
        final right = segment[index + 1];
        if (_occupied(left, selected) && _occupied(right, selected)) {
          result.add(seat);
        }
      }
      segment.clear();
    }

    for (final seat in row) {
      if (!_physicalSeat(seat)) {
        inspect();
        continue;
      }
      if (segment.isNotEmpty &&
          seat.displayColumn != segment.last.displayColumn + 1) {
        inspect();
      }
      segment.add(seat);
    }
    inspect();
  }
  return result;
}

bool _physicalSeat(ShowtimeSeatDto seat) =>
    seat.seatStatus == SeatStatus.available &&
    seat.runtimeStatus != SeatRuntimeStatus.unavailable &&
    seat.runtimeStatus != SeatRuntimeStatus.unknown;

bool _occupied(ShowtimeSeatDto seat, Set<int> selected) =>
    selected.contains(seat.seatId) ||
    seat.runtimeStatus == SeatRuntimeStatus.holding ||
    seat.runtimeStatus == SeatRuntimeStatus.booked ||
    seat.runtimeStatus == SeatRuntimeStatus.checkedIn;
