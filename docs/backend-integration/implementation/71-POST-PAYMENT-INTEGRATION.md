# Post-payment integration

After backend payment status is `SUCCESS`, mobile calls `GET /api/v1/bookings/{bookingId}` through Gateway. No mobile finalize endpoint or duplicate confirmation call is used.
