# AI Studio to Flutter feature mapping

The AI Studio export under `docs/ui-reference/ai-studio/` is a visual and interaction reference. Flutter uses native widgets, GoRouter, Riverpod, and structured mock presentation data. This document maps the full export; only Phase 1 and Phase 2 are implemented.

## Screens

| AI Studio screen | Flutter feature | Phase 1/2 status |
| --- | --- | --- |
| `HomeScreen.tsx` | `features/home/presentation` | Implemented |
| `MovieDetailScreen.tsx` | `features/movie/presentation` | Route and visual placeholder |
| `DiscoverScreen.tsx` | `features/search/presentation` | Deferred |
| `ShowtimesScreen.tsx` | `features/showtime/presentation` | Deferred; also supplies the calendar tab |
| `SeatsScreen.tsx` | `features/seat/presentation` | Deferred |
| `ConcessionsScreen.tsx` | `features/food/presentation` | Deferred |
| `PaymentScreen.tsx` | `features/checkout/presentation` and `features/payment/presentation` | Deferred |
| `OrdersScreen.tsx` | `features/booking/presentation` | Deferred |
| `TicketDetailScreen.tsx` | `features/ticket/presentation` | Deferred |
| `AccountScreen.tsx` | `features/profile/presentation` | Deferred |
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

## Navigation scope

The active Flutter routes are `/home` and `/movie/:id`. Home movie taps open the Movie Detail placeholder; back returns to Home. The five-tab bar matches the reference visually. Other tab destinations and the booking flow are deferred with clear provisional feedback, so Phase 1/2 does not imply completed screens or backend behavior.

No API client, repository, use case, data source, or backend integration belongs in this phase.
