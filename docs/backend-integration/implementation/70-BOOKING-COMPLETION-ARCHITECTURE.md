# Booking completion architecture

Payment Service emits `PaymentSucceededEvent`; Booking Service consumes it and marks the same booking `PAID`. Mobile refreshes that booking by its unchanged ID and stops at the real booking/ticket boundary.
