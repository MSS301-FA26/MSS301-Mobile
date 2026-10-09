# B12-C Runtime Contract Verification

Audit mode: verify/retest only. Date: 2026-10-09.

## 1. Backend Snapshot

- Branch `dev`, HEAD `f93e4f2d433631ba5ad92a4d4c8e8df3d7250c99`.
- Worktree clean; `HEAD...origin/dev = 0 0`.
- Backend and Frontend were not modified.

## 2. Gateway Verification

Gateway configuration routes `/api/v1/bookings/**` and `/api/v1/food-orders/**` to Booking Service, `/api/v1/wallet/**`, `/api/v1/wallets/**`, and `/api/v1/loyalty/**` to Payment Service, and catalog paths to Catalog Service. Customer JWT is supplied by Mobile's Dio interceptor; downstream customer operations are authenticated. Internal controllers were excluded from customer support classification.

## 3. Booking History / Detail

| Capability | Contract | Mobile comparison | Result |
|---|---|---|---|
| History | `GET /api/v1/bookings?page={page}&size={size}`; JWT-scoped; `ApiResponse<PageResponse<BookingResponse>>` | `RemoteBookingRepository` uses the Gateway path and page envelope; no customer id is sent | CURRENT |
| Detail | `GET /api/v1/bookings/{bookingId}`; JWT-scoped; `ApiResponse<BookingResponse>` | ID, totals, QR and ticket fields are mapped | CURRENT |

## 4. Food Order History

`GET /api/v1/food-orders/my` is Gateway-routed and customer-scoped by JWT. The response is `ApiResponse<List<FoodOrderResponse>>` (not paginated). `FoodOrderResponse` carries order identity/status, booking references when attached, totals and item data. Mobile B11 `RemoteFoodOrderRepository` maps this envelope and its repository tests pass.

Result: **DONE_VALID**.

## 5. Wallet

Customer-facing endpoints are present and Gateway-routed:

- `GET /api/v1/wallet` (alias `/wallets`): JWT customer balance, `ApiResponse<WalletResponse>`.
- `GET /api/v1/wallet/transactions?page=&size=`: JWT customer page, `ApiResponse<PageResponse<WalletTransactionResponse>>`.
- `GET /api/v1/wallet/withdrawals?page=&size=` and `POST /api/v1/wallet/withdrawals`: customer withdrawal history/create.

The current Mobile customer flow does not implement a real remote wallet screen or mutation path. Classification: **SUPPORTED_AND_MISSING** for wallet balance/transactions; withdrawal is **NOT_REQUIRED** for the current closure.

## 6. Loyalty / Points

Customer-facing endpoints are present and Gateway-routed:

- `GET /api/v1/loyalty/me`: current points, `ApiResponse<LoyaltyResponse>`.
- `GET /api/v1/loyalty/config?cinemaId=`: `ApiResponse<LoyaltyConfigurationResponse>`.
- `POST /api/v1/loyalty/me/redeem?points=`: authenticated redemption, `ApiResponse<LoyaltyResponse>`.

No separate point-history endpoint was found. Mobile does not currently bind these endpoints as a production customer feature. Classification: **SUPPORTED_AND_MISSING** for current points/config/redeem; point history is **DEFER_BACKEND**.

## 7. Recommendation Routing

Mobile movie detail currently calls `GET /api/v1/recommendation/content/{movieId}` through `MovieEngagementRepository`. The Python recommendation service implements that endpoint. Gateway currently exposes `/api/v1/recommendation/**` in the Catalog route list, while the dedicated AI route is `/api/v1/ai-recommendation/**` and points to Catalog as fallback. Therefore the existing Mobile path is compatible with the current Gateway configuration, but requires runtime smoke verification against the deployed gateway.

Result: **NEEDS_RUNTIME_RETEST**; no contract change is authorized.

## 8. Existing Mobile Validation

- `flutter analyze`: passed, no issues.
- `flutter test`: passed, **73 tests**.
- `git diff --check`: passed.
- No production source files changed; only the audit documents are untracked.

## 9. Supported and Missing Capabilities

Supported and implemented: auth/profile, catalog/discover/detail/reviews, showtimes/seat map/hold, quote/payment/completion, booking history/detail, ticket data, and standalone food-order history.

Supported and missing from current Mobile production binding: wallet balance/transactions and loyalty current points/config/redeem.

## 10. Deferred Backend Capabilities

Persistent watchlist, customer notifications, support/chat, vouchers, customer refund flow, and loyalty point history remain deferred because no complete stable customer contract was verified for them.

## 11. Contract Mismatches

No breaking mismatch found in implemented Mobile flows. Recommendation has two backend naming surfaces (`/recommendation/**` and `/ai-recommendation/**`); current Mobile uses the Gateway-routed `/api/v1/recommendation/content/{movieId}` path and must retain that path until runtime verification proves otherwise.

## 12. Final Closure Decision

**B — ONE_SUPPORTED_MOBILE_UPDATE_BATCH_REQUIRED**

The contradiction is resolved: the existing flows are valid and all validation passes, but wallet and loyalty have complete customer-facing contracts, Gateway exposure and authentication, while Mobile has no production binding. One follow-up batch is justified and must be limited to these endpoints:

- `GET /api/v1/wallet`
- `GET /api/v1/wallet/transactions?page=&size=`
- `GET /api/v1/loyalty/me`
- `GET /api/v1/loyalty/config?cinemaId=`
- `POST /api/v1/loyalty/me/redeem?points=`

No backend change is required for that batch. Do not implement deferred capabilities in the same batch.

