import 'package:dio/dio.dart';

import 'api_exception.dart';

class ApiErrorMapper {
  ApiException fromDioException(DioException error) {
    final response = error.response;
    if (response != null) return fromResponse(response, cause: error);

    final type = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => ApiErrorType.timeout,
      DioExceptionType.connectionError => ApiErrorType.network,
      DioExceptionType.cancel => ApiErrorType.cancelled,
      _ => ApiErrorType.unknown,
    };
    return ApiException(
      type: type,
      message: _transportMessage(type),
      originalCause: error,
    );
  }

  ApiException fromResponse(Response<dynamic> response, {Object? cause}) {
    final data = response.data;
    final fields = _fields(data);
    final status = response.statusCode;
    return ApiException(
      type: _statusType(status),
      statusCode: status,
      backendCode: fields.code,
      message:
          fields.message ??
          'Request failed${status == null ? '' : ' ($status)'}.',
      validationErrors: fields.errors,
      originalCause: cause,
    );
  }

  ApiErrorType _statusType(int? status) {
    if (status == null) return ApiErrorType.unknown;
    return switch (status) {
      400 => ApiErrorType.badRequest,
      401 => ApiErrorType.unauthorized,
      403 => ApiErrorType.forbidden,
      404 => ApiErrorType.notFound,
      409 => ApiErrorType.conflict,
      422 => ApiErrorType.validation,
      429 => ApiErrorType.tooManyRequests,
      >= 500 && <= 599 => ApiErrorType.server,
      _ => ApiErrorType.unknown,
    };
  }

  _ErrorFields _fields(Object? data) {
    if (data is! Map) return const _ErrorFields();
    final nested = data['error'];
    final source = nested is Map ? nested : data;
    final message = source['message']?.toString();
    final code = source['code']?.toString();
    final rawErrors = source['errors'];
    final errors = rawErrors is Map
        ? rawErrors.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};
    return _ErrorFields(message: message, code: code, errors: errors);
  }

  String _transportMessage(ApiErrorType type) => switch (type) {
    ApiErrorType.timeout => 'The request timed out.',
    ApiErrorType.network => 'The network is unavailable.',
    ApiErrorType.cancelled => 'The request was cancelled.',
    _ => 'The request could not be completed.',
  };
}

class _ErrorFields {
  const _ErrorFields({this.message, this.code, this.errors = const {}});
  final String? message;
  final String? code;
  final Map<String, dynamic> errors;
}
