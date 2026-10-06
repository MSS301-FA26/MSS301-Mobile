enum AppEnvironment { development, staging, production }

class AppConfig {
  AppConfig({required this.environment, required this.apiBaseUrl})
    : _validated = true {
    validateBaseUrl(apiBaseUrl);
  }

  factory AppConfig.fromDartDefines() {
    final rawEnvironment = const String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );
    final rawBaseUrl = const String.fromEnvironment('API_BASE_URL');
    return AppConfig(
      environment: _parseEnvironment(rawEnvironment),
      apiBaseUrl: rawBaseUrl,
    );
  }

  final AppEnvironment environment;
  final String apiBaseUrl;
  final bool _validated;

  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isStaging => environment == AppEnvironment.staging;
  bool get isProduction => environment == AppEnvironment.production;

  static AppEnvironment _parseEnvironment(String value) {
    return switch (value.trim().toLowerCase()) {
      'development' || 'dev' => AppEnvironment.development,
      'staging' || 'stage' => AppEnvironment.staging,
      'production' || 'prod' => AppEnvironment.production,
      _ => throw ArgumentError.value(
        value,
        'APP_ENV',
        'Unsupported environment',
      ),
    };
  }

  static Uri validateBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        value,
        'apiBaseUrl',
        'API_BASE_URL is required',
      );
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        uri.host.isEmpty ||
        !{'http', 'https'}.contains(uri.scheme)) {
      throw ArgumentError.value(
        value,
        'apiBaseUrl',
        'API_BASE_URL must be an HTTP(S) URL',
      );
    }
    return uri;
  }

  // Keeps construction const while validating all runtime-created configs.
  bool get isValid => _validated && validateBaseUrl(apiBaseUrl).isAbsolute;
}
