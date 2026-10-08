# Customer Web → Flutter Parity Matrix

Status is based on the post-UI-B10 source and current presentation, not on compilation alone. `PARTIAL` means a corresponding mobile capability exists but meaningful visual, route-shape or interaction differences remain. `ACCEPTED_MOBILE_DIFFERENCE` means the remaining difference is an intentional mobile adaptation. `DEFER_BACKEND_UNSUPPORTED` means the Web capability is not safely supported by the current mobile/backend contract.

| Feature | Web screen / route | Mobile screen / route | Web source → mobile source | Parity | Backend | Visual / interaction differences | Decision |
|---|---|---|---|---|---|---|---|
| Home | Home `/` | Home `/home` | `HomePage.jsx` → `home_page.dart` | PARTIAL | SUPPORTED | Web editorial hero/sections vs Flutter native cards/shell; mobile route differs | RESTYLE |
| Discover | `/movies` | `/discover` | `ExplorePage.jsx` → `discover_page.dart` | PARTIAL | SUPPORTED | Web filters/grid/pagination richer; mobile search/filter is separate presentation | RESTYLE |
| Showtimes | `/showtimes` | `/showtimes` | `ShowtimesPage.jsx` → `showtimes_page.dart` | PARTIAL | SUPPORTED | Web grouped schedule and denser chips; Flutter date/schedule components differ | RESTYLE |
| Movie detail | `/movies/:id` | `/movie/:id` | `MovieDetailPage.jsx` → `movie_detail_page.dart` | PARTIAL | SUPPORTED | Web reviews/cast/recommendations/trailer richer; Flutter detail is narrower | REBUILD_PRESENTATION |
| Seat selection | `/movies/:id/book` embedded booking | `/seat-selection/:showtimeId` | `BookingPage.jsx` → `seat_selection_page.dart` | PARTIAL | SUPPORTED | Web multi-step booking shell vs Flutter dedicated seat route | RESTYLE |
| Concessions | `/concessions` | `/booking/:bookingId/concessions` | `ConcessionsPage.jsx` → `concessions_page.dart` | PARTIAL | SUPPORTED | Web supports standalone and booking contexts; mobile route is booking-scoped | RESTYLE |
| Checkout | embedded `/movies/:id/book` | `/booking/:bookingId/checkout` | `BookingPage.jsx` → `checkout_page.dart` | PARTIAL | SUPPORTED | Different step boundaries and summary layout | RESTYLE |
| Payment | `/payment-callback` plus booking UI | `/payment/:paymentId` | `PaymentCallbackPage.jsx`, `paymentService.js` → `payment_result_page.dart` | PARTIAL | SUPPORTED | Callback/return semantics differ; preserve launcher/repository | REBUILD_PRESENTATION |
| Ticket/history | `/tickets` | `/orders`, `/ticket/:bookingId` | `MyOrdersPage.jsx`, `MyTicketsPage.jsx` → orders/ticket pages | PARTIAL | SUPPORTED | Web combines history/ticket actions; Flutter splits list/detail | RESTYLE |
| Watchlist | `/watchlist` | `/preview/favorites` | `WishlistPage.jsx` → account route surface | DEFER_BACKEND_UNSUPPORTED | PARTIALLY_SUPPORTED | No confirmed dedicated mobile wishlist repository/persistence contract | DEFER_BACKEND_UNSUPPORTED |
| Profile | `/profile` | `/account/profile` | `ProfilePage.jsx` → account detail pages | PARTIAL | SUPPORTED | Web membership/wallet-rich hub; mobile account detail is simpler | RESTYLE |
| Policies | `/policies` | `/information/policies` | `PoliciesPage.jsx` → information pages | ACCEPTED_MOBILE_DIFFERENCE | SUPPORTED | Static purpose matches; Flutter uses a dedicated mobile route and compact shell presentation | ACCEPTED_MOBILE_DIFFERENCE |
| Auth modal | modal from shell/protected actions | `/auth/login`, `/auth/register`, `/auth/forgot-password` | `AuthModal.jsx` → `auth_page.dart` | ACCEPTED_MOBILE_DIFFERENCE | SUPPORTED | Web modal, Flutter full route; continuation and auth session are preserved | ACCEPTED_MOBILE_DIFFERENCE |
| Password setup | `/setup-password` | no confirmed equivalent | `GooglePasswordSetupPage.jsx` → — | MISSING_IN_MOBILE | SUPPORTED | Required customer auth recovery/setup screen absent from Flutter inventory | CREATE_MOBILE_SCREEN |
| Food order history | embedded `/concessions` history | no dedicated confirmed route | `FoodOrdersHistoryPage.jsx` → — | MISSING_IN_MOBILE | Web customer flow has standalone history; mobile preview/booking food only | CREATE_MOBILE_SCREEN |
| Cinema information | Home/header modal/link | `/information/cinema` | `HomePage.jsx`, `Header.jsx` → `information_pages.dart` | ACCEPTED_MOBILE_DIFFERENCE | SUPPORTED | Mobile has a dedicated route; Web uses sections/modal/link | ACCEPTED_MOBILE_DIFFERENCE |
| Support/chat | header/home affordance | `/support`, `/preview/popbot` | `Header.jsx`, `HomePage.jsx` → preview/account routes | DEFER_BACKEND_UNSUPPORTED | PARTIALLY_SUPPORTED | Mobile routes are not proven equivalent to the Web chat service | DEFER_BACKEND_UNSUPPORTED |
| Wallet | Profile/account surface | `/account/wallet` | `ProfilePage.jsx`, `walletService.js` → account pages | DEFER_BACKEND_UNSUPPORTED | PARTIALLY_SUPPORTED | Read-only/account presentation exists, but unsupported mutation scope is intentionally deferred | DEFER_BACKEND_UNSUPPORTED |
| Points/VIP | Profile/membership surface | `/account/points`, `/preview/vip` | `ProfilePage.jsx`, `loyaltyService.js` → account pages | DEFER_BACKEND_UNSUPPORTED | PARTIALLY_SUPPORTED | Read-only membership values are preserved; unsupported redemption/VIP actions are deferred | DEFER_BACKEND_UNSUPPORTED |
| Vouchers/promotions | Home/booking promotion UI | `/preview/vouchers` | Home/Booking pages → preview page | DEFER_BACKEND_UNSUPPORTED | PARTIALLY_SUPPORTED | Mobile is preview-only; no production promotion contract is claimed | DEFER_BACKEND_UNSUPPORTED |
| Notifications | no dedicated customer web route found | `/preview/notifications` | — → account route surface | DEFER_BACKEND_UNSUPPORTED | PARTIALLY_SUPPORTED | Mobile-only preview route has no Web parity target or proven backend contract | DEFER_BACKEND_UNSUPPORTED |
| Refund preview | order action/booking cancellation | `/preview/refund/:bookingId` | `MyOrdersPage.jsx` → preview page | DEFER_BACKEND_UNSUPPORTED | PARTIALLY_SUPPORTED | Customer paid-booking refund is intentionally not implemented | DEFER_BACKEND_UNSUPPORTED |

## Totals

Using the source inventories: 13 Web customer screen rows appear in `00`, and 28 distinct Flutter customer route paths appear in `01` (combined table cells are expanded by path). The matrix contains 22 parity entries because some rows intentionally combine related routes or decompose one composite Web flow into multiple mobile steps. Post-B10 matrix status counts are: MATCH 0, PARTIAL 10, ACCEPTED_MOBILE_DIFFERENCE 3, NEEDS_REWORK 0, MISSING_IN_MOBILE 2, DEFER_BACKEND_UNSUPPORTED 7.

The totals do not need to equal one another: Web `/movies/:id/book` is one route-backed composite flow represented by seat selection and checkout rows; `/concessions` contains food-order history; profile contains wallet/points/VIP surfaces; Home/header affordances cover cinema information and support/chat. Conversely, Flutter exposes separate routes for login/register/forgot-password, profile/security/wallet/points/VIP, cinema/policies/support, preview food, vouchers, PopBot and refund. Mobile-only and preview-only rows are retained so every current Flutter route is visible in the matrix. `ACCEPTED_MOBILE_DIFFERENCE` and `DEFER_BACKEND_UNSUPPORTED` are parity dispositions, not additional Web screens or Flutter routes.

## Flutter route coverage appendix

All 28 distinct route paths from `AppRoutes` are represented below. Routes marked mobile-only have no corresponding customer Web screen in `00`; they are not included in the Web-to-Mobile parity-status denominator.

| Flutter route | Matrix coverage |
|---|---|
| `/home` | Home |
| `/discover` | Discover |
| `/showtimes` (including `?movieId=:id`) | Showtimes |
| `/orders` | Ticket/history |
| `/account` | Account |
| `/auth/login`, `/auth/register`, `/auth/forgot-password` | Auth modal |
| `/account/profile` | Profile |
| `/account/security` | Mobile-only account route |
| `/account/wallet` | Wallet |
| `/account/points` | Points/VIP |
| `/information/cinema` | Cinema information |
| `/information/policies` | Policies |
| `/support` | Support/chat |
| `/preview/food` | Mobile-only preview route |
| `/preview/refund/:bookingId` | Refund preview |
| `/preview/vouchers` | Vouchers/promotions |
| `/preview/vip` | Points/VIP |
| `/preview/favorites` | Watchlist |
| `/preview/notifications` | Notifications |
| `/preview/popbot` | Support/chat |
| `/seat-selection/:showtimeId` | Seat selection |
| `/booking/:bookingId/concessions` | Concessions |
| `/booking/:bookingId/checkout` | Checkout |
| `/payment/:paymentId` | Payment |
| `/ticket/:bookingId` | Ticket/history |
| `/movie/:id` | Movie detail |
