# Payment Contract

## CURRENT IMPLEMENTATION

The Mobile app uses `MockPaymentRepository` and `mock://vnpay/{id}`. This is not the canonical backend contract.

## MOBILE-USABLE CONTRACT

| Operation | Method | Public path | Owner |
|---|---|---|---|
| Create VNPay payment | POST | `/api/v1/payments/vnpay/create` | payment-service |
| Mock payment (dev only) | POST | `/api/v1/payments/mock` | payment-service |
| Payment by booking | GET | `/api/v1/payments/booking/{bookingId}` | payment-service |
| Payment by ID | GET | `/api/v1/payments/{paymentId}` | payment-service |

The selected controller accepts `bookingId` for create and derives the amount from the backend booking/payment service. Payment response includes a backend-generated payment URL; Mobile must open that URL and must not provide the amount.

## Provider callbacks

- VNPay calls `POST/GET /api/v1/payments/vnpay/ipn`.
- Browser/provider return reaches `POST/GET /api/v1/payments/vnpay/return` or `/vnpay/null`.
- The payment service validates callback parameters/signature and updates payment state.
- In the microservice architecture, successful payment publishes an outbox/RabbitMQ event; booking-service `PaymentEventListener` transitions the booking to `PAID` and generates QR data.

Evidence: `payment-service/.../controller/PaymentController.java`, `PaymentServiceImpl.java`, `OutboxPublisherWorker.java`, `booking-service/.../listener/PaymentEventListener.java`.

## CURRENT MOBILE RETURN STATUS

```text
MOBILE_PAYMENT_RETURN_CONTRACT_MISSING
```

The backend return URL is a server callback/redirect contract. No mobile custom scheme, app link, or Flutter callback is configured in the Mobile Android/iOS projects.

## Authoritative verification

Mobile can query `GET /api/v1/payments/{paymentId}` or `GET /api/v1/payments/booking/{bookingId}`. Backend payment status is authoritative; Mobile must not treat a redirect query parameter alone as success.

## Status

Backend payment enum evidence: `PENDING`, `SUCCESS`, `FAILED` in `payment-service/.../enums/PaymentStatus.java`.

Payment creation/status is frozen. Mobile return remains `MISSING` and is a `P0_BEFORE_MOB-070`, not a blocker for MOB-010.

## RECOMMENDED CONTRACT — NOT IMPLEMENTED

```text
Mobile → gateway create payment
→ open returned VNPay URL
→ VNPay backend return/IPN
→ backend authoritative payment status
→ redirect to an agreed mobile deep link, if required
→ Mobile GET payment/booking status
```
