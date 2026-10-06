# Integration Readiness

| Blocker | Before | After | Evidence |
|---|---|---|---|
| Canonical backend | BLOCKED | RESOLVED | Root Docker Compose + gateway wiring select `cinema-services` |
| Auth contract | BLOCKED | FROZEN | Identity controller, JWT/refresh services, gateway path |
| Quote contract | BLOCKED | FROZEN with expiry detail deferred | Catalog checkout-quote controller/service |
| Payment contract | BLOCKED | PARTIALLY_RESOLVED | Payment create/status/event paths frozen; Mobile return missing |
| Seat/booking contract | BLOCKED | FROZEN | Booking controller/service/scheduler/repository evidence |
| Gateway/base URL | BLOCKED | RESOLVED | Gateway exposed on configurable port, default 8080 |

## Blocks MOB-010 Network Foundation

None of the original five blockers blocks starting network foundation, provided MOB-010 uses:

```text
API_BASE_URL = gateway host + configured gateway port
```

and keeps DTO details under the frozen-contract follow-up tasks.

## Does not block MOB-010 but blocks later phases

1. `MOBILE_PAYMENT_RETURN_CONTRACT_MISSING` — P0 before MOB-070/payment completion.
2. Exact quote expiry/snapshot semantics — required before production checkout/payment.
3. Exact identity DTO field declarations and refresh rotation behavior — required before completing MOB-011.
4. Notification gateway route is missing — blocks notification integration.
5. Promotion/voucher public contract is not proven — blocks promotion integration.

## Readiness decision

```text
READY FOR MOB-010 → MOB-017: YES, conditionally
```

Condition: MOB-010 starts with the gateway contract and does not implement payment callback behavior. Payment deep-link remains explicitly tracked for the later payment phase.
