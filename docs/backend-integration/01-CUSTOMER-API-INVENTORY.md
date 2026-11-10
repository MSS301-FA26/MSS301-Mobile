# Customer API Inventory

## Scope and canonical-backend decision

Two backend implementations are present and contain overlapping CUSTOMER APIs:

1. Monolith: `D:/FPTK9/MSS/MSS301-Backend/cinemaAI`
2. Microservices: `D:/FPTK9/MSS/MSS301-Backend/cinema-services`

The Mobile repository has no API base URL, HTTP client, environment selection, or service-discovery configuration. Therefore:

```text
BACKEND_CANONICAL_IMPLEMENTATION_UNDECIDED
```

The inventory below records source-proven endpoints. It does not claim that either implementation is the runtime backend for Mobile.

## Monolith CUSTOMER endpoints

| Domain | Method | Path | Backend module | Authentication | Request/response evidence | Confidence |
|---|---|---|---|---|---|---|
| AUTH | POST | `/api/v1/auth/login` | cinemaAI | Public | `AuthController.java`; auth integration tests | HIGH |
| AUTH | POST | `/api/v1/auth/register` | cinemaAI | Public | `AuthController.java` | HIGH |
| AUTH | POST | `/api/v1/auth/verify-email` | cinemaAI | Public | `AuthController.java`, email verification service | MEDIUM |
| AUTH | POST | `/api/v1/auth/forgot-password` | cinemaAI | Public | `AuthController.java`, password reset service | MEDIUM |
| AUTH | POST | `/api/v1/auth/refresh` | cinemaAI | Authenticated/refresh token | `AuthController.java`, refresh token service | MEDIUM |
| MOVIE | GET | `/api/v1/movies` | cinemaAI | Public | `MovieController.java`, `MovieIntegrationTests.java` | HIGH |
| MOVIE | GET | `/api/v1/movies/{id}` | cinemaAI | Public | `MovieController.java` | HIGH |
| MOVIE | GET | `/api/v1/genres` | cinemaAI | Public | `GenreController.java` | HIGH |
| MOVIE | GET | `/api/v1/actors` | cinemaAI | Public | `ActorController.java` | HIGH |
| CINEMA | GET | `/api/v1/cinemas` | cinemaAI | Public | `CinemaController.java`, phase-5 API README | HIGH |
| SHOWTIME | GET | `/api/v1/showtimes` | cinemaAI | Public | `ShowtimeController.java`, phase-5 API README | HIGH |
| SEAT | GET | `/api/v1/showtimes/{showtimeId}/seat-map` | cinemaAI | Public | `ShowtimeController.java`, phase-5 API README | HIGH |
| PRICING | POST | `/api/v1/ticket-pricing/validate` | cinemaAI | Public/authenticated by flow | `TicketPricingController.java`, phase-5 API README | HIGH |
| FOOD | GET | `/api/v1/foods/items` | cinemaAI | Public | `FoodController.java`, phase-5 API README | HIGH |
| FOOD | GET | `/api/v1/foods/combos` | cinemaAI | Public | `FoodController.java`, phase-5 API README | HIGH |
| BOOKING | POST | `/api/v1/bookings/hold` | cinemaAI | CUSTOMER | `BookingController.java`, phase-5 booking API README | HIGH |
| BOOKING | POST | `/api/v1/bookings` | cinemaAI | CUSTOMER | `BookingController.java` | HIGH |
| BOOKING | PUT | `/api/v1/bookings/{bookingId}/items` | cinemaAI | CUSTOMER | `BookingController.java` | HIGH |
| BOOKING | GET | `/api/v1/bookings` | cinemaAI | CUSTOMER | `BookingController.java` | HIGH |
| BOOKING | GET | `/api/v1/bookings/{bookingId}` | cinemaAI | CUSTOMER | `BookingController.java` | HIGH |
| BOOKING | DELETE | `/api/v1/bookings/{bookingId}` | cinemaAI | CUSTOMER | `BookingController.java` | HIGH |
| BOOKING | POST | `/api/v1/bookings/{bookingId}/release-hold` | cinemaAI | CUSTOMER | `BookingController.java` | HIGH |
| AUTH | POST | `/api/v1/auth/google` | cinemaAI | Public | `AuthController.java` | HIGH |
| AUTH | POST | `/api/v1/auth/google/verify` | cinemaAI | Public | `AuthController.java` | HIGH |
| AUTH | POST | `/api/v1/auth/verify-email/request` | cinemaAI | Public | `AuthController.java` | HIGH |
| AUTH | POST | `/api/v1/auth/password-reset/request` | cinemaAI | Public | `AuthController.java` | HIGH |
| AUTH | POST | `/api/v1/auth/password-reset/verify` | cinemaAI | Public | `AuthController.java` | HIGH |
| AUTH | POST | `/api/v1/auth/password-reset/confirm` | cinemaAI | Public | `AuthController.java` | HIGH |
| PAYMENT | POST | `/api/v1/payments/vnpay/create` | cinemaAI | CUSTOMER | `PaymentController.java`, `PaymentIntegrationTests.java` | HIGH |
| PAYMENT | POST | `/api/v1/payments/mock` | cinemaAI | CUSTOMER/test flow | `PaymentController.java`, payment tests | HIGH |
| PAYMENT | GET | `/api/v1/payments/booking/{bookingId}` | cinemaAI | CUSTOMER | payment integration tests | HIGH |
| PAYMENT | GET | `/api/v1/payments/vnpay/return` | cinemaAI | Public callback | `PaymentController.java`, security config | HIGH |
| PAYMENT | GET | `/api/v1/payments/vnpay/ipn` | cinemaAI | Public provider callback | `PaymentController.java`, security config | HIGH |
| TICKET | GET | `/api/v1/bookings/{bookingId}` | cinemaAI | CUSTOMER | Booking response includes ticket/QR fields where present | MEDIUM |
| PROFILE | GET/PUT | `/api/v1/users/me` | cinemaAI | CUSTOMER | `UserController.java` | MEDIUM |
| LOYALTY | GET | `/api/v1/loyalty/me` | cinemaAI | CUSTOMER | `LoyaltyPointController.java` | MEDIUM |
| NOTIFICATION | GET/PATCH | `/api/v1/notifications/me`, `/api/v1/notifications/me/read-all` | cinemaAI | CUSTOMER | `NotificationController.java`, SRS | MEDIUM |
| WISHLIST | GET/POST/DELETE | `/api/v1/wishlist/**` | cinemaAI | CUSTOMER | `WishlistController.java` | MEDIUM |
| REVIEW | — | — | cinemaAI | — | SRS states customer review controller/service is not implemented | HIGH |
| RECOMMENDATION | GET/POST | recommendation controller paths | cinemaAI | CUSTOMER | `RecommendationController.java` | MEDIUM |
| AI_CHAT | POST | chat controller path | cinemaAI | CUSTOMER | `ChatController.java` | MEDIUM |

Exact request/response DTOs and statuses must be resolved against the selected backend before implementation. The monolith source is the only source that can currently provide a single coherent controller/service/entity trace.

## Microservices CUSTOMER endpoints

The microservice repository contains separate identity, catalog, booking, payment, and recommendation services. Evidence includes:

- Catalog: `catalog-service/src/main/java/com/cinemaai/catalog/controller/CinemaController.java`, `MovieController.java`, `ShowtimeController.java`, `FoodController.java`, `CheckoutQuoteController.java`.
- Identity: `identity-service/src/main/java/com/cinemaai/identity/...`.
- Booking: `booking-service/src/main/java/com/cinemaai/booking/controller/...`.
- Payment: `payment-service/src/main/java/com/cinemaai/payment/...`.
- Gateway: `api-gateway/src/main/java/com/cinemaai/gateway/...`.

Public gateway route composition is not proven from Mobile source. Internal routes such as `/internal/v1/catalog/checkout-quote` and `/internal/v1/bookings/{id}` must not be used by Mobile without gateway evidence.

## Contract facts that are proven

- Seat-map endpoint exists in both the monolith API documentation and catalog/showtime code.
- Hold and booking endpoints exist in the monolith API documentation.
- VNPay create/return/IPN paths exist in the monolith payment controller/tests.
- The microservice implementation has payment return/IPN security paths, but its gateway-facing public contract is not proven equivalent to the monolith.
- Customer review support is explicitly reported as incomplete in `cinemaAI/SRS_CINEMA_SYSTEM_COMPLETE.md`.
