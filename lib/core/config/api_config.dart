import 'app_config.dart';

class ApiConfig {
  ApiConfig({
    required AppConfig appConfig,
    this.connectTimeout = const Duration(seconds: 10),
    this.sendTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 20),
  }) : baseUrl = appConfig.apiBaseUrl,
       networkLoggingEnabled = appConfig.isDevelopment {
    if (connectTimeout.isNegative ||
        sendTimeout.isNegative ||
        receiveTimeout.isNegative) {
      throw ArgumentError('Network timeouts must not be negative');
    }
    AppConfig.validateBaseUrl(baseUrl);
  }

  final String baseUrl;
  final Duration connectTimeout;
  final Duration sendTimeout;
  final Duration receiveTimeout;
  final bool networkLoggingEnabled;

  Map<String, String> get defaultHeaders => const {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
}
