# Customer Integration Protection Map

This map is a guardrail for future UI work. UI changes may restyle presentation, but must not silently replace or bypass these paths.

| Integration | Current Flutter files | Protection requirement | Risk |
|---|---|---|---|
| Authentication | `features/auth/data/remote_auth_repository.dart`, `auth_remote_data_source.dart`, `application/auth_session.dart`, `core/auth/token_storage.dart`, `features/auth/presentation/widgets/auth_guard.dart` | Preserve token/session lifecycle, redirect continuation, guest/auth guard and error mapping. | HIGH |
| Movie/catalog | `features/movie/data/repositories/remote_catalog_repository.dart`, `catalog_providers.dart`, movie DTOs | Keep provider identity, pagination/filter parameters and remote DTO mapping. | HIGH |
| Cinema | catalog repository/DTOs, showtime provider | Do not replace remote cinema selection with fixtures. | MEDIUM |
| Showtime | `features/showtime/presentation/providers/showtimes_provider.dart`, showtime repositories/DTOs | Preserve movie/date/cinema query and showtime ID passed into seat route. | HIGH |
| Seat map | `seat_map_provider.dart`, `seat_selection_page.dart` | Keep runtime seat status, selected seats and refresh behavior. | CRITICAL |
| Seat hold | `seat_hold_repository.dart`, `remote_seat_hold_repository.dart`, `seat_hold_providers.dart`, `booking_entry_session.dart` | Never fake hold success; preserve TTL/countdown, release and conflict handling. | CRITICAL |
| Checkout quote | booking repositories/providers, `checkout_page.dart`, food quote DTOs | Keep quote request payload, recalculation and server totals. | CRITICAL |
| Payment | `payment_repository.dart`, `remote_payment_repository.dart`, `payment_providers.dart`, `payment_launcher.dart` | Preserve provider selection, external launch/return, idempotency and result handling. | CRITICAL |
| Booking completion | `booking_completion_controller.dart`, booking repository/providers | Preserve completion ordering and no duplicate booking/payment calls. | CRITICAL |
| Ticket/QR | `ticket_page.dart`, booking DTOs/repository | Render server ticket/QR data; do not derive production QR locally. | HIGH |
| Booking history/detail | orders provider, booking repository, `orders_page.dart`, `ticket_page.dart` | Preserve pagination/list/detail/cancel/rebook status mapping. | HIGH |
| Account/profile | account repositories/providers, `account_detail_pages.dart` | Preserve remote profile/password mutations and auth refresh. | HIGH |

## Explicit no-touch set for any UI-only batch

Do not modify repositories, providers, controllers, DTOs/mappers, API/network/auth infrastructure, routing/guards, platform files, assets, tests or dependency manifests unless a later approved task explicitly expands scope. UI-B01 in particular must touch only the four theme/token files listed in the implementation plan.

## Audit validation record

- Frontend application source: not modified by this audit; pre-existing `package-lock.json` change was observed and preserved.
- Backend application source: not modified.
- Flutter application source outside documentation: not modified.
- Flutter tests/assets/configuration: not modified.
- Documentation scope: only `docs/ui-parity/customer` is intended to change.
- Stop condition: documentation only; do not implement UI-B01 without explicit approval.
