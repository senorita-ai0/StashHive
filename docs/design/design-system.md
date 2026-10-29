# StashHive — Design System

**Status:** Updated to the shared premium component language used by FinMate and Stockly; app-specific layouts remain StashHive's own.

## Brand and semantic palette

| Token | Value | Use |
|---|---|---|
| `color.brand` | `#2563EB` | Primary actions, selected states, focus and navigation |
| `color.brand-dark` | `#60A5FA` | Primary actions on dark surfaces |
| `color.mint` | `#17C7A1` | Positive accents and the secondary brand color |
| `color.violet` | `#8B7CFF` | Secondary emphasis |
| `color.text-primary` | `#10203A` | Headings and primary labels |
| `color.text-secondary` | `#65738B` | Supporting labels and metadata |
| `color.surface` | `#FFFFFF` | Cards and controls in light mode |
| `color.surface-muted` | `#F6F8FC` | Light app background |
| `color.border` | `#E3E8F0` | Input, card and divider boundaries |
| `color.dark-canvas` | `#07111F` | Dark app background |
| `color.dark-surface` | `#101B2C` | Dark cards, fields and navigation |
| `color.success` | `#16A34A` | Success, paired with text/icon |
| `color.warning` | `#D97706` | Warning and data-loss guidance |
| `color.danger` | `#DC2626` | Destructive actions and errors |
| `color.type-image` | `#218F84` | Image type with an explicit label |
| `color.type-document` | `#3673BE` | Document type with an explicit label |

## Layout and typography

- Spacing rhythm: 4, 8, 12, 16, 20, 24, 32 and 40 dp.
- Content cards: 24 dp radius; hero panels: 28 dp radius; controls: 17 dp radius.
- Primary text uses confident Material 3 weights and compact heading tracking without reducing readability.
- Minimum standard icon/tap targets are 44 dp; primary buttons and icon buttons use at least 48 dp when layout permits.
- Use system text scaling; do not lock content into fixed-height containers where larger text can clip.
- The premium hero gradient runs from `#1D4ED8` through `#2563EB` to `#17C7A1`.

## Shared components

`lib/ui/premium_kit.dart` is the shared component kit imported from FinMate and Stockly. It provides:

- `PremiumTokens`: brand colors, hero gradient, card/control radii and page padding.
- `PremiumPageHeader`: consistent large page title and subtitle.
- `PremiumHeroCard` / `PremiumProfileHero`: gradient hero surfaces.
- `PremiumSection`, `PremiumTile`, `PremiumSwitchTile`, `PremiumIconChip`: grouped settings-style rows and icon chips.
- `PremiumEmptyState` and `PremiumSkeletonList`: consistent empty/loading states.
- `PremiumReveal`: brief entrance motion that respects reduced-motion preferences.

Use `PremiumTokens` and shared kit widgets rather than introducing slightly different colors or radii in each page. Keep content-list items quieter than action/hero surfaces so the saved content remains the focus.

## Iconography and branding

- Use rounded Material icons with a consistent visual weight and clear tooltips for icon-only actions.
- Use the StashHive hive mark as the identity cue; do not borrow FinMate financial symbols or Stockly inventory/category graphics.
- Android adaptive icons and the web favicon use StashHive's own blue-and-mint hive mark, not another app's logo.
- Pair type color with a visible text label or semantic label; color alone is not sufficient.

## Responsive and accessible behavior

Provide visible focus, semantic labels, keyboard order on web, reduced-motion support, and clear validation/error associations. Cards should wrap long titles, chips should scroll when necessary, and screen-reader users must receive the same essential status information as sighted users.

## Source of truth

Use the seven screen IDs and layouts in [Premium Screen Reference](screen-reference.md). The shared FinMate/Stockly kit sets reusable styling, but StashHive's capture, search, organization, privacy and backup flows remain governed by its own requirements. Record any material deviation in the screen reference and traceability matrix.
