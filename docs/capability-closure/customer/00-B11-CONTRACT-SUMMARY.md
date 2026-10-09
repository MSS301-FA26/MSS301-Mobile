# B11-A Customer Capability Contract Summary

## Decision

| Capability | Backend readiness | Gateway readiness | Auth readiness | Mobile decision |
|---|---|---|---|---|
| Persistent watchlist | READY | READY | READY | Safe for B11-B after DTO/error tests |
| Standalone food-order history | READY | READY | READY | Safe for B11-C; use real repository flow |
| Google password setup | PARTIAL | Identity route exists | State contract incomplete | Do not implement yet |

## Watchlist

Confirmed public path: `/api/v1/wishlist`.

- `GET` lists the authenticated user's wishlist.
- `POST` adds a movie using `{ "movieId": number }`.
- `DELETE /{movieId}` removes one item.
- The unique `(user_id, movie_id)` constraint and service conflict handling prevent duplicate adds.
- The list is not paginated.
- Authorization is derived from the authenticated principal; users cannot address another user's list.

The API Gateway routes the path to `booking-service` because the controller is in the main booking application. This is an architectural placement detail; the route is exposed through Gateway and is not a direct-service request.

## Standalone food orders

Confirmed customer history path: `GET /api/v1/food-orders/my`.

- `POST /api/v1/food-orders` creates a standalone order.
- `GET /api/v1/food-orders/my` lists the current user's orders.
- `DELETE /api/v1/food-orders/{foodOrderId}` cancels an order subject to service rules.
- The list is not paginated.
- The order response contains order identity, booking linkage when present, status, totals, timestamps, QR code, and food item snapshots.
- All customer operations use the authenticated user and ownership checks.

The API Gateway routes these paths to `booking-service`.

## Google password setup

Web evidence uses `currentUser.passwordChangeRequired`, redirects to `/setup-password`, and submits `POST /api/v1/users/me/password` with a temporary password and new password.

The current identity-service `AuthResponse` contains access token, refresh token, token type, expiry, user profile, and roles. `UserProfileResponse` and the `User` entity do not expose `passwordChangeRequired` or `passwordSetupProvider`. Therefore Mobile cannot safely know when to force a dedicated setup flow.

Classification: `CONTRACT_MISSING`.

## Recommended sequence

1. B11-B: persistent watchlist.
2. B11-C: standalone food-order history.
3. Re-open Google password setup only after the identity contract explicitly exposes the required state and its lifecycle.

No Dart, Backend, or Frontend files were modified by B11-A.
