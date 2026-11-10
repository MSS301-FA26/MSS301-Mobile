# Checkout Quote Contract

Status: `FROZEN`

## Pricing authority

The authoritative quote owner is `catalog-service`, exposed through the gateway:

```text
POST /api/v1/catalog/checkout-quote
```

Evidence:

- `catalog-service/.../controller/CheckoutQuoteController.java`
- `catalog-service/.../service/impl/CheckoutQuoteServiceImpl.java`
- gateway route `/api/v1/catalog/**` in `api-gateway/application.properties`

## Semantics

The service loads showtime/seat/pricing data and rejects unavailable seats before calculating the quote. It does not use a Mobile-supplied final amount as the pricing authority. Quote inputs are request DTO fields for showtime, selected seats/ticket selections, food selections, and booking/session context as declared in `catalog-service/.../dto/request/`.

Final amount is therefore backend-calculated. Mobile must display the response and must not authoritatively recompute or submit a trusted final amount.

## Quote snapshot and expiry

The inspected public controller/service proves server-side recalculation, but an independently persisted quote ID/TTL snapshot contract is not proven at the gateway boundary. Treat quote expiry/snapshot semantics as:

```text
CONTRACT DETAIL NOT_PROVEN
```

This does not block network foundation or catalog reads, but it blocks claiming checkout/payment integration complete until DTO and service behavior are frozen in the selected commit.

## Promotion

No customer voucher/promotion field and validation route was proven in the selected microservice public contract during this pass. Mark promotion integration `BLOCKED`, not implemented by assumption.
