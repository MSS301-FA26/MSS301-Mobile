import 'json_parsers.dart';

class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.data,
    required this.message,
    required this.timestamp,
  });

  final bool success;
  final T? data;
  final String message;
  final DateTime timestamp;

  factory ApiResponse.fromJson(
    Map<String, Object?> json,
    T Function(Object? value) parseData,
  ) {
    return ApiResponse(
      success: boolFromJson(json['success']),
      data: json['data'] == null ? null : parseData(json['data']),
      message: json['message']?.toString() ?? '',
      timestamp: dateTimeFromJson(json['timestamp'], field: 'timestamp'),
    );
  }
}
