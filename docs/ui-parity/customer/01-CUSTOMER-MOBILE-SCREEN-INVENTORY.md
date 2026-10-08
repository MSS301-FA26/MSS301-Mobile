# Customer Flutter Screen Inventory

Target inspected: `MSS301-Mobile/lib`. Routes come from `lib/core/routing/app_routes.dart` and `app_router.dart`; application integrations are preserved for future UI work.

| Feature | Screen / route | Dart files | Integration and current UI |
|---|---|---|---|
| Discovery | Home `/home` (root redirects here) | `features/home/presentation/pages/home_page.dart`, home widgets, `shared/widgets/app_shell.dart` | Catalog/showing content through Riverpod catalog providers; hero, quick actions, now showing/coming soon and shell navigation. |
| Discovery | Discover `/discover` | `features/discover/presentation/pages/discover_page.dart`, discover widgets | Catalog provider; search/filter controls and movie cards. |
| Scheduling | Showtimes `/showtimes`, `/showtimes?movieId=:id` | `features/showtime/presentation/pages/showtimes_page.dart`, `showtimes_provider.dart`, widgets | Remote showtime/catalog repository; date/cinema/movie schedule and login-gated seat entry. |
| Catalog | Movie `/movie/:id` | `features/movie/presentation/pages/movie_detail_page.dart`, `movies_provider.dart`, `trailer_preview_dialog.dart` | Remote catalog provider; detail, trailer and showtime CTA. |
| Booking | Seats `/seat-selection/:showtimeId` | `features/seat/presentation/pages/seat_selection_page.dart`, `seat_map_provider.dart`, seat-hold repositories, `booking_entry_session.dart` | Remote seat map and seat hold; countdown/selection/hold failure and next-step flow. |
| Booking | Concessions `/booking/:bookingId/concessions` | `features/booking/presentation/pages/concessions_page.dart` | Booking repository and catalog/food quote path; cart and continue to checkout. |
| Booking | Checkout `/booking/:bookingId/checkout` | `features/booking/presentation/pages/checkout_page.dart`, booking completion controller | Remote checkout quote/booking repository; summary and payment initiation. |
| Payment | Payment `/payment/:paymentId` | `features/booking/presentation/pages/payment_result_page.dart`, payment repositories, payment launcher | Remote/mock selectable payment repository; result, retry and ticket continuation. |
| Ticketing | Ticket `/ticket/:bookingId` | `features/booking/presentation/pages/ticket_page.dart` | Remote booking detail; QR/ticket presentation and navigation to orders. |
| Ticketing | Orders `/orders` | `features/orders/presentation/pages/orders_page.dart`, orders provider/widgets, booking repositories | Remote booking history; tabs, order cards, ticket, rebook and refund preview. |
| Account/Auth | Account `/account` | `features/account/presentation/pages/account_page.dart`, account widgets/providers | Account summary repository; guest login/register entry or authenticated account menu. |
| Account/Auth | Login `/auth/login`, Register `/auth/register`, Forgot password `/auth/forgot-password` | `features/auth/presentation/pages/auth_page.dart`, auth guard, auth repositories/session | Remote auth repository with auth session/token storage; continuation redirect and validation states. |
| Account | Profile `/account/profile` | `features/account/presentation/pages/account_detail_pages.dart` | Account repository; profile view/update presentation. |
| Account | Security `/account/security` | `features/account/presentation/pages/account_detail_pages.dart` | Account/auth repository; password/security UI. |
| Account | Wallet `/account/wallet`, Points `/account/points`, VIP `/preview/vip` | `features/account/presentation/pages/account_page.dart`, account widgets/repositories | Wallet/loyalty presentation; verify each remote contract before enabling mutations. |
| Account | Favorites `/preview/favorites` | account page/widgets; repository availability is not a dedicated mobile feature | Presentation route exists; customer backend support and persistence need verification. |
| Account | Notifications `/preview/notifications` | account route surface; no dedicated notification page in inspected feature list | Route exists in router but appears preview/incomplete; do not assume parity. |
| Information | Cinema info `/information/cinema`, Policies `/information/policies`, Support `/support` | `features/account/presentation/pages/information_pages.dart` | Static/information screens within AppShell. |
| Food | Preview food `/preview/food` | `features/preview/presentation/pages/preview_feature_page.dart` | Preview/demo route; not equivalent to production concessions without contract confirmation. |
| Experimental | Vouchers `/preview/vouchers`, PopBot `/preview/popbot`, refund preview `/preview/refund/:bookingId` | `features/preview/presentation/pages/preview_feature_page.dart` and orders flow | Route surfaces exist, but should be treated as preview/unsupported until concrete customer contract is proven. |

## Shared/current mobile foundation

`AppShell`, `CinemaBottomNav`, `CinemaHeader`, `AppButton`, `AppImage`, `AppSectionHeader`, `AgeBadge`, `CinemaInfoSheet`, Riverpod providers and repository abstractions are the reusable foundation. Current application states include loading/error/empty handling in feature pages, but visual parity with the web shell is partial: Flutter uses Material dark theme, Inter, gold/purple tokens and rounded cards while web uses a more editorial black/white/amber treatment.
