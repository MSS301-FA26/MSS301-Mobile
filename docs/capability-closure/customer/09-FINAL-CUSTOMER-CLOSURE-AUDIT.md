# Final Customer Capability Closure Audit

Audit date: 2026-10-09. Audit-only result; no Backend, Frontend or Mobile production code was changed.

## 1. Executive Summary

Backend `dev` is clean at `f93e4f2d433631ba5ad92a4d4c8e8df3d7250c99` and synchronized with `origin/dev` (`0 0`). The Gateway exposes the verified customer contracts used by the completed Mobile journey. B11, B12-A, B12-B and B13 remain compatible with no breaking contract change. One supported customer operation remains unimplemented in Mobile: loyalty redemption (`POST /api/v1/loyalty/me/redeem`).

## 2. Customer Capability Matrix

| Capability | Backend Service | Endpoint | Gateway | Mobile | Classification | Notes |
|---|---|---|---|---|---|---|
| Authentication | Identity | `/api/v1/auth/*` | Yes | Remote auth/session | SUPPORTED_AND_IMPLEMENTED | JWT/refresh flow. |
| Profile | Identity | `/api/v1/users/me` | Yes | Existing account profile flow | SUPPORTED_BUT_POLISH_ONLY | Current profile binding remains legacy account scope. |
| Home | Catalog | hero/movie endpoints | Yes | Remote catalog | ACCEPTED_MOBILE_DIFFERENCE | Mobile composition differs from Web. |
| Discover | Catalog | `/api/v1/movies`, genres | Yes | Remote catalog | SUPPORTED_AND_IMPLEMENTED | B12-A. |
| Search | Catalog | `/api/v1/movies?keyword=` | Yes | Remote catalog | SUPPORTED_AND_IMPLEMENTED | Uses catalog keyword contract. |
| Genres | Catalog | `/api/v1/genres` | Yes | Remote catalog | SUPPORTED_AND_IMPLEMENTED | |
| Movie detail | Catalog | `/api/v1/movies/{id}` | Yes | Remote catalog | SUPPORTED_AND_IMPLEMENTED | B12-B. |
| Cast/director/trailer | Catalog | movie/actor/director resources | Yes | Detail DTO/UI | ACCEPTED_MOBILE_DIFFERENCE | Trailer playback is presentation-limited. |
| Reviews | Catalog | `/api/v1/reviews/movies/{movieId}*` | Yes | Movie engagement repository | SUPPORTED_AND_IMPLEMENTED | Read and eligible customer actions. |
| Recommendations | Catalog/recommendation | `/api/v1/recommendation/content/{movieId}` | Yes | Movie engagement repository | SUPPORTED_AND_IMPLEMENTED | Current Gateway-compatible content path. |
| Cinemas | Catalog | `/api/v1/cinemas` | Yes | Remote catalog | SUPPORTED_AND_IMPLEMENTED | |
| Showtimes | Catalog | `/api/v1/showtimes*` | Yes | Remote catalog | SUPPORTED_AND_IMPLEMENTED | |
| Seat availability | Catalog | `/api/v1/showtimes/{id}/seat-map` | Yes | Remote seat map | SUPPORTED_AND_IMPLEMENTED | |
| Seat hold | Booking | `POST /api/v1/bookings/hold` | Yes | Remote seat hold | SUPPORTED_AND_IMPLEMENTED | JWT; conflict reconciliation covered. |
| Concessions | Catalog/Booking | foods and booking item endpoints | Yes | Booking concessions flow | SUPPORTED_AND_IMPLEMENTED | Attached booking scope. |
| Standalone food orders | Booking | `/api/v1/food-orders*` | Yes | Remote food repository | SUPPORTED_AND_IMPLEMENTED | B11. |
| Booking-attached food | Booking | `/api/v1/bookings/{id}/food-orders*` | Yes | Booking flow | SUPPORTED_AND_IMPLEMENTED | |
| Checkout quote | Catalog | `POST /api/v1/catalog/checkout-quote` | Yes | Remote catalog | SUPPORTED_AND_IMPLEMENTED | |
| Booking | Booking | hold/checkout/items | Yes | Remote booking/hold | SUPPORTED_AND_IMPLEMENTED | |
| Booking history | Booking | `GET /api/v1/bookings?page=&size=` | Yes | Remote booking repository | SUPPORTED_AND_IMPLEMENTED | JWT-scoped page. |
| Booking detail | Booking | `GET /api/v1/bookings/{id}` | Yes | Remote booking repository | SUPPORTED_AND_IMPLEMENTED | |
| Payment | Payment | `/api/v1/payments/*` | Yes | Remote payment | SUPPORTED_AND_IMPLEMENTED | |
| VNPay | Payment | `POST /api/v1/payments/vnpay/create` | Yes | Remote payment/launcher | SUPPORTED_AND_IMPLEMENTED | |
| Ticket / QR | Booking | booking detail response | Yes | Ticket page | SUPPORTED_AND_IMPLEMENTED | Backend QR fields preserved. |
| Wallet | Payment | `GET /api/v1/wallet` | Yes | Remote wallet | SUPPORTED_AND_IMPLEMENTED | B13. |
| Wallet transactions | Payment | `GET /api/v1/wallet/transactions` | Yes | Remote wallet | SUPPORTED_AND_IMPLEMENTED | Page envelope mapped. |
| Wallet withdrawal history | Payment | `GET /api/v1/wallet/withdrawals` | Yes | Repository read path | SUPPORTED_AND_IMPLEMENTED | No new withdrawal mutation scope added. |
| Loyalty points | Payment | `GET /api/v1/loyalty/me` | Yes | Remote loyalty | SUPPORTED_AND_IMPLEMENTED | B13. |
| Loyalty configuration | Payment | `GET /api/v1/loyalty/config` | Yes | Remote loyalty | SUPPORTED_AND_IMPLEMENTED | B13. |
| Loyalty redemption | Payment | `POST /api/v1/loyalty/me/redeem?points=` | Yes | Not implemented | SUPPORTED_AND_MISSING | Stable customer contract; no Backend change required. |
| Notifications | None verified | No customer Gateway route | No | Preview only | DEFER_BACKEND | No complete public contract. |
| Watchlist | None verified | No customer endpoint | No | Preview only | DEFER_BACKEND | Do not recreate service. |
| Vouchers/promotions | None verified | No stable customer contract | No | Preview only | DEFER_BACKEND | |
| Customer refund | Booking admin flow | Admin/refund endpoints only | Role-scoped | Preview only | DEFER_BACKEND | Not customer-safe. |
| Chat/support | AI chat exists, Gateway route not verified | `/api/v1/chat/*` not exposed in current Gateway map | No | Preview/support info | DEFER_BACKEND | |
| AI chatbot | AI service | `/api/v1/chat/*` | No verified Mobile Gateway route | Not production-bound | DEFER_BACKEND | |
| AI search | AI service | `/api/v1/search/*` | No verified Mobile Gateway route | Not production-bound | DEFER_BACKEND | |
| AI recommendation | AI service | `/api/v1/recommendations/*` | Dedicated route mismatch/fallback | Existing catalog recommendation used | DEFER_BACKEND | Keep current compatible path. |

## 3. Completed Supported Capabilities

The real production chain is active for authentication, catalog/discover/detail, showtimes/seat map/hold, quote, payment/VNPay, booking completion, tickets/QR, booking history/detail, standalone food history, wallet balance/transactions and loyalty read/configuration. Production providers use Remote repositories; mock repositories are only test overrides.

## 4. Supported But Missing

Only loyalty redemption remains supported-but-missing: `POST /api/v1/loyalty/me/redeem?points=`. The endpoint is public through the Payment Gateway route, authenticated, and has a known request/response contract. This is the sole condition requiring one final Mobile batch if product scope requires redemption.

## 5. Supported But Polish Only

Profile presentation and wallet/loyalty presentation can receive copy, loading and visual polish, but no contract work is required. These are not blockers for the supported journey.

## 6. Accepted Mobile Differences

Mobile's Home composition, cast/trailer presentation and account shell differ from Web by design. These differences do not bypass Backend contracts or introduce mock production data.

## 7. Deferred Backend Capabilities

Notifications, persistent watchlist, vouchers/promotions, customer refund, chat/support, AI chatbot, AI search and a dedicated AI recommendation Gateway contract remain deferred because the required complete customer-facing Gateway/auth contract is not proven.

## 8. Existing Contract Compatibility

- **B11:** Standalone food history remains `GET /api/v1/food-orders/my`, JWT-scoped, `ApiResponse<List<FoodOrderResponse>>`; Mobile test coverage passes.
- **B12-A:** Discover catalog paths and filters remain Gateway-compatible; no breaking change found.
- **B12-B:** Movie detail, reviews and content recommendation paths remain compatible; no breaking change found.
- **B13:** Wallet/Loyalty remote repositories use the shared authenticated Dio client and verified Gateway paths; repository tests pass. Loyalty redemption is intentionally not implemented.

## 9. Validation

- `flutter analyze`: PASS — no issues.
- `flutter test`: PASS — 76 tests.
- `git diff --check`: PASS.
- Backend status: clean, branch `dev`, synchronized with `origin/dev`.
- Mobile production code was not modified during this audit.

## 10. Final Decision

**ONE_FINAL_SUPPORTED_MOBILE_BATCH_REQUIRED**

Exactly one supported customer capability remains missing: loyalty redemption. If redemption is required for product closure, implement one narrowly scoped Mobile batch for the verified endpoint above. Otherwise, all currently implemented customer capabilities are closed, and no further customer capability implementation is justified until Backend exposes new supported contracts.

