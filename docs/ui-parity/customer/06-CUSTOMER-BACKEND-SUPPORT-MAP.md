# Customer Backend Support Map

Backend was read for verification only. Concrete evidence includes customer controllers under `MSS301-Backend/cinemaAI/src/main/java/com/sba301/cinemaai/controller` and matching web/mobile repositories.

| Customer feature | Evidence | Support |
|---|---|---|
| Authentication/session | `AuthController`, auth service/repository, token storage and guards | SUPPORTED |
| Movie/catalog | `MovieController` GET list/detail/available-showtimes; web `movieService`; mobile remote catalog repository | SUPPORTED |
| Cinema | public cinema endpoints and `CinemaController`; web public cinema service; mobile catalog DTOs | SUPPORTED |
| Showtime | `ShowtimeController` customer schedule/detail/seat-map; `ShowtimeController.java` and `bookingService` | SUPPORTED |
| Seat map | showtime `/{id}/seat-map`; mobile `seat_map_provider.dart` | SUPPORTED |
| Seat hold | booking hold/update endpoints and `seat_hold_repository.dart`/remote implementation | SUPPORTED |
| Checkout quote | `CatalogCheckoutController`/checkout quote contract; web booking service and mobile booking repositories | SUPPORTED |
| Payment | `PaymentController` VNPay/mock/booking lookup; web payment service and mobile payment repository/launcher | SUPPORTED |
| Booking completion | booking controller/service, create booking and booking lifecycle; mobile completion controller | SUPPORTED |
| Ticket/QR | booking detail/ticket contract and QR ticket service/controller | SUPPORTED |
| Booking history/detail | customer booking list/detail endpoints; web and mobile booking repositories | SUPPORTED |
| Concessions/food catalog | public food endpoints, ticket pricing combos, booking/standalone food order controllers | SUPPORTED |
| Food order history | `StandaloneFoodOrderController` GET `/my` and booking food-order endpoints | SUPPORTED |
| Profile/security | `UserController` `/me`, update/avatar/password | SUPPORTED |
| Wishlist | `WishlistController` create/list/delete | SUPPORTED |
| Reviews | `ReviewController` movie list/summary/eligibility/create/update/delete | SUPPORTED |
| Loyalty/points/VIP | loyalty controller/service and web loyalty service; confirm exact mobile mutation scope before UI | PARTIALLY_SUPPORTED |
| Wallet | `WalletController` read/transactions/withdrawals; web service exists, mobile UI mutation scope needs verification | PARTIALLY_SUPPORTED |
| Promotions/vouchers | public active/validate promotion endpoints exist; mobile `/vouchers` is preview and does not prove full customer redemption parity | PARTIALLY_SUPPORTED |
| Notifications | notification controller exists, but no corresponding web customer route and mobile page is not a proven production flow | PARTIALLY_SUPPORTED |
| Support/chat/PopBot | web `chatService` exists; no confirmed mobile production chat contract in inspected feature files | PARTIALLY_SUPPORTED |
| Refund preview | cancellation/refund operations exist but mobile preview route is not sufficient evidence for customer production refund flow | PARTIALLY_SUPPORTED |
| Google password setup | web flow and auth backend support exist; no confirmed mobile equivalent route | SUPPORTED (backend), mobile UI missing |

## Rules applied

`SUPPORTED` requires a concrete customer-facing endpoint and an existing repository/service path. Preview-only mobile routes are not treated as production support. Any UI for a partially supported or unverified feature must remain deferred rather than using fake data.
