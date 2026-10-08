# Next Integration Plan

This plan is documentation only. No implementation is included in Batch 01.

| Task | Prerequisites | Likely files | Contract required | Risk |
|---|---|---|---|---|
| MOB-010 Network foundation | Select canonical backend; freeze base URL, envelope, errors | `lib/core/network/**`, config/providers | Public gateway paths, response/error schema | High |
| MOB-011 Auth | MOB-010; auth contract frozen | `features/auth/**`, secure storage/config | Login/register/refresh/me/logout DTOs | Critical |
| MOB-012 Catalog | MOB-010; movie pagination/date/media contract | movie/discover/home repositories/providers | Movie, genre, actor, banner endpoints | Medium |
| MOB-013 Showtime/seat | Catalog; showtime/seat DTOs frozen | showtime/seat repositories/providers/models | Showtimes, seat map, status/type/price | High |
| MOB-014 Hold/booking | Seat; hold conflict/expiry contract | booking repositories/controllers | Hold, release/cancel, create/update booking | Critical |
| MOB-015 Quote/food/promotion | Booking; authoritative quote contract | catalog/booking/payment DTOs | Quote, food, voucher, discount fields | Critical |
| MOB-016 Payment | Auth + booking + payment return contract | payment repository, callback handling, platform config | Create payment, callback, status verification | Critical |
| MOB-017 Ticket/history | Payment confirmation and ticket contract | orders/ticket repositories/models | Booking detail/history, QR payload | High |
| MOB-018 Secondary customer features | Canonical endpoint evidence | account/notification/review/wishlist/AI features | Exact feature-specific contracts | Medium |

## Recommended order

```text
Choose canonical backend
→ freeze auth/envelope/error contract
→ network foundation
→ auth
→ catalog
→ showtime/seat
→ hold/booking
→ quote/food/promotion
→ payment callback/verification
→ ticket/history
→ secondary features
```

Do not begin MOB-010 until the P0 blockers in `04-INTEGRATION-BLOCKERS.md` are resolved or explicitly accepted by the backend owner.
