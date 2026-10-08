# Customer Web → Flutter Parity Matrix

Status is based on source structure and current presentation, not on visual similarity alone. `PARTIAL` means a corresponding mobile capability exists but presentation, route shape or interaction differs.

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
| Watchlist | `/watchlist` | `/preview/favorites` | `WishlistPage.jsx` → account route surface | NEEDS_REWORK | SUPPORTED | Mobile route exists but no confirmed dedicated wishlist repository/page parity | REBUILD_PRESENTATION |
| Profile | `/profile` | `/account/profile` | `ProfilePage.jsx` → account detail pages | PARTIAL | SUPPORTED | Web membership/wallet-rich hub; mobile account detail is simpler | RESTYLE |
| Policies | `/policies` | `/information/policies` | `PoliciesPage.jsx` → information pages | MATCH | SUPPORTED | Static purpose matches; styling differs | RESTYLE |
| Auth modal | modal from shell/protected actions | `/auth/login`, `/auth/register`, `/auth/forgot-password` | `AuthModal.jsx` → `auth_page.dart` | PARTIAL | SUPPORTED | Web modal, Flutter full route; preserve continuation and auth session | REBUILD_PRESENTATION |
| Password setup | `/setup-password` | no confirmed equivalent | `GooglePasswordSetupPage.jsx` → — | MISSING_IN_MOBILE | SUPPORTED | Required customer auth recovery/setup screen absent from Flutter inventory | CREATE_MOBILE_SCREEN |
| Food order history | embedded `/concessions` history | no dedicated confirmed route | `FoodOrdersHistoryPage.jsx` → — | MISSING_IN_MOBILE | Web customer flow has standalone history; mobile preview/booking food only | CREATE_MOBILE_SCREEN |
| Cinema information | Home/header modal/link | `/information/cinema` | `HomePage.jsx`, `Header.jsx` → `information_pages.dart` | PARTIAL | SUPPORTED | Mobile has dedicated route; web uses sections/modal/link | RESTYLE |
| Support/chat | header/home affordance | `/support`, `/preview/popbot` | `Header.jsx`, `HomePage.jsx` → preview/account routes | NEEDS_REWORK | PARTIALLY_SUPPORTED | Mobile routes are not proven equivalent to web chat service | DEFER_BACKEND_UNSUPPORTED |
| Wallet | Profile/account surface | `/account/wallet` | `ProfilePage.jsx`, `walletService.js` → account pages | PARTIAL | PARTIALLY_SUPPORTED | Different information density and mutation scope; exact mobile mutation contract needs verification | RESTYLE |
| Points/VIP | Profile/membership surface | `/account/points`, `/preview/vip` | `ProfilePage.jsx`, `loyaltyService.js` → account pages | PARTIAL | PARTIALLY_SUPPORTED | Web embeds membership; mobile splits routes; exact mobile mutation contract needs verification | RESTYLE |
| Vouchers/promotions | Home/booking promotion UI | `/preview/vouchers` | Home/Booking pages → preview page | NEEDS_REWORK | PARTIALLY_SUPPORTED | Mobile is preview route; do not present as production flow yet | DEFER_BACKEND_UNSUPPORTED |
| Notifications | no dedicated customer web route found | `/preview/notifications` | — → account route surface | MISSING_IN_MOBILE | PARTIALLY_SUPPORTED | Mobile-only route has no web screen to parity-match | DEFER_BACKEND_UNSUPPORTED |
| Refund preview | order action/booking cancellation | `/preview/refund/:bookingId` | `MyOrdersPage.jsx` → preview page | PARTIAL | PARTIALLY_SUPPORTED | Web cancellation is production booking action; mobile preview requires contract check | DEFER_BACKEND_UNSUPPORTED |

## Totals

Using the source inventories: 13 Web customer screen rows appear in `00`, and 28 distinct Flutter customer route paths appear in `01` (combined table cells are expanded by path). The matrix contains 22 parity entries because some rows intentionally combine related routes or decompose one composite web flow into multiple mobile steps. Matrix status counts are: MATCH 1, PARTIAL 15, NEEDS_REWORK 3, MISSING_IN_MOBILE 3.

The totals do not need to equal one another: Web `/movies/:id/book` is one route-backed composite flow represented by seat selection and checkout rows; `/concessions` contains food-order history; profile contains wallet/points/VIP surfaces; Home/header affordances cover cinema information and support/chat. Conversely, Flutter exposes separate routes for login/register/forgot-password, profile/security/wallet/points/VIP, cinema/policies/support, preview food, vouchers, PopBot and refund. Mobile-only and preview-only rows are retained so every current Flutter route is visible in the matrix.

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
