# Enum Mapping

No Dart enum is changed in this batch.

| Backend value | Mobile current value | Action |
|---|---|---|
| `AVAILABLE` | local available value | MAP |
| `UNAVAILABLE` | local unavailable/sold/held variants | MOBILE_ENUM_CHANGE_REQUIRED risk |
| `MAINTENANCE` | no proven dedicated value | MOBILE_ENUM_CHANGE_REQUIRED |
| `NORMAL` | local normal value | MAP |
| `STANDARD` | local standard value | MAP |
| `VIP` | local VIP value | MAP |
| `COUPLE` | local couple value | MAP |
| `SCHEDULED` | local scheduled value | MAP |
| `OPEN` | local open value | MAP |
| `CANCELLED` | local cancelled value | MAP |
| `COMPLETED` | local completed value | MAP |
| `HOLDING` | `holding` | MAP |
| `PENDING_PAYMENT` | `pendingPayment` | MAP |
| `PAID` | `paid` | MAP |
| `USED` | no proven dedicated current Mobile value | MOBILE_ENUM_CHANGE_REQUIRED |
| `CANCELLED` | `cancelled` | MAP |
| `EXPIRED` | `expired` | MAP |
| `REFUNDED` | no proven dedicated current Mobile value | MOBILE_ENUM_CHANGE_REQUIRED |
| `PENDING` | `pending` | MAP |
| `SUCCESS` | `success` | MAP |
| `FAILED` | `failed` | MAP |
| `REFUNDED` | no proven dedicated payment value | MOBILE_ENUM_CHANGE_REQUIRED |
| `FoodOrderStatus` backend values | no complete Mobile enum | MOBILE_ENUM_CHANGE_REQUIRED |
| Refund status | booking/payment values above; no separate customer refund DTO frozen | UNKNOWN |

Evidence: `cinema-services/catalog-service/.../enums/SeatStatus.java`, `SeatType.java`, `ShowtimeStatus.java`; `booking-service/.../enums/BookingStatus.java`, `BookingSeatStatus.java`; `payment-service/.../enums/PaymentStatus.java`.

The backend has separate catalog seat runtime status and booking-seat status. Mobile must not collapse them without an explicit mapper.
