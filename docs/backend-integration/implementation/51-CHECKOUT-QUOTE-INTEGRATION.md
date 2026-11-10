# Checkout quote integration

`POST /api/v1/catalog/checkout-quote` is called through the shared Dio client. The request preserves showtime, seat, ticket, food, voucher, CinePoints, and booking session identifiers. The response is mapped from the backend `ApiResponse<CheckoutQuoteResponse>` envelope.
