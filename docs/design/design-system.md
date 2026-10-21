# StashHive — Design System

**Status:** Draft; illustrated in [Premium Screen Reference](screen-reference.md).

| Token | Value | Use |
|---|---|---|
| color.brand | #5B5CE2 | Primary actions, selection, focus |
| color.brand-soft | #EEF0FF | Selected backgrounds |
| color.text-primary | #1B2340 | Titles and primary labels |
| color.text-secondary | #7B849D | Supporting metadata |
| color.surface | #FFFFFF | Cards and controls |
| color.surface-muted | #F8F9FD | App background |
| color.border | #E7E9F2 | Inputs, cards, separators |
| color.success | #2F8968 | Success with icon/text |
| color.warning | #B87A22 | Backup and data-loss notice |
| color.danger | #C74A5B | Destructive actions/errors |
| color.type-image | #218F84 | Image type (with a text label) |
| color.type-document | #3673BE | Document type (with a text label) |
| space.1–space.8 | 4, 8, 12, 16, 20, 24, 32, 40 dp | Consistent rhythm |
| radius.card | 14–16 dp | Content cards |
| radius.control | 12–14 dp | Inputs, buttons, chips |
| type.body | 14–16 sp with system scaling | Body |
| type.caption | 11–12 sp, not sole meaning | Dates and metadata |
| type.heading | 24–28 sp, responsive | Screen title |

## Component rules

- Reuse the app shell, header, bottom navigation, search field, type chip, saved-item card, type badge, tag chip, collection row and primary button.
- Pair content-type color with a text label or accessible icon; color alone is insufficient.
- Search is prominent; saved content previews remain the focus.
- Do not hardcode version, item counts, backup dates or storage meters; mockup values are illustrative.
- Bookmark, copied attachment, metadata preview and offline snapshot are separate states.

## Responsive and accessible behavior

Allow text to wrap under system scaling. Provide visible focus, semantic labels and keyboard order on web. Use adequate contrast, touch-sized targets, accessible error associations and reduced-motion behavior where needed.

## Source of truth

Use the seven IDs and layouts in [Premium Screen Reference](screen-reference.md). If implementation needs to deviate for platform behavior or usability, update the reference, screen inventory, requirements mapping and tests together.
