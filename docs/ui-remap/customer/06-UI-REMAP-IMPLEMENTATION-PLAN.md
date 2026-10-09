# Mobile UI Remap Implementation Plan

Mobile-only follow-up plan derived from current source. Do not begin until this audit is accepted. All work is presentation/layout/accessibility only unless an explicitly authorized separate task changes scope.

| Batch | Screens | Likely Mobile files | Web reference | Visual goals | Protected logic | Acceptance criteria |
|---|---|---|---|---|---|---|
| UI-R01 — tokens/shared UI | Shared surfaces/buttons/text/navigation/states | `lib/core/theme/*`; `lib/shared/widgets/*` | `src/index.css`, `src/components/common/*`, `src/layouts/UserLayout.jsx` (reference only) | Define semantic colors, type/spacing/radius usage; consistent card/button/input/chip/loading/empty/error states; retain native navigation. | No routes, API, provider, repository or business behavior changes. | Token/widget preview has readable contrast, proper touch targets and reduced-motion behavior; existing tests/analyze remain green. |
| UI-R02 — home | `/home` | `features/home/presentation/pages/home_page.dart`, `features/home/presentation/widgets/*` | `HomePage`, `HeroBannerCarousel`, `QuickBookingBar`, `MovieCard` | Mobile hero hierarchy, media crop, section rhythm, movie metadata/CTA and state panes. | Movie source/status, booking navigation, hero data and quick actions. | Narrow and large phone layouts show primary CTA; populated/loading/empty/error states are clear. |
| UI-R03 — discover/search | `/discover` | `features/discover/presentation/pages/discover_page.dart`, `features/discover/presentation/widgets/*` | `ExplorePage`, Web Header search | Consistent search/filter/results hierarchy, active filters, cards and pagination feedback. | Search endpoint/debounce, genre IDs, status/format filters, pagination and result mapping. | Search and filter states are visually clear; no behavior/API regression; empty/error/retry reviewed. |
| UI-R04 — movie detail | `/movie/:id` | `features/movie/presentation/pages/movie_detail_page.dart`, related widgets | `MovieDetailPage` | Poster/backdrop, metadata, synopsis, cast/trailer, reviews/recommendations, visible showtime CTA. | Detail/review/recommendation repositories, IDs, review actions, showtime navigation. | Long detail remains scannable; CTA and review states accessible; real data preserved. |
| UI-R05 — cinemas/showtimes | `/showtimes` | `features/showtime/presentation/pages/showtimes_page.dart`, widgets | `ShowtimesPage`, `QuickBookingBar` | Persistent cinema/date context, grouping, status and tap targets. | Real cinema/showtime IDs, selection and navigation. | User can identify selected context and available showtimes at phone width; state semantics preserved. |
| UI-R06 — seat selection | `/seat-selection/:showtimeId` | `features/seat/presentation/pages/seat_selection_page.dart`, seat widgets | Seat step in `BookingPage` | Map scaling/legend, selected/unavailable distinction, summary and timer/CTA placement. | Seat map, hold, expiry, bookingId, conflict refresh/reconciliation and seat IDs. | Dense layouts remain operable; hold timer/conflict/error states remain visible and test-covered. |
| UI-R07 — food/checkout | `/booking/:bookingId/concessions`, `/booking/:bookingId/checkout` | `features/booking/presentation/pages/concessions_page.dart`, `checkout_page.dart`, shared booking widgets | Food/quote steps in `BookingPage`; `ConcessionsPage` | Product selection, quantities, summary, totals and primary continuation/payment CTA. | Booking context, food IDs, checkout quote, total calculation source, loyalty redeem/refresh. | UI only rearranges presentation; server quote is authoritative; regression tests cover actions/state. |
| UI-R08 — payment/ticket/history | `/payment/:paymentId`, `/ticket/:bookingId`, `/orders`, `/account/food-orders` | `features/booking/presentation/pages/*`, `features/orders/presentation/pages/orders_page.dart`, `features/food/presentation/pages/food_orders_history_page.dart` | `PaymentCallbackPage`, `MyTicketsPage`, `MyOrdersPage`, `FoodOrdersHistoryPage` | Result-state clarity, scannable ticket QR, status hierarchy, concise history cards and retry/empty states. | VNPay/deep links/status, ticket QR payload, booking/food history, cancel/review eligibility. | No early “success” before confirmed state; QR and status stay legible; history operations unchanged. |
| UI-R09 — account/profile/auth | `/account`, profile/security and auth modes | `features/account/presentation/pages/*`, `features/auth/presentation/pages/auth_page.dart`, account widgets | `ProfilePage`, `AuthModal`, `GooglePasswordSetupPage` | Clear account destinations, coherent profile form, keyboard/validation feedback and native auth steps. | Auth session, auth guard, profile updates/security actions and redirects. | Login/register/recovery remain functional; no auth gating/session changes. Google setup remains deferred absent contract decision. |
| UI-R10 — wallet/loyalty | `/account/wallet`, `/account/points` | `features/account/presentation/pages/account_detail_pages.dart`, `features/account/presentation/widgets/*` | Wallet/loyalty panels in `ProfilePage` | Balance/points emphasis, transaction hierarchy, redeem form feedback, expiry/config detail. | Remote wallet/transactions/withdrawal, loyalty config, redeem mutation and backend refresh. | Amounts/points remain backend-derived; success/error/refresh behavior unchanged. |
| UI-R11 — responsive/polish | All production customer screens | Existing screen/widget files identified in prior batches | Web customer source, desktop/mobile breakpoints | Cross-screen typography, spacing, image, error/loading, keyboard, accessibility and responsive consistency. | No business behavior changes; do not convert preview routes to real features without separate approved contract task. | Manual device-size review plus `flutter analyze`, full `flutter test`, diff check; confirm only intended UI files changed. |

## Recommended first implementation batch

Start with **UI-R01**, then UI-R02. Establishing shared semantic styles makes subsequent screen remaps consistent; use existing widgets first rather than wholesale rewriting screens. Before implementation, review and accept this audit, then keep each batch isolated and run targeted tests after each logic-adjacent UI slice.

## Priority counts across the 21 Web screen/flow units

- P0: 2 — seat selection, checkout quote.
- P1: 11 — home, discover/search, movie detail, cinema/showtimes, booking-attached concessions, standalone food (deferred), payment/result, ticket/QR, booking history/detail, account/profile, watchlist (deferred).
- P2: 7 — standalone food history, login, register, forgot password, wallet, loyalty/redeem, Google password setup (deferred).
- P3: 1 — policies/information.

## Boundaries

- Backend changes required: NO.
- Frontend changes required: NO; Web remains visual reference.
- Mobile production code is unchanged by this audit.
- Standalone food production UI is the only currently identified supported-but-missing Mobile screen; verify current public contract/auth and get a separately scoped implementation task before adding it.
- Wishlist and Google password setup remain deferred pending contract/flow verification.
