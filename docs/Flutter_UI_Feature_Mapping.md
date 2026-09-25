# AI Studio to Flutter feature mapping

The AI Studio export under `docs/ui-reference/ai-studio/` is a visual and interaction reference. Flutter uses native widgets, GoRouter, Riverpod, and structured mock data. This document maps the full export; Phase 1/2 and work packages R1–R3 are implemented. Existing screens now consume the backend-aligned mock repositories; no real API is connected.

## Screens

| AI Studio screen | Flutter feature | Current status |
| --- | --- | --- |
| `HomeScreen.tsx` | `features/home/presentation` | Repository-backed mock UI; responsive/navigation regression covered |
| `MovieDetailScreen.tsx` | `features/movie/presentation` | Repository-backed detail content, trailer and booking route active |
| `DiscoverScreen.tsx` | `features/search/presentation` | Repository-backed mock UI under current `features/discover` alias |
| `ShowtimesScreen.tsx` | `features/showtime/presentation` | Repository-backed typed schedule; valid slots open seat selection through auth gate |
| `SeatsScreen.tsx` | `features/seat/presentation` | R4 implemented: typed seat map, local selection, hold, timer, conflict/expiry and leave guards |
| `ConcessionsScreen.tsx` | `features/food/presentation` | Deferred |
| `PaymentScreen.tsx` | `features/checkout/presentation` and `features/payment/presentation` | Deferred |
| `OrdersScreen.tsx` | `features/booking/presentation` | Reads `BookingRepository` under current `features/orders` alias; ticket/refund deferred |
| `TicketDetailScreen.tsx` | `features/ticket/presentation` | Deferred |
| `AccountScreen.tsx` | `features/profile/presentation` | Composes profile/wallet/loyalty repositories under current `features/account` alias; child routes deferred |
| `WalletScreen.tsx` | `features/wallet/presentation` | Deferred |
| `VouchersScreen.tsx` | `features/promotion/presentation` | Deferred |
| `VoucherDetailScreen.tsx` | `features/promotion/presentation` | Deferred |
| `LoginScreen.tsx` | `features/auth/presentation` | Deferred |
| `RegisterScreen.tsx` | `features/auth/presentation` | Deferred |
| `PopBotScreen.tsx` | `features/chatbot/presentation` | Deferred |
| `HelpScreen.tsx` | `features/support/presentation` | Deferred |

`payment-result` appears in the reference screen-name type but has no matching screen component. The exported `App.tsx` uses `ShowtimesScreen` both for movie showtimes and the calendar tab. Future Flutter pages can share that feature's showtime widgets.

## Shared UI patterns

- `Header.tsx`, `BottomNav.tsx`, and `Logo.tsx`: primary five-tab shell, compact CP logo, cinema identity, search, notifications, account action, and a back/title header on subpages. The Phase 1 shell is in `lib/shared/widgets/`.
- `CinemaPickerModal.tsx`: cinema information bottom sheet. Phase 2 has a native Flutter information sheet with mock cinema details.
- `TrailerModal.tsx`: trailer preview dialog. Phase 2 has a native preview dialog; video playback is deferred.
- `QRModal.tsx`: reusable ticket QR sheet for the future ticket feature.
- `components/auth/`: auth layout, form/password fields, avatar and genre selectors, and primary/social buttons. These belong to the future auth feature; common button styling belongs in `shared/widgets`.
- Repeated screen patterns: section headings, horizontal filter chips, movie cards, status/rating badges, booking summary cards, bottom action bars, tabs, and modal sheets. Share widgets only when at least two Flutter screens need the same behavior.

## Design system

| Token | Reference value | Flutter location |
| --- | --- | --- |
| Background | `#0E0E0F` | `core/theme/app_colors.dart` |
| Surface / raised / border | `#171719` / `#202024` / `#2B2B30` | `core/theme/app_colors.dart` |
| Gold accent | `#F5B800` | `core/theme/app_colors.dart` |
| Purple / lavender | `#6F00BE` / `#DDB7FF` | `core/theme/app_colors.dart` |
| Main / secondary / muted text | `#FFFFFF` / `#D4D4D8` / `#A1A1AA` | `core/theme/app_colors.dart` |
| Typography | Inter; strong 18–23 px headings and 10–14 px UI text | `core/theme/app_text_styles.dart`, bundled font |
| Spacing and radii | 4 px spacing scale; 8/12/16 px radii | `core/theme/app_spacing.dart` |
| Main header and bottom nav | 64 px each | `core/theme/app_spacing.dart` |

The reference uses Material Symbols. Flutter uses the closest built-in Material icons, avoiding an icon dependency for Phase 1/2.

## Assets and mock content

AI Studio has no bundled image or font assets. Its movie data contains external URLs, some of which resolve to unrelated UI mockups. Flutter bundles mock posters and banners under `assets/mock/movies/`, with provenance and remaining banner TODOs in `assets/mock/README.md`. Inter and its license are under `assets/fonts/`. The Phase 2 Home screen uses eight structured mock movies and one mock cinema.

## Backend-aligned contract foundation

R2 is implemented without connecting to a real API:

- shared response/page parsing, `AppClock`/`FakeAppClock`, integer IDs and integer VND money;
- backend-shaped catalog, showtime/seat map, checkout quote, booking, payment, profile, wallet, withdrawal and loyalty DTOs;
- enum parsing with an `unknown` fallback and explicit catalog-seat-to-booking-seat mapping;
- repository interfaces, in-memory mock implementations and Riverpod provider bindings;
- deterministic scenario data for Inception, the 20:30 showtime, seats C4/C5, 90.000đ tickets, the 89.000đ combo and a 269.000đ quote;
- contract and repository lifecycle tests, including hold conflict/expiry and the separate payment `SUCCESS` → booking `PAID` transition.

R3 connects Home, Discover, Movie, Showtimes, Orders and Account to this local repository boundary. Presentation-only metadata stays outside backend DTOs, while IDs, date/time, VND values and contract statuses remain typed through the mapper boundary.

## Navigation scope

The active Flutter routes are `/home`, `/discover`, `/showtimes`, `/orders`, `/account`, and `/movie/:id`. `/showtimes` accepts an optional `movieId` query. The five-tab bar, movie detail navigation, filtered booking entry, Search/Account header actions, and cinema information sheet are active. Actions without a destination are disabled or hidden according to `MOBILE_CTA_ROUTE_REGISTRY.md`; seat selection, ticket, auth/account child routes, and preview flows remain deferred.

No API client, remote data source, or backend integration is active. Local repository interfaces and mock implementations are the active data boundary for R3.
