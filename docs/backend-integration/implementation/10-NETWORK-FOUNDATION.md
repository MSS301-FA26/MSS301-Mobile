# Network Foundation

Status: implemented for infrastructure only.

## Architecture

```text
AppConfig
   ↓
ApiConfig
   ↓
Dio
   ↓
API Gateway :8080
```

The existing feature repositories remain mock-bound. No authentication, remote repository, booking, payment, or UI flow was migrated.

## Dependencies

- `dio: ^5.9.0`
- Existing Riverpod dependency is reused for providers.

## Created files

- `lib/core/config/app_config.dart`
- `lib/core/config/api_config.dart`
- `lib/core/network/api_exception.dart`
- `lib/core/network/error_mapper.dart`
- `lib/core/network/network_logger.dart`
- `lib/core/network/dio_client.dart`
- `lib/core/network/network_providers.dart`
- `test/core/network_foundation_test.dart`

## Error architecture

```text
DioException
   ↓
ApiErrorMapper
   ↓
ApiException
```

`Dio` is configured from injected `ApiConfig`. No Authorization header, customer ID, token refresh, or internal-service secret is added.

## Logging

Development-only request/response/error logging is enabled from `AppConfig.isDevelopment`. Sensitive nested fields are redacted for Authorization, cookies, access/refresh tokens, passwords, OTPs, API keys, and secrets.
