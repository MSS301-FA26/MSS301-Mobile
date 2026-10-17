# Current Web Customer UI Inventory

Audit date: 2026-10-09. Source inspected read-only in `MSS301-Frontend` at `src/routes/AppRoutes.jsx`, `src/layouts/UserLayout.jsx`, `src/layouts/Header.jsx`, `src/pages/user/`, `src/pages/auth/`, and `src/components/common/`.

## Counting rule

Count customer destinations and meaningfully distinct customer flows, not every React component or transient loading/error state. Embedded panels/steps are listed separately when they have a distinct customer capability. This yields **21 Web customer screen/flow units** for the parity matrix. Admin, manager, and staff routes are excluded. `/book` is only a redirect. `FoodOrdersHistoryPage` is embedded as a tab in `/tickets`, not its own route.

## Screen inventory

| # | Web route / entry | Actual page / UI | Layout / reusable UI | Relevant states and observations |
|---:|---|---|---|---|
| 1 | `/` | `HomePage` via `HomeRoute` | `UserLayout`, `Header`, `Footer`, `HeroBannerCarousel`, `QuickBookingBar`, `MovieCard` | Hero, now-showing/coming-soon sections, quick booking, loading/empty/error surfaces; live movie data. |
| 2 | `/movies` | `ExplorePage` | User shell, shared movie cards and filters | Query search, genre/status filters, pagination; `Header` commits search to this route. |
| 3 | `/movies/:id` | `MovieDetailPage` | User shell, common buttons/modal, movie surfaces | Detail, showtime CTA, reviews and recommendation regions; inspect actual conditional content rather than infer standalone routes. |
| 4 | `/showtimes` | `ShowtimesPage` | User shell, common buttons/empty/loading | Cinema/date/movie/showtime selection; actual showtime list and empty/error branches. |
| 5 | `/movies/:id/book` | `BookingPage` — seat-selection step | User shell; page-local seat map, seat/status/price UI | Showtime selection may be an earlier step; seat map loading, refresh/error, selected seats, zoom/pan, seat conflict/availability. No dedicated Web seat route. |
| 6 | same | `BookingPage` — booking/concessions step | Page-local cards/forms | Ticket and food selection, loyalty points input, booking details and continue CTA. This is booking-attached food, not standalone food sales. |
| 7 | same | `BookingPage` — checkout/quote step | Page-local summary and actions | Quote/price breakdown, discounts/points and confirmation; amount is business data, not a visual token. |
| 8 | same | `BookingPage` — payment method/processing/result states | Page-local payment panels | Payment method, processing, failed/success states; `/payment-callback` handles provider return separately. |
| 9 | `/concessions` | `ConcessionsPage` | User shell, common components | Standalone food catalog/order flow; distinct from booking-attached concessions. |
| 10 | `/payment-callback` | `PaymentCallbackPage` | Standalone callback result page | Booking and food-order return paths, verification/polling, loading/success/failure and return CTAs. |
| 11 | `/tickets` | `MyOrdersPage` tab: tickets | User shell; `MyTicketsPage` embedded | Booking/ticket history, booking/ticket detail expansion, QR states, cancellation/resume/review actions. |
| 12 | `/tickets` | `MyOrdersPage` tab: food orders | `FoodOrdersHistoryPage` embedded | Standalone food order history, payment/pickup QR and status/cancel states; not a separate route. |
| 13 | `/profile` | `ProfilePage` account overview/profile panels | User shell, page-local profile sections, modal/panels | Profile data/edit, security and other account panels; page loads customer-specific wallet/loyalty summaries. |
| 14 | `/profile` | `ProfilePage` wallet panel | Embedded panel in profile | Wallet balance and transaction presentation; do not mistake an embedded panel for an independent route. |
| 15 | `/profile` | `ProfilePage` loyalty/redeem panel | Embedded panel in profile | Points/configuration, redemption input/action and refresh states. |
| 16 | `/watchlist` | `WishlistPage` | User shell; Header also has a watchlist drawer | Saved movies, empty/populated states, remove and book actions. |
| 17 | UserLayout `AuthModal` | Login mode | Shared overlay modal | Password/OTP and Google-related states, validation, errors, busy state. Not a standalone route. |
| 18 | UserLayout `AuthModal` | Register mode | Shared overlay modal | Registration form and verify-email step; success/error/busy states. |
| 19 | UserLayout `AuthModal` | Forgot-password mode | Shared overlay modal | Email, OTP verification and new-password steps. |
| 20 | `/setup-password` | `GooglePasswordSetupPage` | Dedicated auth page (outside `UserLayout`) | Required-password setup and validation after Google auth. |
| 21 | `/policies` | `PoliciesPage` | User shell, common UI | Policy/information sections, primarily read-only. |

## Shared UI and states (not additional screen units)

- `UserLayout`: customer page shell, Header/Footer, toast, auth modal, watchlist drawer; role-based redirect/visibility is shared behavior.
- `Header`: desktop navigation, responsive mobile menu, search, cinema selection, account actions and loyalty summary. The Web mobile menu is still Web UI, not the native Mobile navigation target.
- Common components: `Button`, `Modal`, `LoadingState`, `EmptyState`, `MovieCard`, `HeroBannerCarousel`, `QuickBookingBar`, `Toast`, and `Table` (`src/components/common/`).
- Page state vocabulary evidenced by implementation includes pending/loading, empty, API error, validation error, selected/active, submitting, payment processing/success/failure, no seats/seat conflict, no bookings/orders, and QR unavailable/expired. Not every page has all states; remap should retain each page's existing state semantics.
- Other actual Web sources found: `MyTicketsPage` (ticket/QR/review UI embedded in orders), `FoodOrdersHistoryPage` (embedded order tab), `AuthModal`, and password setup. `ProfilePage` embeds wallet and loyalty UI; no distinct Web `/wallet` or `/loyalty` route is defined in `AppRoutes.jsx`.

## Explicit exclusions / caveats

- `AppRoutes.jsx` also registers `/staff`, `/admin/*`, `/manager/*`; these are operational/backoffice, not customer screens.
- `WishlistPage` is customer-facing; its backend support is assessed separately and must not be assumed from the UI alone.
- The source contains no dedicated customer Web routes for cinema detail, seat map, checkout, ticket, food history, wallet, or loyalty: these are either embedded flows/panels or are represented inside another page.
- This is a source inventory, not a runtime visual capture. Browser breakpoints, live backend data and viewport-specific appearance were not separately measured.
