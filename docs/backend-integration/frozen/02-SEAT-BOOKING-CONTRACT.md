# Seat and Booking Contract

Status: `FROZEN for the cinema-services public API surface`

## Seat map

| Method | Path | Owner | Auth |
|---|---|---|---|
| GET | `/api/v1/showtimes/{showtimeId}/seat-map` | catalog-service | Public |

Controller: `cinema-services/catalog-service/.../controller/ShowtimeController.java`.
The response is the catalog service seat-map DTO. Exact JSON field names are defined by the response DTO in `catalog-service/.../dto/response/` and must not be replaced by Mobile's mock model names.

## Hold and booking

| Operation | Method | Path | Owner | Auth |
|---|---|---|---|---|
| Hold seats | POST | `/api/v1/bookings/hold` | booking-service | CUSTOMER |
| Update held items | PUT | `/api/v1/bookings/{bookingId}/items` | booking-service | CUSTOMER |
| Checkout held booking | POST | `/api/v1/bookings/{bookingId}/checkout` | booking-service | CUSTOMER |
| List own bookings | GET | `/api/v1/bookings` | booking-service | CUSTOMER |
| Read own booking | GET | `/api/v1/bookings/{bookingId}` | booking-service | CUSTOMER |
| Read by booking code | GET | `/api/v1/bookings/code/{bookingCode}` | booking-service | CUSTOMER/flow dependent |
| Cancel booking | DELETE | `/api/v1/bookings/{bookingId}` | booking-service | CUSTOMER |

Evidence: `cinema-services/booking-service/src/main/java/com/cinemaai/booking/controller/BookingController.java`.

## Hold ownership and expiry

`BookingController` receives the authenticated principal; Mobile must not send an arbitrary customer ID as the ownership authority. `BookingServiceImpl` creates the booking in `HOLDING`, stores `holdExpiresAt`, and queries/cleans active holds using the server clock. `SeatHoldCleanupScheduler` handles cleanup for expired `HOLDING`/`PENDING_PAYMENT` bookings.

Backend expiry is authoritative. Mobile timers are display-only and must re-read booking/seat state before proceeding.

## Concurrency

Booking service checks active `BOOKED` and non-expired `HOLDING` seats in `BookingSeatRepository`; database migrations include active-seat uniqueness enforcement. The hold operation is transactional in the service implementation. This is the backend protection against concurrent customer holds.

## Release/change semantics

The selected microservice controller exposes cancel and item update, but no separate public `release-hold` endpoint is present in the inspected `BookingController`. Therefore:

```text
EXPLICIT_RELEASE_NOT_SUPPORTED as a distinct public operation
```

For changing a held selection, use the documented `PUT /bookings/{bookingId}/items` contract if the request DTO supports the desired mutation; otherwise cancel/expiry and create a new hold. Do not invent a release endpoint.

## Status lifecycle

Backend enum: `HOLDING`, `PENDING_PAYMENT`, `PAID`, `USED` in `booking-service/.../enums/BookingStatus.java`. Expiry/cancellation states are represented by the actual enum/entity contract and must be confirmed from the selected DTO before mapping a Mobile display label.

Payment event listener transitions a successful payment booking to `PAID` and generates QR data: `booking-service/.../listener/PaymentEventListener.java`.
