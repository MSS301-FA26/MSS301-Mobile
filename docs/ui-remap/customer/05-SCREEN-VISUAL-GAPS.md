# Screen-by-Screen Visual Gaps

Source-level audit, not screenshot pixel comparison. “Current Mobile” reflects registered page/widget composition and source state. Desktop patterns are translated to mobile; accepted modal→page, table→list, sidebar→drawer and wide→stacked adaptations are not counted as gaps by themselves.

## PARTIAL screens

### Home — P1
Web: `HomePage` in `UserLayout`; featured `HeroBannerCarousel`, `QuickBookingBar`, movie rails/cards and footer.
Mobile: `HomePage`, `HeroCard`, `QuickActions`, `NowShowingCard`, `ComingSoonCard` in `AppShell` with bottom navigation.
Gaps: compare hero prominence and image crop; make featured CTA and section progression obvious at phone width; normalize section spacing/card metadata; check loading/empty/error compositions. Keep the native bottom navigation and quick-action concept.

### Discover/search — P1
Web: Header search enters `/movies`; `ExplorePage` combines movie browsing, search, filters and pagination.
Mobile: `DiscoverPage` with `SearchBar`, `SegmentedControl`, `FormatFilterChips`, `DiscoverMovieCard`.
Gaps: align search/filter/result hierarchy, selected-chip contrast, compact result metadata, pagination/load-more feedback and empty/error affordances. Keep API search, debounce, genre/status IDs and pagination unchanged.

### Movie detail (reviews/recommendations) — P1
Web: `MovieDetailPage` with cinematic image/metadata, synopsis, reviews/recommendation areas and showtime booking action.
Mobile: `MovieDetailPage` with real catalog detail, review and recommendation providers plus trailer preview.
Gaps: validate title/meta readability against backdrop; order synopsis, cast/trailer, reviews, recommendations and showtime CTA for mobile; avoid burying primary booking action; normalize poster/backdrop ratios and loading/empty/error states. Keep review/recommendation repositories and showtime navigation.

### Cinema/showtimes — P1
Web: `ShowtimesPage` offers cinema/date/movie selection and a dense grouped showtime list.
Mobile: `ShowtimesPage` with movie/date selectors and `ShowtimeStatusCard`.
Gaps: make chosen cinema/date context persist visibly; distinguish unavailable/status states without color alone; group showtimes with enough tap area and keep selected movie context. Keep backend IDs, filters and showtime navigation.

### Seat selection — P0
Web: embedded `BookingPage` step with dense map, legend, seat prices, zoom/pan and summary.
Mobile: dedicated `SeatSelectionPage`, real seat map, hold timer and conflict refresh/reconciliation.
Gaps: dense map scaling/scroll affordance; legible legend and selected/unavailable distinction; keep price/selected-seat summary and CTA reachable; show hold countdown and recoverable conflict/error without obscuring map. Keep seat map, hold timer/expiry, bookingId, conflict recovery and real seat IDs.

### Booking-attached concessions — P1
Web: food selection embedded in `BookingPage` with booking context, quantity/price and continue flow.
Mobile: dedicated `/booking/:bookingId/concessions` route.
Gaps: keep booking context and total visible; improve product image/title/quantity control alignment and sticky continuation affordance; clear empty/loading/error state. Keep bookingId, food IDs, remote quote flow and totals.

### Checkout quote — P0
Web: `BookingPage` quote/summary and confirmation state within long stepper.
Mobile: dedicated `CheckoutPage` driven by real backend quote and booking snapshot.
Gaps: prioritize amount due and itemized breakdown; separate server totals from editable-looking choices; ensure points/food/seats summary and payment CTA scan in one pass; handle refresh/loading/error without stale-looking quote. Keep backend quote, totals, booking snapshot and point redemption contract.

### Payment/result — P1
Web: payment states in `BookingPage` then `/payment-callback` verifies/polls booking or standalone food order return.
Mobile: `/payment/:paymentId` remote `PaymentResultPage`.
Gaps: clearly distinguish pending vs success vs failure, keep retry/return actions contextual, present payment reference without visual noise, and ensure deep-link return does not look like a final result before backend verification. Keep VNPay invocation, status polling/refresh and deep-link behavior.

### Ticket/QR — P1
Web: `/tickets` contains booking details and QR states in `MyTicketsPage`.
Mobile: dedicated `/ticket/:bookingId` `TicketPage`.
Gaps: QR contrast/size and quiet zone, booking status and showtime/seat scan order, screen brightness/scan guidance, and unavailable/expired states. Keep QR payload and backend ticket state; no mock QR.

### Booking history/detail — P1
Web: `/tickets` ticket tab with expandable/detail actions, status, QR and eligible review actions.
Mobile: `/orders` remote history/detail.
Gaps: status hierarchy, concise cinema/showtime/seat summary and detail affordance; verify long IDs/date wrapping and empty/error/retry consistency. Card list replacing table/grid is accepted. Keep server history/detail, status, cancellation and review eligibility/actions.

### Account/profile — P1
Web: `/profile` combines profile, security, preferences and summary panels.
Mobile: `/account` plus `/account/profile` and `/account/security`.
Gaps: make the account landing page clearly orient users to profile/security/wallet/points/orders; unify avatar/name/metadata and save/error feedback. Route split is accepted. Keep auth guard, profile repository, field validation and security behavior.

## Accepted mobile adaptations (polish only, P2/P3)

- Standalone food history is a dedicated `/account/food-orders` route rather than the Web `/tickets` tab. Preserve QR/order state; tune card density only.
- Login, register and forgot-password change Web overlay states into dedicated native pages. Preserve registration verification and password recovery steps.
- Wallet and loyalty are dedicated native account routes rather than embedded Web profile panels. Keep remote account data and redeem mutation.
- Policies/support/cinema information use native informational routes; desktop footer placement is not a parity requirement.

## Deferred / missing presentation

- Standalone food ordering: current Mobile `/preview/food` uses provisional UI; no real production ordering screen is registered. The backend integration source contains standalone food create/history operations; verify current public route/auth/contract before building a production screen.
- Watchlist: Mobile `/preview/favorites` is provisional. Do not implement production watchlist without verified public customer contract.
- Google password setup has a Web-only route. Defer until the Mobile auth contract requires and supports the same customer flow.

## State review checklist for each visual batch

For each touched screen capture/review loading, populated, empty, API error/retry, validation error, disabled/submitting, and success states applicable to that screen. This document does not establish that every state can be reproduced from the currently running backend.
