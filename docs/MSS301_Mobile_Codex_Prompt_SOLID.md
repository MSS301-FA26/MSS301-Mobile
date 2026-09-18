# MSS301 Mobile UI - Codex Implementation Prompt

## Context

I am building `MSS301-Mobile`, a Flutter mobile application for a movie ticketing platform similar to MoMo, but with more features.

Current backend:
- Spring Boot Microservices
- API Gateway
- Backend integration will be done later

Current goal:
- Rebuild the updated Mobile UI exported from Google AI Studio in native Flutter
- Use AI Studio source only as UI/design reference
- Focus on UI, navigation, reusable components, responsive layout, and mock data
- Do not integrate backend yet

---

## Reference Sources

Before coding, inspect these if they exist:

```text
docs/MSS301_Mobile_Codex_UI_Plan.md
docs/ui-reference/ai-studio/
docs/ui-reference/screenshots/
assets/
pubspec.yaml
lib/
```

The AI Studio export may contain:

```text
README.md
metadata.json
package.json
src/
vite.config.ts
tsconfig.json
```

Important:

- The AI Studio source is a reference only.
- Do NOT copy React/Vite/TypeScript code directly into Flutter.
- Do NOT modify the AI Studio reference files.
- Extract from AI Studio:
  - screens
  - component hierarchy
  - colors
  - typography
  - spacing
  - border radius
  - icons
  - assets
  - navigation behavior
  - mock content
  - reusable UI patterns

Flutter implementation must follow native Flutter conventions.

---

# Architecture

Use:

```text
Feature-first
+
Clean Architecture (pragmatic / simplified during UI phase)
+
MVVM-style Presentation
+
Riverpod
+
GoRouter
+
SOLID
```

During the current UI phase, prioritize:

```text
Feature
└── Presentation
    ├── Pages
    ├── Widgets
    └── Providers / Notifiers only when state is needed
```

Do NOT create empty `data/`, `domain/`, repository, usecase, datasource, or service layers just to make the folder tree look complete.

Add those layers only when backend integration or real business logic requires them.

---

# Target Project Structure

```text
lib/
├── core/
│   ├── constants/
│   ├── routing/
│   │   └── app_router.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   ├── app_spacing.dart
│   │   └── app_theme.dart
│   └── utils/
│
├── shared/
│   └── widgets/
│       ├── app_button.dart
│       ├── app_icon_button.dart
│       ├── app_image.dart
│       ├── app_section_header.dart
│       └── app_loading.dart
│
├── features/
│   ├── home/
│   │   └── presentation/
│   │       ├── pages/
│   │       ├── widgets/
│   │       └── providers/
│   │
│   ├── movie/
│   ├── showtime/
│   ├── booking/
│   ├── seat/
│   ├── food/
│   ├── checkout/
│   ├── payment/
│   ├── ticket/
│   ├── search/
│   ├── notification/
│   ├── auth/
│   ├── profile/
│   └── chatbot/
│
└── main.dart
```

Do not over-engineer the folder structure.

---

# Required Packages

Use if not already installed:

```yaml
flutter_riverpod:
go_router:
```

Do not add Dio yet unless backend integration starts.

Before adding any extra dependency:
1. Check if Flutter SDK already supports the requirement.
2. Only add the package if it provides clear value.
3. Explain why it is needed.

---

# SOLID Requirements

Apply SOLID pragmatically.

## S — Single Responsibility Principle

Each class, widget, provider, and file should have one clear responsibility.

Good:

```text
HomePage
→ compose Home screen

MovieCard
→ render one movie card

GenreSelector
→ render and manage genre selection UI

MovieNotifier
→ manage movie-related presentation state
```

Bad:

A single class that:
- renders UI
- calls API
- stores app state
- performs navigation
- formats business data
- manages persistence

Avoid giant files and giant widgets.

---

## O — Open/Closed Principle

Reusable components should be extendable through configuration instead of repeatedly modifying internal code.

Prefer:

```dart
AppButton(
  label: 'Continue',
  variant: AppButtonVariant.primary,
  onPressed: () {},
)
```

over duplicating multiple button implementations.

Do not create unnecessary abstraction for static widgets.

---

## L — Liskov Substitution Principle

When abstractions are introduced later, implementations must be replaceable without changing expected behavior.

Example for future backend integration:

```text
MovieRepository
├── MovieRepositoryImpl
└── MockMovieRepository
```

Presentation should work with either implementation through the abstraction.

---

## I — Interface Segregation Principle

Do not create huge shared interfaces.

Bad:

```text
AppRepository
- login
- getMovies
- createBooking
- pay
- getProfile
```

Prefer feature-specific abstractions later:

```text
AuthRepository
MovieRepository
BookingRepository
PaymentRepository
ProfileRepository
```

---

## D — Dependency Inversion Principle

When real data integration starts:

```text
View
↓
Notifier / ViewModel
↓
UseCase when needed
↓
Repository abstraction
↑
Repository implementation
↓
Remote datasource
```

UI must never directly depend on HTTP clients or databases.

Do not call Dio from widgets.

Use Riverpod for dependency injection when appropriate.

For the current mock UI phase, do not create fake abstractions just to demonstrate DIP.

---

# UI Coding Rules

## Must

- Use `const` wherever possible
- Use centralized theme
- Use reusable widgets
- Keep widgets small and focused
- Use `SafeArea`
- Prevent overflow
- Support phone portrait layouts
- Use mock data
- Use native Flutter layout primitives
- Use meaningful names
- Run `dart format`
- Keep code readable and maintainable

## Must Not

- Do not create 800-1000 line screen files
- Do not hard-code the same color in many files
- Do not hard-code repeated text styles
- Do not copy React/HTML/CSS mechanically
- Do not call backend APIs
- Do not modify backend
- Do not create empty architecture layers
- Do not put complex business logic inside widgets
- Do not redesign the UI unless the reference is unclear
- Do not change the package name
- Do not modify AI Studio reference code

---

# Design System

Implement Design System before major screens.

Create:

```text
lib/core/theme/app_colors.dart
lib/core/theme/app_text_styles.dart
lib/core/theme/app_spacing.dart
lib/core/theme/app_theme.dart
```

Use exact values from AI Studio if available.

If values are unclear:
- choose the closest reasonable value
- centralize it
- add a TODO comment for later refinement

Recommended spacing scale:

```text
4
8
12
16
20
24
32
```

Do not scatter magic spacing values everywhere.

---

# Routing

Use `GoRouter`.

Create:

```text
lib/core/routing/app_router.dart
```

Prepare routes such as:

```text
/home
/search
/movie/:id
/showtime/:movieId
/seat-selection/:showtimeId
/food
/checkout
/payment
/ticket/:bookingId
/profile
/notifications
/chatbot
```

Use mock IDs for now.

---

# Riverpod Usage

Use Riverpod only where state actually exists.

Examples:

- selected bottom navigation tab
- selected genre
- selected cinema
- selected showtime
- selected seats
- food quantities
- checkout state
- payment mock state

Do not create providers for purely static widgets.

Avoid unnecessary global state.

---

# Mock Data

Use structured mock data.

Do not dump large hard-coded maps directly inside widgets.

Example:

```dart
class MovieUiModel {
  final String id;
  final String title;
  final String posterUrl;
  final String genre;
  final String duration;
  final String releaseDate;

  const MovieUiModel({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.genre,
    required this.duration,
    required this.releaseDate,
  });
}
```

Mock models are temporary presentation models.

Do not build a full domain layer yet.

---

# Implementation Order

## Phase 1 — Foundation

Implement:

- folder structure
- theme
- typography
- spacing
- GoRouter
- Riverpod setup
- shared reusable widgets
- app shell
- bottom navigation if present in AI Studio

Acceptance criteria:

- app compiles
- app runs on Chrome
- navigation works
- no serious `flutter analyze` errors
- theme is centralized

---

## Phase 2 — Home Screen

Implement the latest Home screen from AI Studio.

Likely reusable widgets may include:

```text
home_header.dart
suggestion_chips.dart
popbot_banner.dart
genre_selector.dart
movie_section.dart
movie_card.dart
bottom_navigation.dart
```

Adjust names based on the actual exported design.

Requirements:

- use mock data
- match layout closely
- match spacing
- match typography
- match colors
- match cards
- preserve AI Studio interaction intent
- Movie Card navigation must open Movie Detail placeholder

---

## Phase 3 — Core Booking Flow

After Home is stable:

```text
Home
↓
Movie Detail
↓
Showtime Selection
↓
Seat Selection
↓
Food / Combo
↓
Checkout
↓
Payment
↓
Booking Success
↓
E-Ticket / QR
```

Implement UI and mock navigation only.

No backend yet.

---

# Seat Selection Requirements

Prepare UI states for:

```text
AVAILABLE
SELECTED
HELD
SOLD
VIP
COUPLE
```

UI should contain:

- seat legend
- seat grid
- selected seat list
- temporary mock price
- Continue CTA

Do not implement real-time seat locking yet.

---

# Checkout Requirements

Checkout should display mock snapshot data for:

- movie
- cinema
- room
- showtime
- seats
- ticket type
- food/combo
- promotion
- subtotal
- discount
- total

Do not implement real payment.

---

# Payment Requirements

Implement only UI and mock state:

```text
payment method
order summary
pay button
processing
success
failed
```

Do not store sensitive payment data.

---

# Ticket Requirements

Prepare ticket UI for:

- movie title
- cinema
- room
- showtime
- seats
- booking code
- QR placeholder
- ticket status

---

# Responsive Requirements

Primary target:

```text
Android / iOS phone portrait
```

Check layouts near widths:

```text
360
390
412
```

Prefer:

```text
Expanded
Flexible
Wrap
LayoutBuilder
MediaQuery
AspectRatio
```

Avoid absolute full-screen dimensions when unnecessary.

---

# Assets

Use:

```text
assets/
├── images/
├── icons/
├── logos/
└── mock/
```

Update `pubspec.yaml`.

If an asset is missing, use a clear placeholder and add a TODO.

---

# Validation

After each phase run:

```bash
dart format .
flutter analyze
```

When applicable:

```bash
flutter test
flutter run -d chrome
```

Do not continue to the next phase while compile errors remain.

---

# Git Guidelines

Use small commits.

Examples:

```text
chore: setup mobile architecture
feat: add mobile design system
feat: implement home screen
feat: implement movie detail screen
feat: implement showtime selection
feat: implement seat selection ui
feat: implement checkout ui
feat: implement payment ui
feat: implement ticket ui
```

Do not commit build/cache files.

---

# Task for This Codex Run

For this run, implement ONLY:

```text
Phase 1
+
Phase 2
```

Do not implement the whole application.

Before changing code, inspect the repository and report:

1. Current Flutter project structure
2. Screens discovered in the AI Studio export
3. Reusable components discovered
4. Design tokens identified
5. Assets identified
6. Files you plan to create or modify
7. Packages you plan to add
8. Any unclear or missing UI information

Then implement:

- Feature-first structure
- centralized design system
- Riverpod setup
- GoRouter setup
- shared widgets required by Home
- Home screen matching the latest AI Studio UI
- mock data
- Movie Detail placeholder route

Finally run:

```bash
dart format .
flutter analyze
```

If possible:

```bash
flutter run -d chrome
```

Report:

- files created
- files modified
- packages added
- remaining TODOs
- any visual assumptions made

---

# Core Principle

AI Studio is the UI/design source of truth.

Flutter code must be native, maintainable, reusable, responsive, and easy to integrate with the Spring Boot Microservices backend later.

Do not sacrifice maintainability just to reproduce pixels.
