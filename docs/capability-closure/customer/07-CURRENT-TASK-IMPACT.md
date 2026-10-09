# Current Mobile Task Impact — Backend DEV Refresh

This is an audit-only decision record. No production code, API, migration, test or Git history was changed.

## Current task status

| Task | Status | Impact |
|---|---|---|
| B11 | COMPLETE_WITH_DEFERRED_CONTRACTS | Existing B11 work is present; watchlist/password setup/preview-only capabilities remain intentionally bounded by their contract docs. |
| B12-A | COMPLETE | Backend refresh does not invalidate auth/profile/catalog/movie/detail/review/showtime integration. |
| B12-B | COMPLETE | Existing real seat-map/hold/quote/payment/completion boundary remains valid. |
| B12-C | READY_FOR_RETEST_ONLY | History/detail and standalone food-order remote paths are now backed by concrete backend controllers and gateway routes; run the existing Mobile targeted/full validation against refreshed DEV before claiming runtime closure. |

## Newly supported / confirmed

- Booking history: `GET /api/v1/bookings`.
- Booking detail/ticket data: `GET /api/v1/bookings/{bookingId}`.
- Standalone food orders: `POST/GET/DELETE /api/v1/food-orders*`.
- Attached booking food orders: `/api/v1/bookings/{bookingId}/food-orders*`.
- Wallet and loyalty customer read/redeem endpoints are present and routed.

These are classified as supported backend capabilities; Mobile must not silently switch preview UI to fake data. Existing remote bindings and DTO tests are the source of truth for what is already wired.

## Still deferred

- Persistent watchlist/favorites (no customer endpoint found).
- Customer notifications, support/chat, vouchers and customer-initiated refund flow (no stable public customer contract found).
- Direct production AI recommendation binding until the gateway path split and response/auth contract are verified end-to-end.

## Needs retest

- `flutter test test/remote_booking_repository_test.dart`
- `flutter test test/remote_food_order_repository_test.dart`
- `flutter test test/booking_entry_test.dart`
- `flutter analyze`, `flutter test`, and `git diff --check` in Mobile.
- Runtime smoke through the configured gateway with a real JWT: history, detail, food-order history, wallet/loyalty and recommendation route selection.

## Needs Mobile update

No implementation update is authorized by this audit. If runtime retest confirms the contracts, the next change is documentation/closure status only. A supported capability may be promoted from `READY_FOR_RETEST_ONLY` after evidence is recorded.

## Breaking contract changes

None observed in backend branch `dev` at HEAD `f93e4f2d433631ba5ad92a4d4c8e8df3d7250c99`; branch is clean and synchronized with `origin/dev`.

## Final decision

**B — ONE_SUPPORTED_MOBILE_UPDATE_BATCH_REQUIRED**

Reason: the core B11/B12 customer journey is not blocked by a backend change, but B12-C still needs one evidence-backed Mobile retest/closure pass for the newly confirmed history/detail/food-order paths. Do not implement deferred watchlist/notification/support/voucher features without a new approved backend contract.

