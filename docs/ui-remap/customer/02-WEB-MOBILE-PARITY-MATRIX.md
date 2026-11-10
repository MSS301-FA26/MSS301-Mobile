# Web → Mobile Customer Parity Matrix

Each row corresponds to one of the 21 screen/flow units defined in `00-WEB-CURRENT-SCREEN-INVENTORY.md`. Exactly one classification is assigned per row. Design classification is not a backend contract certification.

| Web screen / flow | Web source | Mobile equivalent | Classification | Priority | Rationale |
|---|---|---|---|---|---|
| Home | `/` → `HomePage` | `/home` → `HomePage` | PARTIAL | P1 | Capabilities and hierarchy exist; composition/hero and section density need native-specific remap. |
| Discover / search | `/movies` → `ExplorePage`, Header search | `/discover` → `DiscoverPage` | PARTIAL | P1 | Search/filter/pagination exist; control and result hierarchy need consistent remap. |
| Movie detail, reviews, recommendations | `/movies/:id` → `MovieDetailPage` | `/movie/:id` → `MovieDetailPage` | PARTIAL | P1 | Same key areas exist; backdrop/poster, information grouping and lower-page hierarchy need comparison/polish. |
| Cinema / showtimes | `/showtimes` → `ShowtimesPage` | `/showtimes` → `ShowtimesPage` | PARTIAL | P1 | Native destination exists; cinema/date/movie/showtime information hierarchy is a remap target. |
| Seat selection | booking step in `BookingPage` | `/seat-selection/:showtimeId` | PARTIAL | P0 | Core flow exists, but dense seat-map readability, legend, selection summary and sticky CTA are high-risk usability areas. |
| Booking-attached concessions | `BookingPage` food step | `/booking/:bookingId/concessions` | PARTIAL | P1 | Capability exists; selection/price/continuation hierarchy differs across web step vs native route. |
| Standalone food order | `/concessions` → `ConcessionsPage` | `/preview/food` only (preview) | DEFER_BACKEND | P1 | No production ordering screen. Although controller and Gateway paths exist, the current controller accepts a nullable principal and falls back to a fixed user ID; customer auth safety is not proven for this flow. |
| Checkout quote | `BookingPage` checkout step | `/booking/:bookingId/checkout` | PARTIAL | P0 | Real quote flow exists; order of summary, price emphasis and confirmation CTA warrants focused remap. |
| Payment method / callback result | `BookingPage` payment states, `/payment-callback` | `/payment/:paymentId` | PARTIAL | P1 | Real payment/result destination exists; Web callback vs native result presentation differs; preserve provider return semantics. |
| Ticket / QR | ticket content in `/tickets` | `/ticket/:bookingId` | PARTIAL | P1 | QR/ticket exist; verify scanability, status, ticket details and action hierarchy at mobile sizes. |
| Booking history / detail | `/tickets` tickets tab and detail | `/orders` | PARTIAL | P1 | History and detail exist; card/list layout adaptation is accepted, but content density and status hierarchy need visual review. |
| Standalone food order history | `/tickets` food tab | `/account/food-orders` | ACCEPTED_MOBILE_DIFFERENCE | P2 | Separate native account route is an intentional mobile information-architecture adaptation; preserve history/QR states. |
| Login | `AuthModal` login | `/auth/login` | ACCEPTED_MOBILE_DIFFERENCE | P2 | Modal → dedicated native page is explicitly accepted. |
| Register | `AuthModal` register | `/auth/register` | ACCEPTED_MOBILE_DIFFERENCE | P2 | Modal → dedicated native page is explicitly accepted; verification state remains. |
| Forgot password | `AuthModal` forgot mode | `/auth/forgot-password` | ACCEPTED_MOBILE_DIFFERENCE | P2 | Multi-step modal → native page/step flow is explicitly accepted. |
| Account / profile | `/profile` profile sections | `/account`, `/account/profile`, `/account/security` | PARTIAL | P1 | Mobile splits account overview/profile/security appropriately; consistency across entry points and information hierarchy needs polish. |
| Wallet | wallet panel in `/profile` | `/account/wallet` | ACCEPTED_MOBILE_DIFFERENCE | P2 | Embedded Web panel → dedicated native destination is accepted; core remote capability exists. |
| Loyalty / redeem | loyalty panel in `/profile` | `/account/points` | ACCEPTED_MOBILE_DIFFERENCE | P2 | Embedded panel → dedicated native destination is accepted; redeem/config and refresh behavior already implemented. |
| Watchlist | `/watchlist` and Header drawer | `/preview/favorites` only | DEFER_BACKEND | P1 | Mobile has only provisional preview; do not implement until a stable customer-facing API/Gateway/auth contract is verified. |
| Google password setup | `/setup-password` | no current production equivalent | DEFER_BACKEND | P2 | Web route is tied to Google-auth password setup. Current Backend customer auth controller has no matching setup-password operation; no Mobile implementation should be inferred. |
| Policy / information | `/policies` | `/information/policies`, plus cinema/support info routes | ACCEPTED_MOBILE_DIFFERENCE | P3 | Static/reference content can be organized as native informational destinations; no layout parity needed. |

## Totals

| Classification | Count |
|---|---:|
| MATCH | 0 |
| PARTIAL | 11 |
| ACCEPTED_MOBILE_DIFFERENCE | 7 |
| MISSING_IN_MOBILE | 0 |
| DEFER_BACKEND | 3 |
| NOT_APPLICABLE | 0 |
| **Total Web screen/flow units** | **21** |

## Interpretive notes

- The Web `BookingPage` is a multi-step screen; its seat, booking food, checkout, and payment states are split into separate Mobile routes. This is an accepted structural difference but does not imply visual parity.
- Search is a state/entry inside Web navigation and `/movies`, not a separate routed page. It is grouped with Discover.
- `MISSING_IN_MOBILE` is zero: no audited flow met the threshold to claim that a supported, safely consumable customer contract exists and only its Mobile presentation is absent.
- `DEFER_BACKEND` is conservative: current Web source presence and a routed path alone do not prove a safe Mobile-consumable public API/auth contract. No unsupported feature should be implemented based only on UI appearance.
