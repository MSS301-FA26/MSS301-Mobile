# Business Logic Protection Map

This audit authorizes no code changes. The following map is a guardrail for a future Mobile-only visual remap. Keep business data flows and decisions intact while changing composition, styling, accessibility, and responsive layout.

| Screen / flow | KEEP unchanged | UI-only work allowed |
|---|---|---|
| Home | Remote movie/banner data, status semantics, route IDs and booking CTA decisions | Hero crop/height, section order, spacing, card styling and state layout. |
| Discover/search | Real search API, debounce, query normalization, genre IDs, status/format filters, pagination and result mapping | Search/filter placement, chips, result card density, keyboard and empty/error presentation. |
| Movie detail | Backend movie IDs/detail, review/recommendation repositories, review eligibility/actions, trailer handling and showtime navigation | Media hierarchy, metadata grouping, section order and CTA visibility. |
| Showtimes | Showtime/cinema IDs, dates, availability/status, query selection and seat-selection navigation | Date selector, grouping, status-chip presentation and tap target size. |
| Seat selection | Real seat map and IDs, selection rules, hold API, hold expiry/timer, conflict refresh/reconciliation, bookingId | Map viewport/legend layout, selected/unavailable visuals, sticky summary and responsive geometry. |
| Booking-attached food | BookingId, real catalog/food IDs, quantity/payload mapping and quote inputs | Product cards, quantity controls, summary layout and CTA placement. |
| Standalone food (future only) | Existing API contract/auth, order IDs, payment/QR/status/cancel behavior; do not route preview data into production | No implementation under this audit. Future screen only after contract verified and separately authorized. |
| Checkout | Backend quote request, authoritative totals/discounts/fees, booking snapshot, point redemption input semantics | Summary hierarchy, typography, grouping, loading/error and CTA layout. |
| Payment / VNPay | Payment creation, VNPay launch/return/deep links, payment ID/status, verification/polling and retry semantics | Pending/success/failure composition, action visibility, reference details. Never display fabricated success. |
| Ticket / QR | Booking/ticket identity, QR payload, backend status and scan validity | QR size/contrast, showtime/seats/status order and accessibility labels. |
| Booking history/detail | Remote customer query, IDs, server statuses, cancellation rules, review eligibility and mutations | Card/list hierarchy, detail expansion and responsive metadata. |
| Standalone food history | Remote food-order history, QR/order state, cancellation/payment rules | Native dedicated route/list cards and state presentation. |
| Auth | Token/session lifecycle, auth guard, register verification, recovery steps, redirect/continue behavior | Native forms, keyboard handling, stepper and validation layout. |
| Account/profile/security | Authenticated account identity, remote profile/security operations and validation | Account navigation grouping, form layout and feedback treatment. |
| Wallet | Remote wallet/transaction/withdrawal repository, authoritative amounts and request payloads | Balance card, transaction list density and status presentation. |
| Loyalty/redeem | Remote points/config, redemption request, eligibility/limits, mutation and refresh after success | Points hierarchy, redemption control and success/error feedback. Never optimistically invent balance. |
| Policies/information | Existing content/URLs and route access | Native sections, typography and layout. |
| Preview-only routes | Keep provisional features clearly marked and separated; do not use preview repository in production flows | May remain preview; no visual remap can imply real capability. |

## Guardrails for review

1. UI diffs must not change endpoint strings, request/response mapping, repository/provider/controller behavior, backend identifiers, auth headers, or route destinations.
2. Do not convert client-computed values into authority where the current contract uses a backend quote/status.
3. Do not remove loading, empty, error, conflict, expiry, disabled, or retry states while simplifying layout.
4. Keep a clear visual distinction between production API-backed screens and provisional preview destinations.
5. Any discovery that requires a new endpoint, contract, security rule, or business decision is a stop-and-escalate item, not an implied UI-remap scope expansion.
