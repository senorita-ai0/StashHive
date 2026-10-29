# StashHive — UX/UI Design Pack

**Status:** Seven core screen mockups are now defined as the visual baseline for implementation review. They are static designs, not runtime screenshots.

## Primary reference

Read [Premium Screen Reference](screen-reference.md) for each mockup, its visible hierarchy, interactions, required extra states and requirement mapping. Individual editable SVGs are in `screens/`.

## Screen inventory

| ID | Screen | Mockup |
|---|---|---|
| SCR-001 | Library | [SVG](screens/scr-001-library.svg) |
| SCR-002 | Quick Save / Add Item | [SVG](screens/scr-002-quick-save.svg) |
| SCR-003 | Search Results | [SVG](screens/scr-003-search-results.svg) |
| SCR-004 | Item Details | [SVG](screens/scr-004-item-details.svg) |
| SCR-005 | Collections & Tags | [SVG](screens/scr-005-collections-tags.svg) |
| SCR-006 | Backup & Privacy | [SVG](screens/scr-006-backup-privacy.svg) |
| SCR-007 | Settings | [SVG](screens/scr-007-settings.svg) |

## Visual direction

Light neutral canvas, white surfaces, premium blue (#2563EB) actions, mint (#17C7A1) accents, deep-navy typography and restrained type accents. Cards use the shared 24 dp radius and hero surfaces use the blue-to-mint gradient. Search stays prominent; content is the visual focus. Screens must be responsive, accessible, and honest about local-storage and bookmark/file states.

## Implementation rule

Implement the layouts as the visual baseline, plus all empty/loading/error/permission/unsupported states specified in the reference and test plan. If real platform behavior requires a material deviation, update screenshots, this reference, screen inventory, requirements mapping and tests together.
