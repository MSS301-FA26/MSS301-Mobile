# Mobile Repository Change Plan

Documentation only; no Dart changes in Batch 01.5.

| Repository/method | Decision | Backend contract | Reason |
|---|---|---|---|
| CatalogRepository.getMovies/getMovie | ADAPT_IMPLEMENTATION | catalog movie paths | Replace mock with gateway DTO parsing |
| CatalogRepository.getShowtimes/getShowtime | ADAPT_IMPLEMENTATION | `/api/v1/showtimes/**` | Query/response fields need DTO mapping |
| CatalogRepository.getSeatMap | ADAPT_IMPLEMENTATION | `/api/v1/showtimes/{id}/seat-map` | Backend status/type fields are authoritative |
| CatalogRepository.getFoodItems/getFoodCombos | ADAPT_IMPLEMENTATION | `/api/v1/foods/items`, `/combos` | Replace fixtures |
| CatalogRepository.createCheckoutQuote | CHANGE_SIGNATURE_REQUIRED | `/api/v1/catalog/checkout-quote` | Quote request/response differs from local mock assumptions |
| BookingRepository.holdSeats | ADAPT_IMPLEMENTATION | `/api/v1/bookings/hold` | Derive user from JWT; do not trust userId argument |
| BookingRepository.updateItems | ADAPT_IMPLEMENTATION | `PUT /api/v1/bookings/{id}/items` | Public endpoint exists |
| BookingRepository.checkout | CHANGE_SIGNATURE_REQUIRED | `POST /api/v1/bookings/{id}/checkout` | Microservice uses explicit checkout route |
| BookingRepository.getBookings | CHANGE_SIGNATURE_REQUIRED | `GET /api/v1/bookings?page=&size=` | Backend returns paginated response |
| BookingRepository.getBooking | ADAPT_IMPLEMENTATION | `GET /api/v1/bookings/{id}` | DTO mapping required |
| BookingRepository.cancel | ADAPT_IMPLEMENTATION | `DELETE /api/v1/bookings/{id}` | Server owns transition |
| BookingRepository.applyPaymentSucceeded | REMOVE_OR_DEPRECATE_LATER | RabbitMQ/backend payment event | Mobile must not mutate paid state locally |
| PaymentRepository.createPayment | CHANGE_SIGNATURE_REQUIRED | `POST /api/v1/payments/vnpay/create?bookingId=` | Backend derives amount and returns URL |
| PaymentRepository.getPayment | ADAPT_IMPLEMENTATION | `GET /api/v1/payments/{id}` | Real endpoint exists in microservice |
| PaymentRepository.getPaymentByBooking | ADAPT_IMPLEMENTATION | `GET /api/v1/payments/booking/{id}` | Real endpoint exists |
| PaymentRepository.markSuccess/markFailed | REMOVE_OR_DEPRECATE_LATER | Provider/backend callback only | Client must not set payment status |
| PaymentRepository.confirmSuccessfulBooking | REMOVE_OR_DEPRECATE_LATER | Payment event + booking read | Backend confirms booking |
| ProfileRepository | ADAPT_IMPLEMENTATION | `/api/v1/users/me` | Identity service owns profile |
| WalletRepository | ADAPT_IMPLEMENTATION | `/api/v1/wallet/**` | Payment service owns wallet |
| LoyaltyRepository | ADAPT_IMPLEMENTATION | `/api/v1/loyalty/**` | Payment service owns loyalty |

Missing methods to add later:

- Auth repository methods and token/session lifecycle.
- Dedicated payment status refresh and callback handling.
- Ticket/QR retrieval/read model.
- Notification repository (gateway route currently missing).
- Promotion/voucher repository after backend route is proven.

## Evidence

Mobile interfaces: `lib/features/*/data/repositories/*_repository.dart`.
Gateway/service controllers: `cinema-services/*/src/main/java/com/cinemaai/*/controller/`.
