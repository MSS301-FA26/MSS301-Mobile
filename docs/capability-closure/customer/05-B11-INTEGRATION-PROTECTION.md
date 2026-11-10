# B11 Integration Protection

## Protected flows

B11 implementation must not alter:

- Auth token storage, refresh, interceptor behavior, or guards.
- Catalog movie IDs, DTO mapping, providers, pagination, or filters.
- Showtime queries and showtime IDs.
- Seat map state, seat holds, TTL, conflict refresh, or booking IDs.
- Checkout quote requests, server totals, or food selections attached to ticket bookings.
- VNPay/payment launch, return, status polling, or idempotency.
- Booking completion ordering and duplicate-call protection.
- Ticket/QR rendering from server data.
- Booking history/detail repository and status mapping.

## Watchlist safeguards

- Use the existing authenticated Dio client; do not add a second token path.
- Scope state by authenticated user and invalidate it on logout.
- Treat movie IDs as catalog primary keys.
- Do not optimistically claim persistence until the Gateway endpoint succeeds.
- Do not change catalog DTOs merely to carry wishlist state unless the API contract requires it.
- Test duplicate add, remove missing item, expired token, and Gateway-unavailable behavior.

## Food-order safeguards

- Use a separate production food-order repository; do not use `ProvisionalPreviewRepository`.
- Keep standalone orders distinct from booking food selections and checkout quote DTOs.
- Render `totalAmount`, status, timestamps, and QR code from server response.
- Do not infer payment completion from local UI state.
- Do not modify booking completion, seat hold, payment, or ticket flows for the history-only batch.
- Test ownership errors, empty history, each status, expired token, and backend failure.

## Password-setup safeguards

- Do not infer a forced setup state from Google login success alone.
- Do not route every Google user into a new Mobile setup page.
- Do not reinterpret password reset as setup-required.
- Wait for an explicit identity-service contract and preserve auth continuation semantics.

## Stop conditions

Stop and report if implementation requires changes to:

- route guards or redirects;
- auth/session response semantics;
- booking, seat-hold, checkout, payment, or ticket repositories;
- direct microservice access;
- fake or provisional production data.
