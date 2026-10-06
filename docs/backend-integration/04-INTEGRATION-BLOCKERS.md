# Integration Blockers

## P0_BLOCKER

1. **Canonical backend is undecided.** Both `cinemaAI` monolith and `cinema-services` microservices contain overlapping customer functionality. Mobile has no configuration proving which is active.
2. **Auth contract is not frozen.** Login response, token fields, refresh rotation, logout semantics, and current-user endpoint are not mapped to a single backend implementation.
3. **Payment return contract is missing for Mobile.** Backend VNPay return/IPN endpoints exist, but the Mobile deep-link/app-link callback and authoritative client verification flow are not defined.
4. **Authoritative quote contract is unresolved.** Monolith pricing validation and microservice checkout quote paths are different; Mobile must not calculate or choose final price locally.
5. **Hold/update lifecycle is not one-to-one.** Mobile has `updateItems`, while an exact customer backend endpoint for that operation is not proven.

## P1_REQUIRED

- Freeze public gateway paths for microservices.
- Freeze response envelope and error schema.
- Reconcile IDs, money scale, timestamps/timezone, and enum values.
- Define ticket/QR retrieval and payload trust model.
- Define pagination for movie, booking, notification, and review lists.
- Define profile, wallet, loyalty, notification, wishlist, recommendation, and AI-chat customer contracts.

## P2_FOLLOWUP

- Customer reviews are reported incomplete in backend SRS; do not build against a speculative endpoint.
- Customer refund semantics conflict with the provisional Mobile refund preview and backend business rules.
- Push notification registration/token lifecycle is not proven.

## Evidence

- Mobile repository providers: `lib/features/*/data/repositories/*_providers.dart`
- Mobile payment mock: `lib/features/payment/data/repositories/mock_payment_repository.dart`
- Monolith controllers: `cinemaAI/src/main/java/com/sba301/cinemaai/controller/`
- Microservice controllers: `cinema-services/*/src/main/java/com/cinemaai/*/controller/`
- Backend status/feature notes: `cinemaAI/SRS_CINEMA_SYSTEM_COMPLETE.md`
