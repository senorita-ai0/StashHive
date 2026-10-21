# StashHive — Screen Inventory

**Status:** Seven static core-screen references are committed in `docs/design/screens/`; see [Premium Screen Reference](screen-reference.md).

| Screen ID | Screen | Purpose | Main actions | Required states | Requirements |
|---|---|---|---|---|---|
| SCR-001 | Library | Search-first landing and recent items. | Search, add, type filter, favorites, sort, open. | Empty, loading, error, no results. | FR-004, FR-005 |
| SCR-002 | Quick Save / Add Item | Capture link, note, image or document. | Select type, input/pick file, tags, collection, save/cancel. | Validation, canceled picker, unsupported file, share errors. | FR-001, FR-002, FR-006–009 |
| SCR-003 | Search Results | Local metadata search across types. | Edit/clear query, filter/sort, open result. | No results, local store error, Unicode, extraction unavailable. | FR-004–005, FR-016 |
| SCR-004 | Item Details | Display content and real storage state. | Open link/file, edit, favorite, move, delete. | Missing file, broken URL, unsupported viewer, extraction unavailable. | FR-003, FR-006, FR-011, FR-017 |
| SCR-005 | Collections & Tags | Lightweight grouping and cross-cutting labels. | Create/rename/delete collection, add/remove tags. | Empty collection, duplicate tag, safe delete. | FR-010 |
| SCR-006 | Backup & Privacy | Portable export/restore and local-data guidance. | Export, restore, review privacy warning. | Progress, cancel, failure, invalid backup, conflict, quota error. | FR-012–015, FR-018 |
| SCR-007 | Settings | Real preferences and data-management controls. | Theme/text, backup/privacy, help, about. | Platform limitations, large text, unavailable features. | FR-018, NFR-002–006 |

## Navigation

Android: Library, Search, Collections and Settings. Quick Save and Item Details are focused screens with back navigation; Backup & Privacy opens from Settings. Web uses the same conceptual destinations but platform-specific import/storage controls.

The mockups show the intended primary state only. Build all listed error, empty, loading, validation and permission states as part of implementation.
