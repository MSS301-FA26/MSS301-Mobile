# Booking detail lifecycle

History items preserve their backend booking ID. Selecting an item loads `GET /api/v1/bookings/{bookingId}` and the ticket screen reuses the same ID and backend ticket/QR fields.
