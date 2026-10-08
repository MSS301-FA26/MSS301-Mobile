import 'package:dio/dio.dart';

class RedactedNetworkLogger extends Interceptor {
  RedactedNetworkLogger({void Function(String line)? write})
    : _write = write ?? print;

  static const _sensitive = {
    'authorization',
    'cookie',
    'accesstoken',
    'refreshtoken',
    'password',
    'otp',
    'apikey',
    'secret',
  };

  final void Function(String line) _write;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _write('REQUEST ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _write('RESPONSE ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _write(
      'ERROR ${err.response?.statusCode ?? err.type.name} ${err.requestOptions.uri}',
    );
    handler.next(err);
  }

  static dynamic redact(Object? value) {
    if (value is Map) {
      return value.map((key, item) {
        final normalized = key.toString().toLowerCase().replaceAll('_', '');
        return MapEntry(
          key,
          _sensitive.contains(normalized) ? '[REDACTED]' : redact(item),
        );
      });
    }
    if (value is Iterable) return value.map(redact).toList(growable: false);
    return value;
  }
}
