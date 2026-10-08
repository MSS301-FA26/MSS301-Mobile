# Payment create integration

Mobile calls `POST /api/v1/payments/vnpay/create` through the Gateway with the exact `bookingId`. The backend derives ownership and payment amount; mobile does not send user identity or amount.
