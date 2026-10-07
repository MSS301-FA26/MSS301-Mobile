# Authentication architecture

Production authentication now has one Riverpod source of truth: `authSessionProvider`.

```text
AuthPage -> AuthSessionController -> AuthRepository -> AuthRemoteDataSource -> Dio(:8080)
                                      |                  |
                                      +-> TokenStorage    +-> ApiException mapping
```

The repository owns the remote contract; the controller owns UI session state. Existing mock repositories remain scoped to catalog, booking, payment, and preview/test flows.

## Backend contract

- Login: `POST /api/v1/auth/login` with `username` and `password`.
- Register: `POST /api/v1/auth/register`.
- Email verification: `/verify-email` and `/verify-email/request`.
- Password reset: `/password-reset/request`, `/verify`, and `/confirm`.
- Refresh: `POST /api/v1/auth/refresh` with `refreshToken`.
- Logout: `POST /api/v1/auth/logout` with `refreshToken`.

All calls use the canonical gateway configured by `AppConfig`/`ApiConfig`.
