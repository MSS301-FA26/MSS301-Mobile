import '../contracts/json_parsers.dart';

/// Cinema schedules without an offset are Vietnam wall times (UTC+7).
/// Server deadlines have their own parser and must not use this convention.
DateTime cinemaTimeFromJson(Object? value) {
  if (value is String &&
      !RegExp(r'(Z|[+-]\d{2}:?\d{2})$', caseSensitive: false).hasMatch(value)) {
    return dateTimeFromJson('$value+07:00').toUtc();
  }
  return dateTimeFromJson(value).toUtc();
}

DateTime? nullableCinemaTimeFromJson(Object? value) =>
    value == null ? null : cinemaTimeFromJson(value);

/// Calendar fields for display/filtering only; not an instant for comparisons.
DateTime vietnamCalendar(DateTime instant) =>
    instant.toUtc().add(const Duration(hours: 7));

String formatVietnamTime(DateTime instant) {
  final value = vietnamCalendar(instant);
  return '${_two(value.hour)}:${_two(value.minute)}';
}

String formatVietnamDateTime(DateTime instant) {
  final value = vietnamCalendar(instant);
  return '${formatVietnamTime(instant)} • '
      '${_two(value.day)}/${_two(value.month)}/${value.year}';
}

bool isVietnamDate(DateTime instant, DateTime calendarDate) {
  final value = vietnamCalendar(instant);
  return value.year == calendarDate.year &&
      value.month == calendarDate.month &&
      value.day == calendarDate.day;
}

String _two(int value) => value.toString().padLeft(2, '0');
