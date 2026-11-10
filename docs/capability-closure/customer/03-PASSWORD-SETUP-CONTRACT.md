# Google Password Setup Contract

## Classification

`CONTRACT_MISSING`

Do not implement a dedicated Mobile password-setup flow in B11 until the identity contract is clarified.

## Web evidence

`MSS301-Frontend/src/pages/auth/GooglePasswordSetupPage.jsx`:

- guards on `currentUser.passwordChangeRequired`;
- redirects authenticated users without that flag away from `/setup-password`;
- submits `POST /api/v1/users/me/password`;
- sends `oldPassword`, `newPassword`, and `confirmPassword`;
- clears `passwordChangeRequired` and `passwordSetupProvider` locally after success.

`MSS301-Frontend/src/stores/useAuthStore.js` and `src/services/authService.js` also preserve and route on `passwordChangeRequired`.

## Backend evidence

The identity service exposes:

- `POST /api/v1/auth/google`
- `POST /api/v1/auth/google/verify`
- `GET /api/v1/users/me`
- `POST /api/v1/users/me/password`

`AuthResponse` contains only:

- access token
- refresh token
- token type
- expiry
- user profile
- roles

`UserProfileResponse` does not expose `passwordChangeRequired`, `passwordSetupProvider`, `hasPassword`, provider, or social-login state. The `User` entity also has no such explicit field. The password-change endpoint exists, but that alone does not tell a client when the flow is mandatory.

## Why reset-password is not equivalent

Mobile's `AuthRemoteDataSource` supports request, OTP verification, and confirmation for password reset. The Web setup flow instead requires an authenticated user, a temporary password, and a forced post-Google-login state. The two flows have different triggers and lifecycle semantics.

## Result

- Dedicated setup endpoint: **NO**. The existing authenticated password-change endpoint is used by Web.
- Concrete mandatory-state field: **NO** in the current identity-service response model.
- Dedicated Mobile flow required: **UNCONFIRMED**.
- Safe Mobile action now: **NO**.

Required follow-up is an identity contract decision: expose a stable mandatory-setup field in login/profile/session responses, or explicitly declare that Mobile does not require the Web-only setup flow.
