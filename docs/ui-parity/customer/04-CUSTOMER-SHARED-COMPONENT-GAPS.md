# Customer Shared Component Gaps

| Gap | Web evidence | Mobile impact | Recommended reusable component | Priority |
|---|---|---|---|---|
| Customer shell parity | Header/footer, search, account, watchlist drawer and active navigation in `UserLayout` | Every screen feels like a different product | Enhance `AppShell`, `CinemaHeader`, `CinemaBottomNav` | P0 |
| Editorial typography | Serif/italic movie titles and uppercase micro-labels | Movie/catalog hierarchy is flatter | `AppDisplayText`, `AppEyebrow`, `AppMetaLine` | P0 |
| Movie card variants | `MovieCard` is used across Home/Explore/detail recommendations | Cards need consistent poster ratio, status, rating, wishlist and CTA | `CustomerMovieCard` with compact/grid/hero variants | P0 |
| Hero/banner | `HeroBannerCarousel` and Home hero | Flutter home lacks equivalent responsive banner behavior | `CustomerHeroCarousel` | P0 |
| Filter/date/showtime controls | Explore filters and Showtimes date/showtime chips | Feature-local controls drift | `FilterChip`, `DateStrip`, `ShowtimeChip` variants | P0 |
| Booking progress | Web booking has multi-step sections; Flutter has `booking_progress.dart` | Flow boundary differs | Make `BookingProgress` a shared shell with state/expiry semantics | P0 |
| Seat legend/map states | Web seat map within booking; Flutter seat page/provider | Need exact available/held/selected/sold/blocked semantics | `SeatLegend`, `SeatCell`, `SeatMapSurface` | P0 |
| Price/order summary | Web quote/checkout and ticket cards | Summary formatting varies by feature | `OrderSummaryCard`, `MoneyLine`, `DiscountLine` | P1 |
| Auth presentation | Web modal; Flutter route | Entry and continuation feel inconsistent | `CustomerAuthScaffold` + auth modal/route adaptive wrapper | P1 |
| Cards/surfaces | Web thin borders and restrained radius | Flutter 16px rounded cards are more generic | `CustomerSurface`, `CustomerCard` with variants | P1 |
| State patterns | Web loading/empty/error/toast; Flutter repository pane | Copy, spacing and retry behavior drift | `CustomerLoading`, `CustomerEmpty`, `CustomerError`, `CustomerToast` | P1 |
| Dialog/drawer | Trailer/auth/watchlist patterns | No common overlay treatment | `CustomerDialog`, `CustomerBottomSheet`, `CustomerDrawer` | P1 |
| Food/concessions cards | Web purple food catalog and cart | Mobile production/preview separation unclear | `ConcessionCard`, `CartBar`, `QuantityStepper` | P1 |
| Ticket/QR | Web tickets/history and Flutter ticket page | Need consistent QR hierarchy and actions | `TicketCard`, `QrTicketPanel`, status badge | P1 |
| Profile/membership | Web profile includes membership/wallet/loyalty surfaces | Mobile has split account widgets/routes | `MembershipCard`, `WalletTile`, `AccountMenu` alignment | P2 |
| Accessibility/focus | Web buttons include focus-visible and disabled styles | Shared Flutter states need explicit contrast/focus/semantics | State-aware button/input contracts | P1 |
