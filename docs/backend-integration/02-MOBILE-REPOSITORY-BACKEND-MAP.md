# Mobile Repository → Backend API Map

## Repository methods

| Mobile repository | Mobile method | Current implementation | Backend target | Mapping status |
|---|---|---|---|---|
| `CatalogRepository` | `getMovies` | `MockCatalogRepository` | `GET /api/v1/movies` | ADAPTABLE |
| `CatalogRepository` | `getMovie` | `MockCatalogRepository` | `GET /api/v1/movies/{id}` | ADAPTABLE |
| `CatalogRepository` | `getShowtimes` | `MockCatalogRepository` | `GET /api/v1/showtimes` | ADAPTABLE |
| `CatalogRepository` | `getShowtime` | `MockCatalogRepository` | showtime detail; exact endpoint not proven | UNCERTAIN |
| `CatalogRepository` | `getSeatMap` | `MockCatalogRepository` | `GET /api/v1/showtimes/{showtimeId}/seat-map` | ADAPTABLE |
| `CatalogRepository` | `getFoodItems` | `MockCatalogRepository` | `GET /api/v1/foods/items` | ADAPTABLE |
| `CatalogRepository` | `getFoodCombos` | `MockCatalogRepository` | `GET /api/v1/foods/combos` | ADAPTABLE |
| `CatalogRepository` | `createCheckoutQuote` | `MockCatalogRepository` | `POST /api/v1/ticket-pricing/validate` or catalog quote endpoint | MULTIPLE_ENDPOINTS_REQUIRED |
| `BookingRepository` | `holdSeats` | `MockBookingRepository` | `POST /api/v1/bookings/hold` | ADAPTABLE |
| `BookingRepository` | `updateItems` | `MockBookingRepository` | `PUT /api/v1/bookings/{bookingId}/items` (monolith) | ADAPTABLE |
| `BookingRepository` | `checkout` | `MockBookingRepository` | `POST /api/v1/bookings` | ADAPTABLE |
| `BookingRepository` | `getBooking` | `MockBookingRepository` | `GET /api/v1/bookings/{bookingId}` | ADAPTABLE |
| `BookingRepository` | `getBookings` | `MockBookingRepository` | `GET /api/v1/bookings` | ADAPTABLE |
| `BookingRepository` | `cancel` | `MockBookingRepository` | `DELETE /api/v1/bookings/{bookingId}` | ADAPTABLE |
| `BookingRepository` | release behavior inside `cancel` | `MockBookingRepository` | `POST /api/v1/bookings/{bookingId}/release-hold` (monolith) | MULTIPLE_ENDPOINTS_REQUIRED |
| `BookingRepository` | `applyPaymentSucceeded` | `MockBookingRepository` | Backend event/payment confirmation; no direct Mobile endpoint proven | MULTIPLE_ENDPOINTS_REQUIRED |
| `PaymentRepository` | `createPayment` | `MockPaymentRepository` | `POST /api/v1/payments/vnpay/create` | ADAPTABLE |
| `PaymentRepository` | `getPayment` | `MockPaymentRepository` | payment-by-id endpoint not proven | BACKEND_ENDPOINT_MISSING |
| `PaymentRepository` | `getPaymentByBooking` | `MockPaymentRepository` | `GET /api/v1/payments/booking/{bookingId}` | ADAPTABLE |
| `PaymentRepository` | `markSuccess` | local simulation | Backend callback/status, not Mobile mutation | BACKEND_ENDPOINT_MISSING |
| `PaymentRepository` | `markFailed` | local simulation | Backend status/callback, not Mobile mutation | BACKEND_ENDPOINT_MISSING |
| `PaymentRepository` | `confirmSuccessfulBooking` | local simulation | Backend payment verification/event | MULTIPLE_ENDPOINTS_REQUIRED |
| `ProfileRepository` | `getProfile` | `MockAccountStore` | `/api/v1/users/me` family; exact contract pending | UNCERTAIN |
| `ProfileRepository` | `updateProfile` | `MockAccountStore` | `/api/v1/users/me` family; exact contract pending | UNCERTAIN |
| `WalletRepository` | wallet/transactions/withdrawal methods | `MockAccountStore` | payment/wallet service endpoints; exact customer paths pending | UNCERTAIN |
| `LoyaltyRepository` | `getLoyalty`, `getConfiguration` | `MockAccountStore` | `/api/v1/loyalty/me` family | UNCERTAIN |
| `ProvisionalPreviewRepository` | `getItems` | mock preview | No proven customer API for all preview features | BACKEND_ENDPOINT_MISSING |

## Important caller traces

| Screen/flow | Controller/provider | Repository method | Target API |
|---|---|---|---|
| Login | `AuthPage` → `MockAuthSessionController` | No repository method | Auth login endpoint missing from Mobile abstraction |
| Home movies | `HomePage` → `moviesProvider` | `getMovies` | `/api/v1/movies` |
| Movie detail | `MovieDetailPage` → `movieProvider` | `getMovie` | `/api/v1/movies/{id}` |
| Showtime | `ShowtimesPage` → `showtimesProvider` | `getShowtimes` | `/api/v1/showtimes` |
| Seat map | `SeatSelectionPage` → `seatMapProvider` | `getSeatMap` | `/api/v1/showtimes/{id}/seat-map` |
| Hold | `BookingEntryController` | `holdSeats` | `/api/v1/bookings/hold` |
| Food | `BookingCompletionController` | `getFoodItems`, `getFoodCombos` | `/api/v1/foods/items`, `/api/v1/foods/combos` |
| Checkout | `BookingCompletionController` | `updateItems`, `createCheckoutQuote` | pricing/quote contract unresolved |
| Booking | `BookingCompletionController` | `checkout` | `/api/v1/bookings` |
| Payment | `BookingCompletionController` | `createPayment` | `/api/v1/payments/vnpay/create` |
| Ticket | `ticketBookingProvider` | `getBooking` | `/api/v1/bookings/{id}` |
| Orders | `ordersProvider` | `getBookings` | `/api/v1/bookings` |
| Profile | account pages | `getProfile`, `updateProfile` | user-me contract unresolved |
| Loyalty | account detail pages | `getLoyalty` | loyalty-me contract unresolved |

## Missing Mobile repository capabilities

- `login`, `register`, email verification, password reset, refresh token, logout, current user.
- `releaseHold` as a named capability separate from generic cancel.
- authoritative payment status/verification.
- payment return/deep-link handling.
- ticket/QR retrieval as a dedicated abstraction.
- promotions/vouchers.
- wishlist.
- reviews.
- notifications and unread state.
- recommendation.
- AI chat.
- pagination metadata for movie/booking/notification lists.
