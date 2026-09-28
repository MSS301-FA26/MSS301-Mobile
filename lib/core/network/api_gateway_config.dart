import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiGatewayConfig {
  const ApiGatewayConfig({
    required this.baseUrl,
    required this.useRemoteGateway,
    required this.connectTimeout,
    required this.receiveTimeout,
  });

  factory ApiGatewayConfig.fromEnvironment() => const ApiGatewayConfig(
    baseUrl: String.fromEnvironment(
      'MSS301_API_GATEWAY_URL',
      defaultValue: 'http://10.0.2.2:8080',
    ),
    useRemoteGateway: bool.fromEnvironment('MSS301_USE_REMOTE_GATEWAY'),
    connectTimeout: Duration(seconds: 12),
    receiveTimeout: Duration(seconds: 20),
  );

  final String baseUrl;
  final bool useRemoteGateway;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  Uri resolve(String path) {
    final base = Uri.parse(baseUrl);
    return base.resolve(path.startsWith('/') ? path.substring(1) : path);
  }
}

final apiGatewayConfigProvider = Provider<ApiGatewayConfig>(
  (ref) => ApiGatewayConfig.fromEnvironment(),
);
