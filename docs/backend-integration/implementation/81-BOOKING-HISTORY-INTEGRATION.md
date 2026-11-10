# Booking history integration

Mobile calls `GET /api/v1/bookings?page=0&size=20` through Gateway. Customer ownership is derived from AuthInterceptor/JWT; no customer identifier is sent.
