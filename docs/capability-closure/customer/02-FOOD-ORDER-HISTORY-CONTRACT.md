# Standalone Food-Order History Contract

## Sources

- Backend controller: `MSS301-Backend/cinemaAI/src/main/java/com/sba301/cinemaai/controller/StandaloneFoodOrderController.java`
- Service: `.../service/FoodOrderService.java`, `.../service/impl/FoodOrderServiceImpl.java`
- Request DTO: `.../dto/request/booking/FoodOrderRequest.java`
- Response DTO: `.../dto/response/booking/FoodOrderResponse.java`
- Gateway: `cinema-services/api-gateway/src/main/resources/application.properties`
- Mobile concessions: `lib/features/booking/presentation/pages/concessions_page.dart`
- Mobile food models: `lib/features/movie/data/models/food_quote_dto.dart`
- Mobile preview: `lib/features/preview/presentation/pages/preview_feature_page.dart`
- Web reference: `MSS301-Frontend/src/pages/user/FoodOrdersHistoryPage.jsx`

## Endpoint matrix

| Mobile target | Gateway route | Target service | Controller/method | Auth | DTOs | Result |
|---|---|---|---|---|---|---|
| `GET /api/v1/food-orders/my` | `booking-service`, Path `/api/v1/food-orders/**` | Booking service | `StandaloneFoodOrderController.listMine` → `FoodOrderService.listMine` | Bearer customer | `List<FoodOrderResponse>` | **YES** |
| `POST /api/v1/food-orders` | Same | Booking service | `StandaloneFoodOrderController.create` → `createStandalone` | Bearer customer | `FoodOrderRequest` → `FoodOrderResponse` | **YES** |
| `DELETE /api/v1/food-orders/{foodOrderId}` | Same | Booking service | `StandaloneFoodOrderController.cancel` → `cancel` | Bearer customer | path → `FoodOrderResponse` | **YES** |

## DTO contract

`FoodOrderRequest` contains a non-empty list of validated `BookingFoodRequest` items and an optional `promotionCode`.

`FoodOrderResponse` contains:

- `id`
- `orderCode`
- nullable `bookingId` and `bookingCode` for standalone orders
- `status`
- `totalAmount`
- `paidAt`
- `expiresAt`
- `pickedUpAt`
- `qrCode`
- `createdAt`
- `createdByStaff`
- `items: List<BookingFoodResponse>`

Food item snapshots include the selected product identity/name, quantity, unit/line pricing, combo information, and related item fields defined by `BookingFoodResponse`.

## Semantics

- Standalone orders have no movie booking requirement; booking fields are null.
- `totalAmount` is the server-calculated order total and must not be recomputed as the source of truth in Mobile.
- Status values: `PENDING_PAYMENT`, `PAID`, `PICKED_UP`, `CANCELLED`, `EXPIRED`.
- History is returned as a plain list; no page/size parameters or pagination envelope are defined.
- Customer ownership is enforced by passing the authenticated user's identity to the service. A customer cannot list or cancel another customer's order.
- Expected errors include `401` unauthenticated, `400` validation/business rejection, `404` unknown or inaccessible order, and service-specific conflict/state errors for invalid cancellation. The project exception handler supplies the response envelope.

## Mobile findings

Mobile already has reusable food product and quote models in `lib/features/movie/data/models/food_quote_dto.dart` and booking-scoped concessions in `lib/features/booking/presentation/pages/concessions_page.dart`. It does not have a standalone food-order DTO, repository, provider, history page, or production route. `lib/features/preview` is explicitly provisional and must not be reused for production history.

Existing order-history presentation patterns are in `lib/features/orders/presentation/pages/orders_page.dart` and `lib/features/orders/presentation/widgets/order_card.dart`, but those models represent bookings/tickets and should not be silently reused as the food-order API model.

## Recommended Mobile architecture

- `lib/features/food/data/models/food_order_dto.dart`
- `lib/features/food/data/remote_food_order_data_source.dart`
- `lib/features/food/data/food_order_repository.dart`
- `lib/features/food/data/remote_food_order_repository.dart`
- `lib/features/food/application/food_orders_provider.dart`
- `lib/features/food/presentation/pages/food_orders_history_page.dart`
- `lib/features/food/presentation/widgets/food_order_card.dart`
- Account navigation entry and a production route

The first implementation should be read-only history. Create/cancel/payment should be separate scope because they introduce additional payment and state-transition risk.

## Dedicated route

**YES.** A dedicated Mobile route is needed to replace the current preview food destination and to represent standalone orders separately from ticket bookings.
