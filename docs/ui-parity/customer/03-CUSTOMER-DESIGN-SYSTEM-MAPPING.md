# Customer Design System Mapping

## Web source observations

| Concern | Web evidence | Flutter current mapping | Classification |
|---|---|---|---|
| Backgrounds/surfaces | `UserLayout`, `Header`, pages: black, `#0a0a0a`, `#0d0f14`, translucent white borders | `AppColors.background`, `surface`, `surfaceHigh`, `surfaceRaised` | GLOBAL |
| Primary/accent | White primary actions, amber/gold selection and CTA; purple concessions accents | `gold`, `goldDim`, `purple`, `deepPurple`, `lavender` | GLOBAL |
| Text | Uppercase microcopy, wide tracking, white/neutral gray; editorial serif/italic display headings plus sans UI | Inter-only `AppTheme`; `AppTextStyles` has compact sans scale | GLOBAL |
| Typography | Large hero/title, 9–12px labels, 14–18px body/section, bold CTA labels | `heroTitle 22`, `screenTitle 22`, `sectionTitle 18`, `body 13`, `caption 11`, button 14 | GLOBAL |
| Spacing | 4/8/12/16/24-ish rhythm, dense grids, generous hero sections | `AppSpacing` 4/8/12/16/20/24/32 | GLOBAL |
| Radius | Mostly square/small controls and cards; dialogs/drawers use restrained radius | Flutter card 16, control 12, small 8 | GLOBAL |
| Shadows/borders | Thin white-alpha borders, dark overlays/backdrop blur, selective shadow | Theme elevation is minimal; shared widgets need explicit border/overlay recipes | GLOBAL |
| Cards/images | Movie poster cards ~2:3; hero/banner ~16:9; cinema/food cards | `AppImage`, movie/home/discover cards; aspect ratio needs consistency | GLOBAL |
| Buttons | Filled white/amber, outlined white, dark bordered, compact uppercase; disabled/hover/focus states | `AppButton` primary/secondary/purple, 46px height, rounded | GLOBAL |
| Inputs/forms | Dark fields, thin borders, compact labels, validation/error messages | Auth/account forms use native widgets; shared input recipe not clearly centralized | GLOBAL |
| Chips/badges | Genre/filter/showtime chips; age/status/upcoming badges | `AgeBadge`, feature-specific chips; consolidate variants | GLOBAL |
| Navigation | Web header + footer, customer tabs, watchlist drawer; Flutter `AppShell` header + bottom nav | `AppShell`, `CinemaHeader`, `CinemaBottomNav` | GLOBAL |
| Modals/dialogs | Auth modal, trailer dialog, watchlist drawer, backdrop blur | Trailer/dialog patterns are feature-local; no shared customer modal spec | GLOBAL |
| Loading/empty/error | `LoadingState`, `EmptyState`, Toast and per-page fallbacks | Riverpod AsyncValue and `RepositoryStatePane`; visual language differs | GLOBAL |

## Recommended token direction

Keep the existing backend-facing architecture and consolidate presentation around the current token files rather than changing contracts. Add semantic roles for web parity: `ink`, `surfaceOverlay`, `textFaint`, `accentPrimary`, `accentSecondary`, `danger`, `success`, `warning`, `focus`, plus explicit poster/hero aspect constants. Decide whether the final mobile brand keeps gold as primary; the web audit shows white/amber dominance and purple mainly for food/promotional accents.

## Mapping to shared Flutter artifacts

| Web concept | Flutter artifact | Action |
|---|---|---|
| Colors | `lib/core/theme/app_colors.dart` | Extend semantic aliases; do not change API behavior. |
| Theme | `lib/core/theme/app_theme.dart` | Centralize input, card, dialog, navigation and disabled states. |
| Typography | `lib/core/theme/app_text_styles.dart` | Add editorial/display and micro-label styles; retain Inter for body. |
| Spacing/radii | `app_spacing.dart` | Add grid/gutter/aspect constants and verify existing scale. |
| Buttons | `shared/widgets/app_button.dart` | Add web-aligned compact/outlined/danger/loading variants. |
| Shell | `shared/widgets/app_shell.dart`, `cinema_header.dart`, `cinema_bottom_nav.dart` | Align active states, search/account entry, and customer navigation. |
| Images/cards | `app_image.dart`, feature cards | Standardize ratios, placeholder, error and loading behavior. |
| States | `repository_state_pane.dart`, new shared state widgets | Align loading skeleton, empty, error and retry presentation. |
