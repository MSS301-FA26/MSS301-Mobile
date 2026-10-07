# Checkout architecture

Production flow is `real showtime -> real seat map -> real hold -> real bookingId -> real checkout quote -> stop before payment`.

The quote is owned by Catalog Service and reached through the API Gateway. Mock checkout remains available only through the test/demo repository bridge.
