import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/time/vietnam_time.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_dto.dart';
import 'package:mss301_mobile/features/showtime/data/models/showtime_dto.dart';
import 'package:mss301_mobile/features/showtime/presentation/models/showtime_models.dart';

void main() {
  test(
    'Vietnam schedule time stays 10:00 with or without an explicit offset',
    () {
      for (final raw in [
        '2026-10-12T10:00:00',
        '2026-10-12T10:00:00+07:00',
        '2026-10-12T03:00:00Z',
        '2026-10-11T22:00:00-05:00',
      ]) {
        final value = cinemaTimeFromJson(raw);
        expect(value, DateTime.utc(2026, 10, 12, 3));
        expect(formatVietnamDateTime(value), '10:00 • 12/10/2026');
      }
      expect(nullableCinemaTimeFromJson(null), isNull);
    },
  );

  test(
    'Vietnam calendar and date filtering handle UTC midnight boundaries',
    () {
      final instant = DateTime.utc(2026, 10, 11, 18, 30);
      expect(formatVietnamDateTime(instant), '01:30 • 12/10/2026');
      expect(isVietnamDate(instant, DateTime(2026, 10, 12)), isTrue);
      expect(isVietnamDate(instant, DateTime(2026, 10, 11)), isFalse);
      expect(vietnamCalendar(instant).day, 12);
    },
  );

  test('showtime and booking interpret offset-less times as Vietnam time', () {
    final showtime = ShowtimeDto.fromJson({
      'id': 1,
      'movieId': 1,
      'cinemaId': 1,
      'roomId': 1,
      'startTime': '2026-10-12T10:00:00',
      'endTime': '2026-10-12T12:00:00',
      'status': 'OPEN',
    });
    final presentation = mapShowtimesToPresentation(1, [showtime]);
    expect(presentation.rooms.single.slots.single.time, '10:00');
    final booking = BookingDto.fromJson({
      'id': 1,
      'bookingCode': 'BK-1',
      'userId': 1,
      'showtimeId': 1,
      'movieId': 1,
      'subtotal': 0,
      'discountAmount': 0,
      'totalAmount': 0,
      'status': 'HOLDING',
      'createdAt': '2026-10-11T06:00:00',
      'showtimeStartSnapshot': '2026-10-12T10:00:00',
      'holdExpiresAt': '2026-10-11T13:03:00',
    });
    expect(booking.showtimeStartSnapshot, showtime.startTime);
    expect(
      formatVietnamDateTime(booking.showtimeStartSnapshot!),
      '10:00 • 12/10/2026',
    );
    expect(
      booking.holdExpiresAt!.difference(DateTime.utc(2026, 10, 11, 6)),
      const Duration(minutes: 3),
    );
  });
}
