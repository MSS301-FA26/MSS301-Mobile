# Payment lifecycle

The backend returns a payment ID and `paymentUrl`. Returning from the provider is not success. Mobile fetches `GET /api/v1/payments/{paymentId}` and maps `PENDING`, `SUCCESS`, `FAILED`, and `REFUNDED` without treating unknown values as success.
