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

  String get userMessage {
    final normalizedMessage = message.toLowerCase();
    if (type == ApiErrorType.unauthorized) {
      if (normalizedMessage.contains('invalid username or password') ||
          normalizedMessage.contains('invalid credentials') ||
          normalizedMessage.contains('bad credentials')) {
        return 'Tên đăng nhập hoặc mật khẩu không chính xác.';
      }
      return 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn. Vui lòng đăng nhập lại.';
    }

    return switch (type) {
      ApiErrorType.badRequest || ApiErrorType.validation =>
        'Thông tin gửi lên chưa hợp lệ. Vui lòng kiểm tra và thử lại.',
      ApiErrorType.forbidden => 'Bạn không có quyền thực hiện thao tác này.',
      ApiErrorType.notFound => 'Không tìm thấy dữ liệu cần tải.',
      ApiErrorType.conflict =>
        'Yêu cầu không thể thực hiện do dữ liệu đã thay đổi. Vui lòng thử lại.',
      ApiErrorType.tooManyRequests =>
        'Có quá nhiều yêu cầu. Vui lòng chờ một chút rồi thử lại.',
      ApiErrorType.server =>
        'Máy chủ đang gặp sự cố${statusCode == null ? '' : ' ($statusCode)'}. Vui lòng thử lại sau.',
      ApiErrorType.timeout =>
        'Kết nối đến máy chủ quá lâu. Vui lòng kiểm tra mạng và thử lại.',
      ApiErrorType.network =>
        'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng và thử lại.',
      ApiErrorType.cancelled => 'Yêu cầu đã bị hủy. Vui lòng thử lại.',
      ApiErrorType.unknown =>
        'Đã xảy ra lỗi khi xử lý yêu cầu. Vui lòng thử lại.',
      ApiErrorType.unauthorized =>
        'Phiên đăng nhập không hợp lệ hoặc đã hết hạn. Vui lòng đăng nhập lại.',
    };
  }

  @override
  String toString() => 'ApiException(${type.name}, $statusCode): $message';
}

String userFacingErrorMessage(Object error) => error is ApiException
    ? error.userMessage
    : 'Đã xảy ra lỗi khi tải dữ liệu. Vui lòng thử lại.';
