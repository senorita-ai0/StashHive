# StashHive — Proposed Design System

**Status:** Draft tokens for blueprint review. Exact values may change after a Flutter implementation spike.

## Principles

1. Search is the primary task; organizing is secondary.
2. Content preview and title are more important than decorative gradients.
3. Content types should be recognizable but not rely on color alone.
4. Controls and typography should remain comfortable at narrow phone widths and large text settings.
5. Destructive actions are visually separated from routine actions and offer confirmation/undo where feasible.

## Proposed tokens

| Token | Proposed value / rule | Use |
|---|---|---|
| `color.brand` | Indigo `#5B5CE2` | Primary actions, selected nav/filter, focus accents |
| `color.brand-soft` | Lavender `#EEF0FF` | Soft selected background |
| `color.text-primary` | Deep navy `#18213D` | Titles and primary labels |
| `color.text-secondary` | Slate `#626D86` | Secondary metadata |
| `color.surface` | Warm white `#FFFFFF` | Main surfaces |
| `color.surface-muted` | `#F7F8FC` | App background and subtle section surfaces |
| `color.border` | `#E5E8F2` | Dividers, input and card outlines |
| `color.success` | Deep green with text/icon | Confirmation, not large decorative banner |
| `color.danger` | Accessible red | Delete/error only |
| `space.1`–`space.8` | 4, 8, 12, 16, 20, 24, 32, 40 dp | Consistent spacing; avoid arbitrary per-screen values |
| `radius.card` | 16 dp (starting point) | Content cards |
| `radius.control` | 12 dp (starting point) | Inputs, buttons, filter chips |
| `type.body` | 14–16 sp with system scaling | General body content |
| `type.caption` | 12–13 sp; never the only source of meaning | Dates and supporting metadata |
| `type.heading` | 20–24 sp responsive | Screen headings |

## Components to standardize

- App shell/navigation for Android and web responsive layouts.
- Search field with clear button, filters and visible focus state.
- Filter chips and content-type badges.
- Saved-item card variants: image, link, text, document.
- Collection/tag chips.
- Empty/loading/error cards.
- Save/edit form fields and URL validation messages.
- Destructive confirmation and undo affordance.
- Backup/restore progress, success, failure, and unknown-version states.

## Responsive behavior

- Narrow phone: one-column list, search on top, horizontally scrollable type filters, bottom navigation if it remains accessible and does not obscure content.
- Wide screen: constrained content width, optional side navigation, library/detail split view only if it simplifies use.
- Keyboard: visible focus and sensible tab order on web; no hover-only interactions.
- Large text: allow labels and card content to wrap; never clip titles or core buttons.

## Accessibility checks

- Do not encode content types only by color; include labels/icons with accessible names.
- Check text/background contrast, focus visibility, keyboard navigation, semantics, input errors, and scaling.
- Motion is optional and should respect reduced-motion settings where applicable.
- The target for the public web experience is WCAG 2.2 AA as a design goal, not a compliance claim.
