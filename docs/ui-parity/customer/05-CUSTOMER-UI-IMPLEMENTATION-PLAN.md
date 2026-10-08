# Customer UI Implementation Plan (No implementation in this audit)

## Batches

| Batch | Goal | Screens | Expected Flutter files | Integration-sensitive files | Risks | Acceptance criteria |
|---|---|---|---|---|---|---|
| UI-B01 Design tokens | Establish customer visual primitives | All customer screens | `lib/core/theme/app_colors.dart`, `app_theme.dart`, `app_text_styles.dart`, `app_spacing.dart` | Avoid repositories/providers/controllers, `app_router.dart`, feature data | Global regressions and contrast drift | Token previews cover background/surface/text/accent/disabled/focus; no API or route behavior changes. |
| UI-B02 Shared widgets | Remove duplicated presentation | Cards, buttons, chips, states, dialogs, summaries | `lib/shared/widgets/*` plus new shared widgets | Do not alter repository calls or DTOs | Over-generalized variants | Widget catalog used by at least Home, Discover, Showtimes, Booking, Account. |
| UI-B03 AppShell/customer navigation | Match web header/footer/navigation | Home, Discover, Showtimes, Orders, Account | `app_shell.dart`, `cinema_header.dart`, `cinema_bottom_nav.dart`, `cinema_info_sheet.dart` | `app_router.dart` only for presentation shell wiring; preserve guards | Navigation regressions | Active tab, search, account, auth continuation and back behavior verified. |
| UI-B04 Home/Discover | Match editorial catalog surfaces | `/home`, `/discover` | home/discover pages and widgets | `movies_provider.dart`, catalog repositories read-only | Loading/pagination mismatch | Hero/cards/filters use shared tokens; real catalog remains intact. |
| UI-B05 Movie/Showtime | Match detail and schedule discovery | `/movie/:id`, `/showtimes` | movie/showtime pages/widgets | `movies_provider.dart`, `showtimes_provider.dart`, catalog/showtime repositories | Showtime IDs and deep links | Detail → showtime → seat preserves IDs/query state. |
| UI-B06 Seat Selection | Match seat map and hold feedback | `/showtimes/:id/seats` | `seat_selection_page.dart`, seat widgets | `seat_map_provider.dart`, seat hold repositories, booking session | Hold expiry/selection mutation | Real seat map, hold, release/expiry and totals remain unchanged. |
| UI-B07 Checkout/Payment | Match summary, payment and result | concessions, checkout, payment | booking pages/widgets | booking completion, payment repositories/launcher, booking providers | Payment redirect and duplicate completion | Quote, payment initiation/result and retry remain contract-compatible. |
| UI-B08 Tickets/History/Detail | Match ticket and history hierarchy | orders/ticket | orders/ticket pages/widgets | booking repositories/providers | QR/status/cancel semantics | Real booking list/detail and QR data preserved. |
| UI-B09 Account/Profile/Auth | Match profile and auth entry | account/profile/security/auth | account/auth pages/widgets | auth session, token storage, account repositories | Guard/continuation and sensitive mutation | Login/register/reset/profile update preserve current remote calls. |
| UI-B10 States/consistency | Final cross-screen visual QA | All | shared state widgets and affected pages | No contract changes | Inconsistent edge states | Loading/empty/error/success/disabled/focus states documented and tested visually. |

## Recommended order

UI-B01 → UI-B02 → UI-B03 → UI-B04 → UI-B05 → UI-B06 → UI-B07 → UI-B08 → UI-B09 → UI-B10.

## UI-B01 exact expected file scope

Expected to change only:

- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/theme/app_text_styles.dart`
- `lib/core/theme/app_spacing.dart`

Potentially add token-only tests under `test/` only after approval; this audit does not modify tests.

UI-B01 must avoid all providers, controllers, repositories, DTOs, API/network files, `lib/core/routing/*`, platform files, assets, `pubspec.*`, and feature pages/widgets.
