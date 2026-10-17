# Design System Mapping — Web → Mobile

Read-only source comparison: Web `src/index.css`, customer JSX utility classes and common components vs Mobile `lib/core/theme/` and shared widgets.

| Dimension | Current Web source | Current Mobile source | Mapping guidance |
|---|---|---|---|
| Base/background | `#000`; global ambient radial glows; many local `#0a0a0a`, `#0d0f14` surfaces | `AppColors.background #000000`, surface `#0A0A0A`, high `#0D0F14` | Keep black cinema canvas and restrained raised surfaces; translate large ambient desktop glow into restrained native accents, not a full-bleed fixed effect. |
| Primary accent | Amber/gold utility values including `#F59E0B`, `#FBBF24`, Header `#F7C600`; purple/magenta glows | `gold #FBBF24`, `goldDim #DDAA00`, purple `#6F00BE`, lavender `#DDB7FF` | Consolidate gold usage semantically; reserve purple for secondary/brand accents. Avoid changing status meanings. |
| Text colors | White, neutral-200/300/400/500/600; frequent all-caps and tracking | `text`, `textSecondary #D4D4D8`, `textMuted #A1A1AA`, `textFaint #737373`, disabled | Preserve readable contrast; reduce desktop all-caps/tracking at small widths. |
| Typography | Inter configured as sans/serif/mono in `src/index.css`; default root 18px; headings clamp; bold uppercase labels | Inter; `AppTextStyles` 10–22px mobile scale | Keep Inter and semantic hierarchy; do not imitate Web's 18px root size literally on phone. Make prices/IDs tabular where useful. |
| Weight / letter spacing | Frequent 800/900, uppercase, tracking 0.1–0.2em | Mostly 700/800 with compact tracking in eyebrow/meta | Use stronger weight only for title/price/CTA; relax tracking for body and controls. |
| Spacing | Tailwind spacing, broad desktop section margins and max-width layouts | `AppSpacing` 4/8/12/16/20/24/32/40; 16 page gutter, 12 card gap | Map desktop macro spacing to stacked native sections; retain consistent 16px gutter and touch-friendly gaps. |
| Radii | Mixed square cinema booking (`.square-ui` forces 0) and rounded modal/cards; many sharp borders | card 16, control 12, small 8 | Prefer a coherent mobile system. Keep square/precise geometry for seat map/booking data only where it aids scanning; do not force all mobile surfaces square. |
| Borders / dividers | White translucent borders (`white/5`, `/10`, `/25`) and amber hover borders | `border #1AFFFFFF`, strong `#33FFFFFF`; Theme divider | Translate low-contrast borders; use strong border only for active/focus/selected. Avoid hover-only feedback. |
| Shadows / glow | Ambient fixed glows, backdrop blur, hover shadows/glows | Theme elevation 0; generally flat surfaces | Avoid desktop hover shadows; use elevation sparingly for sheets and important overlays. Respect reduced motion. |
| Cards / surfaces | `MovieCard`, bespoke page cards, black translucent panels | `AppSurface`, feature-specific cards | Standardize padding/border/radius through `AppSurface` while allowing media cards and seat cells specialized geometry. |
| Buttons | Common `Button` plus many bespoke uppercase utility buttons; hover inversion | `AppButton`, Theme filled-button gold style | Establish primary/secondary/destructive hierarchy with visible pressed/disabled/loading states, minimum touch targets. Do not change actions. |
| Inputs / search | Tailwind bespoke dark inputs; Header search; `QuickBookingBar` dropdowns | Theme filled input on `#0D0F14`, gold focus border; Discover `SearchBar` | Align focus/error/disabled presentation; ensure clear field labels and native keyboard affordance. Keep query/debounce behavior. |
| Chips / tabs / badges | Utility-class chips, uppercase filters; rating/status labels | `AppChip`, `AgeBadge`, segmented controls, feature status widgets | Define selected/unselected/status semantic variants; maintain age-rating and backend status meanings. |
| Navigation | Responsive Header + Footer desktop links; mobile menu; modal account actions | `CinemaHeader` + `CinemaBottomNav` | Keep mobile bottom nav/drawer as accepted adaptation; avoid importing dense desktop nav. |
| Status colors | Green/emerald, amber, rose/red, neutral; meanings can vary by page | success `#10B981`, warning `#F59E0B`, error `#F43F5E`, disabled `#262626` | Map by semantic state, not sampled hue. Ensure contrast and never infer backend status from color alone. |
| Poster / backdrop | Web carousel/backdrop large wide imagery, poster cards | `AppImage`, `HeroCard`, movie cards | Poster ratio 2:3; backdrop ~16:9/cinematic. Use correct crop/fallback and avoid stretching. |
| Prices | Often uppercase/large white or amber text among bespoke price blocks | Text styles and shared surfaces; page-specific formatting | Align currency formatting/weight only. Totals/discounts/fees remain server-derived and unchanged. |
| Empty / error / loading | Common `EmptyState`, `LoadingState`; page-specific error/empty branches | `RepositoryStatePane` and feature-specific states | Common visual shell, preserve page-specific retry/CTA and error semantics. Loading skeletons must not use mock data. |

## Key differences to resolve in implementation

1. Web's visual vocabulary is heterogeneous: broad black/amber theme with purple ambient accents and locally square booking surfaces. Mobile currently has more coherent semantic tokens and rounded 8/12/16 radii. Choose explicit contexts rather than flattening either system.
2. Web CSS root size, wide content, hover states and desktop hero composition are not mobile specifications. Carry over hierarchy, media identity, contrast and brand accents, not exact dimensions.
3. Mobile has a usable token layer already. UI-remap batches should first compare actual usages and adjust token/widget presentation only where screens are inconsistent; no API/provider/business edits are authorized by this plan.
