enum ApiErrorType {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  tooManyRequests,
  server,
  timeout,
  network,
  cancelled,
  unknown,
}

class ApiException implements Exception {
  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.backendCode,
    this.validationErrors = const {},
    this.originalCause,
  });

  final ApiErrorType type;
  final int? statusCode;
  final String? backendCode;
  final String message;
  final Map<String, dynamic> validationErrors;
  final Object? originalCause;

  @override
  String toString() => 'ApiException(${type.name}, $statusCode): $message';
}
