import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';
import 'package:mss301_mobile/features/seat/application/single_seat_gap.dart';
import 'package:mss301_mobile/features/showtime/data/models/showtime_dto.dart';

ShowtimeSeatDto seat(
  int column, {
  String row = 'A',
  SeatRuntimeStatus runtime = SeatRuntimeStatus.available,
  SeatStatus status = SeatStatus.available,
  CatalogSeatType type = CatalogSeatType.standard,
}) => ShowtimeSeatDto(
  seatId: row.codeUnitAt(0) * 100 + column,
  seatRowId: row.codeUnitAt(0),
  rowLabel: row,
  displayOrder: column,
  seatNumber: column,
  displayColumn: column,
  startColumn: column,
  seatType: type,
  seatStatus: status,
  runtimeStatus: runtime,
);

void main() {
  test('rejects one free seat between selected or booked seats', () {
    final row = [for (var col = 1; col <= 5; col++) seat(col)];
    expect(
      newlyOrphanedSeat(row, {row[0].seatId}, {row[0].seatId, row[2].seatId}),
      row[1],
    );
    expect(newlyOrphanedSeat(row, {}, {row[0].seatId, row[3].seatId}), isNull);
    final booked = [
      seat(1, runtime: SeatRuntimeStatus.booked),
      seat(2),
      seat(3),
    ];
    expect(newlyOrphanedSeat(booked, {}, {booked[2].seatId}), booked[1]);
  });

  test('edges, aisles, maintenance and other rows are boundaries', () {
    final aisle = [seat(1), seat(2), seat(4)];
    expect(
      newlyOrphanedSeat(aisle, {}, {aisle[0].seatId, aisle[2].seatId}),
      isNull,
    );
    final off = [seat(1), seat(2, status: SeatStatus.maintenance), seat(3)];
    expect(newlyOrphanedSeat(off, {}, {off[0].seatId, off[2].seatId}), isNull);
    expect(
      newlyOrphanedSeat(
        [seat(1), seat(2), seat(3, row: 'B')],
        {},
        {seat(1).seatId, seat(3, row: 'B').seatId},
      ),
      isNull,
    );
  });

  test('does not attribute a preexisting gap to another selection', () {
    final row = [
      seat(1, runtime: SeatRuntimeStatus.booked),
      seat(2),
      seat(3, runtime: SeatRuntimeStatus.holding),
      seat(4),
      seat(5),
    ];
    expect(orphanedSeat(row, {}), row[1]);
    expect(newlyOrphanedSeat(row, {}, {row[3].seatId, row[4].seatId}), isNull);
    expect(
      newlyOrphanedSeat(row, {row[3].seatId, row[4].seatId}, {row[4].seatId}),
      row[3],
    );
  });

  test('two free couple seats count as two physical seats', () {
    final row = [
      seat(1),
      seat(2, type: CatalogSeatType.couple),
      seat(3, type: CatalogSeatType.couple),
      seat(4),
    ];
    expect(newlyOrphanedSeat(row, {}, {row[0].seatId, row[3].seatId}), isNull);
  });
}
