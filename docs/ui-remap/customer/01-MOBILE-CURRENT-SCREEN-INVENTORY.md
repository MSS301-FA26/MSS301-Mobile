# Current Mobile Customer UI Inventory

Audit date: 2026-10-09. Source inspected read-only in `MSS301-Mobile/lib/core/routing/` and `lib/features/`.

## Counting rule

Count registered, non-preview customer production destinations (distinct auth modes counted separately); **22 Mobile customer screens**. Preview-only routes are inventoried afterwards but excluded from production count. Web screen equivalence is a mapping, not a claim that the layouts are identical.

## Production screen inventory

| # | Route | Page widget | Feature | Data / state handling | Main shared widgets / Web equivalent |
|---:|---|---|---|---|---|
| 1 | `/home` | `HomePage` | home | Remote catalog/providers; page-level repository states | `AppShell`, `CinemaHeader`, `CinemaBottomNav`, `HeroCard`, `NowShowingCard`, `ComingSoonCard`, `QuickActions`; Web `/`. |
| 2 | `/discover` | `DiscoverPage` | discover | Remote catalog, search/filter/pagination state | `DiscoverMovieCard`, `SearchBar`, `SegmentedControl`, `FormatFilterChips`; Web `/movies`. |
| 3 | `/movie/:id` | `MovieDetailPage` | movie | Remote detail, reviews, recommendations and showtime navigation | `TrailerPreviewDialog`, shared surfaces/buttons; Web `/movies/:id`. |
| 4 | `/showtimes?movieId=` | `ShowtimesPage` | showtime | Remote showtime/cinema data, date and selection states | `ShowtimeMovieCard`, `ShowtimeStatusCard`, date selector; Web `/showtimes` and booking pre-step. |
| 5 | `/seat-selection/:showtimeId` | `SeatSelectionPage` | seat | Real seat map and hold lifecycle; selected seats, conflict refresh, expiry | Shared state panes/surfaces; Web `BookingPage` seat step. |
| 6 | `/booking/:bookingId/concessions` | `ConcessionsPage` | booking | Booking-attached catalog/order flow | Shared buttons/surfaces; Web `BookingPage` food step. |
| 7 | `/booking/:bookingId/checkout` | `CheckoutPage` | booking | Real quote and booking snapshot | Shared summary/surface widgets; Web `BookingPage` checkout step. |
| 8 | `/payment/:paymentId` | `PaymentResultPage` | booking/payment | Remote payment status and result states | Shared state panes; Web payment states and callback. |
| 9 | `/ticket/:bookingId` | `TicketPage` | booking | Booking completion/ticket/QR state | Shared surfaces/buttons; Web ticket/QR inside `/tickets`. |
| 10 | `/orders` | `OrdersPage` | orders | Remote booking history/detail and order actions | `RepositoryStatePane`, order cards/tabs; Web `/tickets` ticket tab. |
| 11 | `/account/food-orders` | `FoodOrdersHistoryPage` | food | Remote standalone food order history and state | Food order card/state UI; Web `/tickets` food tab. |
| 12 | `/account` | `AccountPage` | account | Auth-gated summary/menu | `AccountMenu`, `ProfileCard`, `MembershipCard`; Web `/profile` overview. |
| 13 | `/account/profile` | `ProfileEditPage` | account | Remote profile load/save and validation | `AppButton`, `AppSurface`; Web `/profile` profile panel. |
| 14 | `/account/security` | `SecurityPage` | account/auth | Auth-gated security view/actions | Shared form/surface widgets; Web account security panel where present. |
| 15 | `/account/wallet` | `WalletPage` | account/wallet | Remote balance, transaction and withdrawal state | Shared cards/state panes; Web wallet panel in `/profile`. |
| 16 | `/account/points` | `PointsPage` | account/loyalty | Remote loyalty/config, redeem mutation and refresh | Shared surfaces/buttons/chips; Web loyalty panel in `/profile`. |
| 17 | `/auth/login` | `AuthPage(login)` | auth | Remote auth, loading/error/validation | Shared app widgets; Web AuthModal login mode. |
| 18 | `/auth/register` | `AuthPage(register)` | auth | Remote registration/verification state | Shared app widgets; Web AuthModal register mode. |
| 19 | `/auth/forgot-password` | `AuthPage(forgotPassword)` | auth | Remote recovery and validation state | Shared app widgets; Web AuthModal forgot mode. |
| 20 | `/information/cinema` | `InformationPage(cinema)` | information | Informational content state | Shared app shell/surfaces; no direct Web destination in current route table. |
| 21 | `/information/policies` | `InformationPage(policies)` | information | Informational content | Shared app shell/surfaces; Web `/policies`. |
| 22 | `/support` | `InformationPage(support)` | information | Support/information content | Shared app shell/surfaces; no direct Web destination in current route table. |

## Preview-only routes (not production capability/screens for parity count)

`/preview/food`, `/preview/refund/:bookingId`, `/preview/vouchers`, `/preview/vip`, `/preview/favorites`, `/preview/notifications`, `/preview/popbot` map to `PreviewFeaturePage`/`PopBotPreviewPage` and `ProvisionalPreviewRepository`. Do not present these as real API-backed production implementations or as evidence that standalone food ordering, refunds, vouchers, watchlist, notifications, or chatbot are complete.

## Shared design widgets

`AppButton`, `AppChip`, `AppImage`, `AppSectionHeader`, `AppShell`, `AppSurface`, `CinemaBottomNav`, `CinemaHeader`, `CinemaInfoSheet`, `RepositoryStatePane`; design tokens in `lib/core/theme/app_colors.dart`, `app_spacing.dart`, `app_text_styles.dart`, `app_theme.dart`. Feature widgets are listed in the table and component map.
