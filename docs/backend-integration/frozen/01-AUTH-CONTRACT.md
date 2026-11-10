# Auth Contract

AUTH CONTRACT STATUS:

```text
FROZEN for cinema-services public paths
```

## Public paths

All paths are reached through the gateway; owner is `identity-service`.

| Operation | Method | Path | Evidence |
|---|---|---|---|
| Register | POST | `/api/v1/auth/register` | `identity-service/.../controller/AuthController.java` |
| Login | POST | `/api/v1/auth/login` | same |
| Google login | POST | `/api/v1/auth/google` | same |
| Google OTP verify | POST | `/api/v1/auth/google/verify` | same |
| Refresh | POST | `/api/v1/auth/refresh` | same |
| Logout | POST | `/api/v1/auth/logout` | same |
| Verify email | POST | `/api/v1/auth/verify-email` | same |
| Resend email OTP | POST | `/api/v1/auth/verify-email/request` | same |
| Password reset request | POST | `/api/v1/auth/password-reset/request` | same |
| Password reset verify | POST | `/api/v1/auth/password-reset/verify` | same |
| Password reset confirm | POST | `/api/v1/auth/password-reset/confirm` | same |

## Login and token behavior

`POST /api/v1/auth/login` request DTO is `LoginRequest`:

| Field | Type | Required | Validation |
|---|---|---:|---|
| `username` | String | Yes | Not blank; JSON alias `email` is accepted |
| `password` | String | Yes | Not blank |

The response is `ApiResponse<AuthResponse>` where `AuthResponse` fields are exactly:

```text
accessToken: String
refreshToken: String
tokenType: String
expiresInMs: long
user: UserProfileResponse
roles: List<String>
```

`UserProfileResponse` includes `id: Long`, `email`, `fullName`, `phone`, `avatarUrl`, `birthYear`, `status`, `emailVerified`, `phoneVerified`, `roles`, optional `cinemaId`, `createdAt`, and `updatedAt`.

Evidence: `identity-service/src/main/java/com/cinemaai/identity/dto/response/auth/AuthResponse.java` and `.../user/UserProfileResponse.java`.

The refresh token is supplied in a JSON body (`RefreshTokenRequest.refreshToken`), not a cookie or Authorization header. `AuthServiceImpl.refresh` validates the old token and creates a new access/refresh pair, but `RefreshTokenServiceImpl` does not revoke the old refresh token during rotation. Therefore rotation is `NEW_TOKEN_ISSUED_WITHOUT_OLD_TOKEN_REVOCATION`.

Frozen facts:

- Access authentication is Bearer JWT through the identity filter.
- Refresh is `POST /api/v1/auth/refresh` with a request body containing `refreshToken`.
- Logout is a server call with a request body containing `refreshToken`; therefore it is server-side refresh-token handling, not merely local deletion.
- Customer identity is derived from the authenticated principal for protected endpoints.
- JWT claims include subject=email, `userId`, `email`, `roles`, and optional `cinemaId`; role values are strings from `RoleName`, with registration assigning `CUSTOMER`.
- Gateway routes `/api/v1/auth/**` and `/api/v1/users/**` to identity service.

## Current vs recommended

CURRENT CODE: Mobile has no auth repository, token storage, interceptor, or real auth DTO.

RECOMMENDED CONTRACT: MOB-011 should model the exact identity DTO records, persist tokens securely, attach only access tokens to protected calls, and use the refresh body contract on 401 recovery.
