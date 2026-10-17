# Reusable Component Mapping

Mapping is based on components actually found in Web `src/components/common/`, `src/layouts/`, and Mobile `lib/core/widgets/` / feature widgets. A dash means no single shared counterpart was established; use a screen-local component only after confirming reuse need.

| Web component / pattern | Mobile counterpart | Mapping / gap |
|---|---|---|
| `Button` (`components/common/Button.jsx`) | `AppButton` | Map variants, loading/disabled and touch feedback; preserve callback/action. |
| bespoke black card / common modal surface | `AppSurface` | Common container/surface; specialized media and seat cells stay feature-specific. |
| `.section-heading`, `.section-title` | `AppSectionHeader` | Map title/subtitle/divider hierarchy; relax desktop uppercase/tracking on narrow layouts. |
| `MovieCard` | `NowShowingCard`, `ComingSoonCard`, `DiscoverMovieCard`, `ShowtimeMovieCard` | Domain-specific mobile cards already exist; align image/title/meta/CTA treatment rather than create a generic card. |
| `HeroBannerCarousel` | `HeroCard` | Preserve prominent featured content, adapt carousel/height/indicators to phone and screen reader. |
| Web poster `<img>` patterns | `AppImage` | Normalize poster ratio, crop, placeholder and failure state. |
| Header search / `QuickBookingBar` search inputs | `SearchBar` | Search query behavior stays intact; align clear/filter affordance. Quick booking has no 1:1 shared counterpart. |
| Explore filter buttons/chips | `AppChip`, `FormatFilterChips`, `SegmentedControl` | Shared semantic selected/disabled state; maintain filter IDs/status logic. |
| Web booking status labels | `AppChip`, `ShowtimeStatusCard`, feature status widgets | No single component maps every status; preserve status values and meaning. |
| Web age/rating badge | `AgeBadge` | Direct conceptual counterpart; preserve rating value and contrast. |
| Web price rows / totals | no single shared price widget established | Keep page-local existing presentation; align typography only. Never recompute quote or totals. |
| Web info cards | `AppSurface`, `CinemaInfoSheet` | Surface vs cinema-specific sheet; preserve information order and actions. |
| Web account menu rows | `AccountMenu` and account menu widgets | Native grouped navigation; preserve destinations/auth gating. |
| Web wallet card/transaction list | Wallet feature page widgets + `AppSurface` | Feature-specific remote state already exists; map balance emphasis and transaction density. |
| Web loyalty/membership card | `MembershipCard`, Points page widgets | Map points balance/expiry/redeem affordance; preserve config and remote refresh. |
| `EmptyState` | `RepositoryStatePane` / feature empty widgets | Mobile shared state wrapper; keep meaningful per-feature copy and retry/action. |
| `LoadingState` / skeleton | `RepositoryStatePane` and feature loading widgets | Keep current loading semantics; skeleton style only. |
| Web page error/Toast | `RepositoryStatePane`, app feedback | Map recoverable vs terminal error and retry; do not swallow API failures. |
| `Modal` / AuthModal / Header watchlist drawer | native page, dialog, or bottom sheet | Accepted adaptation. No requirement for a 1:1 overlay replica. |
| `Table` | list/card presentation using `AppSurface` | Mobile card/list is accepted; preserve row fields, sort/order and actions. |
| Web desktop navigation | `CinemaHeader`, `CinemaBottomNav` | Mobile-native navigation; preserve auth and route behavior. |
| `Toast` | app feedback | Map transient feedback accessibly; don't make essential error state transient-only. |

## Reuse rule

Prefer evolving these existing Mobile widgets and feature components. Do not create a second parallel design system or replace feature state widgets merely to mimic the Web DOM structure.
