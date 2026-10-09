# Backend DEV Refresh — Customer Capability Snapshot

Audit date: 2026-10-09. Source snapshot: backend branch `dev`, HEAD `f93e4f2d433631ba5ad92a4d4c8e8df3d7250c99`; worktree clean and `HEAD...origin/dev = 0 0`.

## Routing and security evidence

- Gateway routes identity, catalog, booking, payment and the AI fallback (`cinema-services/api-gateway/src/main/resources/application.properties`). Booking and payment customer paths are publicly routed through the gateway; downstream services require JWT for authenticated operations (`booking-service/.../security/SecurityConfig.java`, `payment-service/.../security/SecurityConfig.java`).
- Customer booking contract exists: hold, checkout, items, history, detail, cancel and code lookup (`booking-service/.../controller/BookingController.java`). Attached and standalone food-order contracts exist (`BookingFoodOrderController.java`, `StandaloneFoodOrderController.java`).
- Catalog exposes movies, showtimes, seat maps and checkout quote (`MovieController.java`, `ShowtimeController.java`, `CatalogController.java`/quote controller). Payment exposes VNPay/mock creation and payment lookup; wallet and loyalty customer controllers are present.
- Identity exposes auth and `/api/v1/users/me`. Recommendation has real Python endpoints, but the gateway's `/api/v1/ai-recommendation/**` fallback points to catalog; the AI service also has `/api/v1/recommendations/...` routes. This is a route/contract distinction, not a new backend change.

## Capability classification

| Capability | Status | Evidence / boundary |
|---|---|---|
| Auth, profile, movie/catalog, reviews, showtimes, cinema and seat map | SUPPORTED_AND_IMPLEMENTED | Customer controllers and current Mobile remote repositories are present. |
| Seat hold lifecycle, checkout quote, VNPay payment, booking completion, ticket/QR, booking history/detail | SUPPORTED_AND_IMPLEMENTED | Booking/payment/catalog endpoints and Mobile Batches 05–09 remote flows. |
| Standalone food order history and attached booking food orders | SUPPORTED_AND_IMPLEMENTED | `/api/v1/food-orders*` and `/api/v1/bookings/{id}/food-orders*`; Mobile has remote food-order/history coverage. |
| Loyalty read/redeem and wallet read/transactions | SUPPORTED_BUT_POLISH_ONLY | Customer controllers exist; current Mobile account composition still uses the established account repository/preview boundaries. Retest against live JWT data before enabling mutations. |
| AI/recommendations | SUPPORTED_AND_MISSING | Backend implementations exist, but gateway path split/fallback (`/api/v1/ai-recommendation/**` vs `/api/v1/recommendations/**`) must be confirmed against the Mobile contract before a production binding is claimed. |
| Persistent watchlist/favorites | DEFER_BACKEND | No customer watchlist controller/repository endpoint found; only wishlist text/metrics exist. Do not recreate a wishlist service in Mobile. |
| Customer notifications, support/chat, vouchers, customer refund action | DEFER_BACKEND | No stable customer-facing controller + gateway + auth contract was found; related backend code is admin/internal or AI module support code. |
| Admin/staff reports, check-in, refund operations | NOT_REQUIRED | Existing endpoints are role-scoped operational capabilities, outside the current customer Mobile closure. |

## Refresh impact

No backend API, schema, route, auth or response-shape change was observed relative to the Mobile B11/B12 work already documented. The main newly confirmed facts are that booking history/detail, standalone food orders, wallet/loyalty and recommendation implementations are present in this DEV snapshot, while watchlist/notifications/support/vouchers remain without a safe customer contract.

