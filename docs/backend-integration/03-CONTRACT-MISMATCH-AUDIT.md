# Contract Mismatch Audit

This document compares the current Mobile mock-shaped DTOs with backend evidence. It intentionally does not change either side.

## High-impact mismatches

| Area | Mobile | Backend evidence | Classification | Impact |
|---|---|---|---|---|
| Authentication | No auth DTO/repository; hardcoded mock session | Backend has auth controller, JWT and refresh-token services | MISSING_MOBILE | Blocks real login/session |
| Auth response | No proven access/refresh token fields | Backend token response exists but exact selected implementation is unresolved | UNCERTAIN | Cannot safely implement interceptor |
| Movie list | `List<MovieDto>` from mock fixture | Backend APIs/controllers and pagination tests/docs exist | PAGINATION_CONTRACT_MISMATCH risk | Mobile may assume bare list |
| Quote | Local `CheckoutQuoteDto` | Monolith exposes ticket-pricing validation; microservice exposes catalog checkout quote | NAME_MISMATCH / MULTIPLE_CONTRACTS | Final price source unresolved |
| Hold | Mobile has booking object with `holdExpiresAt` | Backend hold contract has booking/seat locking semantics | ADAPTABLE | Exact hold identifier/expiry field must be verified |
| Booking update | Mobile `updateItems` mutates a holding booking | Monolith exposes `PUT /api/v1/bookings/{bookingId}/items`; microservice equivalence is not proven | ADAPTABLE / CANONICAL_UNCERTAIN | Food/seat edit depends on selected backend |
| Payment URL | Mobile uses `mock://vnpay/{id}` | Backend returns VNPay URL from create endpoint | FORMAT_MISMATCH | Requires launcher and return contract |
| Payment success | Mobile calls local `markSuccess` then local confirmation | Backend uses VNPay return/IPN and payment state | NAME_MISMATCH / MISSING_MOBILE | Local success is not authoritative |
| Payment return | No Mobile callback/deep link | Backend return redirects to configured URL; current tests use localhost callback | MISSING_MOBILE | Payment completion cannot be wired safely |
| QR/ticket | Ticket is derived from mock booking | Backend ticket/QR fields are not proven as dedicated endpoint/DTO | MISSING_MOBILE | QR source and trust model unresolved |
| Profile | `UserProfileDto` mock model | Backend user/profile DTOs exist in separate implementations | UNCERTAIN | Field-level mapping pending canonical selection |
| Loyalty | Mock DTO | Backend loyalty controller/service exists | UNCERTAIN | Exact endpoint/fields pending |
| Reviews | No Mobile DTO | Backend SRS says customer review flow is not implemented | MISSING_BACKEND | Do not implement Mobile review client yet |

## Field-level comparison status

| DTO | Field group | Mobile type | Backend type | Match |
|---|---|---|---|---|
| Movie | `id` | `int` | Backend entity IDs are numeric in inspected Java source | PROVISIONAL MATCH |
| Movie | `releaseDate` | nullable `DateTime` | Backend date/time representation varies by DTO/source | FORMAT_MISMATCH risk |
| Seat | `id`/`seatId` | `int` | Backend Java IDs appear numeric | PROVISIONAL MATCH |
| Seat | `status` | Dart enum with local wire values | Backend enum values require selected implementation comparison | ENUM_MISMATCH risk |
| Booking | `status` | local `BookingStatus` | Backend status set includes `HOLDING`, `PENDING_PAYMENT`, `PAID`, `CANCELLED`, `EXPIRED` evidence | ENUM_MISMATCH risk |
| Payment | `amount` | `VndMoney` | Backend monetary type/serialization differs by implementation and is not fully proven | MONEY_FORMAT_UNCERTAIN |
| Payment | `status` | local enum | Backend payment lifecycle includes pending/success/failure and callback/IPN state | ENUM_MISMATCH risk |
| Food | product IDs/quantity | `int` | Backend food DTOs exist; exact response fields not yet reconciled | UNCERTAIN |
| Ticket | QR payload | not modeled as backend contract | Backend QR representation not proven | MOBILE_DTO_MISSING |

## Date/time contract

Mobile parses date values into Dart `DateTime` and uses local `AppClock`. Backend source contains Java date/time DTOs and expiry timestamps, but timezone/offset guarantees for the chosen public API are not proven.

Classification: `FORMAT_MISMATCH` risk, especially for `showtime`, `holdExpiresAt`, payment timestamps, and ticket times.

## Money contract

Mobile uses `VndMoney` and integer-like VND semantics in mock DTOs. Backend contains pricing/quote/payment amounts, but the public JSON representation and scale are not yet proven for the canonical implementation.

Classification: `MONEY_FORMAT_UNCERTAIN`.

## Envelope and errors

Mobile has `ApiResponse` and `PageResponse` contract helpers, but no network client uses them. Backend source has global exception handlers and response wrappers in both implementations; exact envelope and validation-error shape must be selected and recorded before network foundation.

Classification: `API_RESPONSE_ENVELOPE_UNCERTAIN`, `ERROR_CONTRACT_UNCERTAIN`.

## Enum comparison

| Enum | Backend evidence | Mobile | Result |
|---|---|---|---|
| BookingStatus | HOLDING/PENDING_PAYMENT/PAID/CANCELLED/EXPIRED evidence | Local enum | Needs exact reconciliation |
| PaymentStatus | Pending/success/failed lifecycle evidence | Local enum | Needs exact reconciliation |
| SeatStatus | Backend seat-map status exists | Local enum | Needs exact reconciliation |
| ShowtimeStatus | Backend showtime status exists | Local enum | Needs exact reconciliation |
| FoodOrderStatus | Backend standalone food lifecycle exists | No complete Mobile model | MOBILE_DTO_MISSING |
| RefundStatus | Backend refund/wallet behavior is split and customer refund is disputed | Preview only | CONTRACT_UNCERTAIN |
