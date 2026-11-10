# MSS301 Mobile - Full Project Prompt

Use this prompt when asking Codex or another AI coding agent to work on this repository.

## Project Context

I am working on `MSS301-Mobile`, a Flutter mobile app for a cinema/movie-ticketing product named CinePremier. The app is designed for Android/iOS phone portrait first, with web/desktop platform folders present from the Flutter scaffold.

The backend is expected to be Spring Boot microservices behind an API Gateway, but the mobile app currently runs with mock repositories, typed DTOs, mappers, local fixtures, and preview feature repositories. Do not integrate real backend APIs unless explicitly requested.

Current stack:

- Flutter SDK / Dart `^3.13.3`
- `flutter_riverpod` for state management and dependency injection
- `go_router` for navigation
- `dio` for API Gateway HTTP client scaffolding
- `url_launcher` for VNPay/deep-link/in-app browser payment handoff
- Native Flutter Material UI
- Inter font from `assets/fonts/Inter-Variable.ttf`
- Mock movie assets under `assets/mock/movies/`

The app already has a feature-first structure with pragmatic Clean Architecture ideas. Preserve this structure and avoid large cross-feature refactors unless the task requires them.

## Current Repository Shape

Important files and folders:

```text
lib/
  app/
    app.dart
  main.dart
  core/
    config/
    constants/
    contracts/
    demo/
    money/
    network/
    routing/
    theme/
    time/
  shared/
    widgets/
  features/
    account/
    auth/
    booking/
    discover/
    home/
    movie/
    orders/
    payment/
    preview/
    seat/
    showtime/
assets/
  fonts/
  mock/movies/
docs/
test/
```

Key docs:

- `docs/MSS301_Mobile_Codex_Prompt_SOLID.md`
- `docs/MOBILE_API_READINESS_REPORT.md`
- `docs/BACKEND_ALIGNED_MOCK_UI_PLAN.md`
- `docs/BOOKING_FLOW_V2_REWORK_PLAN.md`
- `docs/CINEPREMIER_MOBILE_UI_FLOWS.md`
- `docs/MOBILE_CTA_ROUTE_REGISTRY.md`
- `docs/Flutter_UI_Feature_Mapping.md`
- `docs/ui-reference/ai-studio-v2/`

The AI Studio React/Vite exports under `docs/ui-reference/` are design references only. Do not modify them and do not copy React/TypeScript code directly into Flutter.

## App Architecture Rules

Use:

```text
Feature-first
+ pragmatic Clean Architecture
+ MVVM-style presentation where useful
+ Riverpod providers
+ GoRouter routes
+ SOLID, applied only where it reduces real complexity
```

Preserve this rough layering:

```text
feature/
  data/
    models/
    repositories/
    mappers/ when needed
    mock/ when needed
  application/ when feature orchestration is needed
  presentation/
    pages/
    providers/
    widgets/
    models/ when UI-specific models are needed
```

Do not create empty `domain`, `data`, `service`, `usecase`, or repository folders just to satisfy architecture. Add layers only when there is actual behavior to put there.

Widgets should stay small and focused. Avoid giant screen files. Extract repeated layout, visual patterns, and feature widgets into local `widgets/` folders or `shared/widgets/` when truly cross-feature.

## Existing Routing

Routing lives in:

- `lib/core/routing/app_routes.dart`
- `lib/core/routing/app_router.dart`

Current major routes include:

```text
/home
/discover
/showtimes
/orders
/account
/movie/:id
/seat-selection/:showtimeId
/auth/login
/auth/register
/auth/forgot-password
/account/profile
/account/security
/account/wallet
/account/points
/information/cinema
/information/policies
/support
/booking/:bookingId/concessions
/booking/:bookingId/checkout
/payment/:paymentId
/ticket/:bookingId
/preview/food
/preview/refund/:bookingId
/preview/vouchers
/preview/vip
/preview/favorites
/preview/notifications
/preview/popbot
```

Use `AppRoutes` helpers instead of hard-coding route strings in widgets.

## Existing Feature Areas

Implemented or scaffolded areas:

- Home: hero, quick actions, now showing, coming soon, genre selector, PopBot banner
- Discover: search/filter style browsing
- Movie: catalog DTOs, mock catalog repository, movie detail, trailer preview dialog
- Showtime: showtime pages, date selector, cinema status/card widgets
- Seat: seat selection page, seat map provider, booking entry session
- Booking: concessions, checkout, payment result, ticket page, booking progress
- Orders: order list, segmented tabs, order cards, ticket/order models
- Payment: payment DTO/enums/repositories with mock implementation
- Account: profile card, membership, wallet/points/security/profile/detail pages
- Auth: mock auth session, auth pages, auth guard
- Preview: provisional features for food, refund, vouchers, VIP, favorites, notifications, PopBot

When adding new behavior, first check whether a feature already has the correct repository/provider/page/widget to extend.

## Data And Backend Integration Rules

The project is backend-aligned but still mock-first.

Current backend/mobile integration scaffold:

- `lib/core/network/api_gateway_config.dart`
  - reads `MSS301_API_GATEWAY_URL`
  - reads `MSS301_USE_REMOTE_GATEWAY`
  - defaults to Android emulator gateway base URL `http://10.0.2.2:8080`
- `lib/core/network/api_gateway_client.dart`
  - exposes a Riverpod `Dio` provider
  - applies JSON headers and timeout configuration
  - maps HTTP `401` to a token-expired/unauthorized exception
- Existing feature repositories still bind to mock implementations by default.

Current payment handoff scaffold:

- `lib/features/payment/application/payment_launcher.dart`
  - supports VNPay mock URLs
  - supports in-app browser opening for real payment URLs
  - supports external-app/deep-link opening for banking app handoff
- `PaymentResultPage` shows the `paymentUrl`, opens VNPay handoff, then relies on backend/callback verification before issuing the QR ticket.
- Mock callback buttons remain available for demo/test only.

Existing repository examples:

- `CatalogRepository`
- `BookingRepository`
- `PaymentRepository`
- `AccountRepository`
- mock repository implementations and provider bindings

Keep mock repositories working for tests, demos, and offline development. If adding a remote repository later:

1. Keep the existing abstraction.
2. Add a remote implementation beside the mock implementation.
3. Switch binding through Riverpod/environment configuration.
4. Do not call HTTP clients from widgets.
5. Preserve DTO parsing fallbacks and `unknown` enum cases.

Backend contract expectations:

- Response envelope should be parsed consistently.
- Business IDs are integers unless a specific contract says otherwise.
- VND money values are integers, never floating point.
- Timestamps must include timezone or clear UTC handling, displayed for Vietnam users.
- Conflict/expired/validation states should be explicit, especially for booking holds.
- Payment success must come from backend verification, not client-side URL query trust.
- Idempotency keys are needed for hold, checkout, create payment, callback, and withdrawal flows.

Dio already exists as the project HTTP client scaffold. Do not add another HTTP dependency unless there is a clear, reviewed reason. Do not switch repositories from mock to remote unless the user explicitly asks for backend integration.

## UI And Design System Rules

Theme files live in:

```text
lib/core/theme/app_colors.dart
lib/core/theme/app_text_styles.dart
lib/core/theme/app_spacing.dart
lib/core/theme/app_theme.dart
```

Shared widgets live in:

```text
lib/shared/widgets/
```

Use existing colors, typography, spacing, buttons, image components, app shell, cinema header/nav/info components, and state panes before creating new variants.

UI requirements:

- Phone portrait first.
- Use `SafeArea` where appropriate.
- Avoid overflows at widths around 360, 390, and 412.
- Use `Expanded`, `Flexible`, `Wrap`, `LayoutBuilder`, `AspectRatio`, and scroll views intentionally.
- Use `const` constructors wherever possible.
- Keep spacing and colors centralized.
- Do not scatter magic colors or repeated text styles.
- Do not redesign the app unless the reference or task requires it.
- Do not put complex business logic in widgets.

The design should feel like a polished cinema/ticketing app: dark premium theme, clear movie artwork, ergonomic booking flow, and readable dense content where needed.

## Riverpod Rules

`main.dart` wraps the app in `ProviderScope`.

Use Riverpod where there is actual state or dependency injection:

- selected movie/showtime/date/cinema
- seat map and selected seats
- booking entry/completion state
- checkout/payment state
- account/auth summary state
- repository binding

Do not create providers for static widgets or constants.

## Testing And Validation

Existing tests include:

```text
test/backend_aligned_contract_test.dart
test/booking_entry_test.dart
test/completion_and_account_test.dart
test/home_navigation_test.dart
test/preview_flags_test.dart
```

After changes, run at minimum:

```bash
dart format .
flutter analyze
flutter test
```

If working on visual/navigation flows and the environment supports it, also run:

```bash
flutter run -d chrome
```

If working on native payment/deep-link/plugin integration and the environment supports it, also run:

```bash
flutter build apk --debug
```

On Windows, iOS builds cannot be validated locally. If Android SDK is not configured, report the exact SDK/`ANDROID_HOME` limitation instead of treating it as a code failure.

Do not leave analyzer errors. If tests cannot run due to environment limitations, clearly report what was attempted and why it failed.

## Feature Flags And Preview Areas

Some product areas are provisional and should remain behind preview/feature handling until backend contracts are stable:

- independent food ordering
- refunds
- vouchers
- VIP/membership expansion
- favorites
- notifications
- PopBot/chatbot

Use existing preview repository/page patterns instead of pretending these are fully integrated production features.

## Assets

Configured assets:

```yaml
assets:
  - assets/mock/movies/
fonts:
  - family: Inter
    fonts:
      - asset: assets/fonts/Inter-Variable.ttf
```

Before adding new assets, check existing assets. Update `pubspec.yaml` when adding new asset directories.

## Coding Style

Follow the existing Dart/Flutter style:

- Prefer typed DTOs/models over raw maps in widgets.
- Keep parsing logic in data/model layers.
- Keep UI mapping/state in providers or presentation models where appropriate.
- Use meaningful names.
- Prefer small methods/widgets over deeply nested build methods.
- Add comments only for non-obvious logic.
- Avoid unrelated refactors and metadata churn.
- Preserve user changes in the worktree.

## What Not To Do

- Do not modify `docs/ui-reference/ai-studio*` unless explicitly asked.
- Do not copy React/Vite/TypeScript directly into Flutter.
- Do not add backend calls during UI tasks.
- Do not remove mock repositories.
- Do not hard-code route strings where `AppRoutes` exists.
- Do not trust client-side payment callback query params as payment success.
- Do not introduce large abstractions without immediate need.
- Do not collapse feature boundaries into one shared mega-service.
- Do not commit build/cache files.

## Good Task Execution Pattern

For a coding task in this project:

1. Inspect relevant files first.
2. Identify the feature slice and existing patterns.
3. Make the smallest maintainable change.
4. Reuse existing theme/shared widgets/providers/routes.
5. Add or adjust focused tests when behavior changes.
6. Run `dart format .`, `flutter analyze`, and relevant tests.
7. Report files changed, validation results, and any remaining assumptions.

## Suggested First Message To Codex

```text
You are working in the MSS301-Mobile Flutter project.

Follow `docs/MSS301_Mobile_Full_Project_Prompt.md`.
Before editing, inspect the relevant feature files and existing patterns.
Use Riverpod, GoRouter, the existing theme/shared widgets, and mock repositories.
Do not integrate backend APIs unless I explicitly ask.
After changes, run dart format, flutter analyze, and relevant flutter tests.

Task:
[describe the exact feature, bug, UI change, or backend-integration slice here]
```

