import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/contracts/json_parsers.dart';

void main() {
  test('server deadlines preserve instants for UTC and explicit offsets', () {
    final expiry = DateTime.utc(2026, 10, 11, 6, 3);
    for (final raw in [
      '2026-10-11T06:03:00',
      '2026-10-11T06:03:00Z',
      '2026-10-11T13:03:00+07:00',
      '2026-10-11T13:03:00+0700',
    ]) {
      expect(serverDeadlineFromJson(raw), expiry);
    }
    expect(nullableServerDeadlineFromJson(null), isNull);
    expect(
      serverDeadlineFromJson('2026-10-11T06:03:00.123456').microsecond,
      456,
    );
    expect(dateTimeFromJson('2026-10-12T10:00:00').hour, 10);
    expect(() => serverDeadlineFromJson('invalid'), throwsFormatException);
  });
}
