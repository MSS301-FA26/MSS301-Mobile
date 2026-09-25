int intFromJson(Object? value, {String? field}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException(
    'Expected integer${field == null ? '' : ' for $field'}',
  );
}

int? nullableIntFromJson(Object? value, {String? field}) =>
    value == null ? null : intFromJson(value, field: field);

double doubleFromJson(Object? value, {String? field}) {
  if (value is num) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('Expected number${field == null ? '' : ' for $field'}');
}

bool boolFromJson(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  if (value is num) return value != 0;
  return fallback;
}

DateTime dateTimeFromJson(Object? value, {String? field}) {
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException(
    'Expected date time${field == null ? '' : ' for $field'}',
  );
}

DateTime? nullableDateTimeFromJson(Object? value, {String? field}) =>
    value == null ? null : dateTimeFromJson(value, field: field);

List<T> listFromJson<T>(Object? value, T Function(Map<String, Object?>) parse) {
  if (value == null) return const [];
  if (value is! List) throw const FormatException('Expected JSON list');
  return value
      .map((item) => parse(Map<String, Object?>.from(item as Map)))
      .toList(growable: false);
}

List<int> intListFromJson(Object? value) {
  if (value == null) return const [];
  if (value is! List) throw const FormatException('Expected integer list');
  return value.map(intFromJson).toList(growable: false);
}

List<String> stringListFromJson(Object? value) {
  if (value == null) return const [];
  if (value is! List) throw const FormatException('Expected string list');
  return value.map((item) => item.toString()).toList(growable: false);
}
