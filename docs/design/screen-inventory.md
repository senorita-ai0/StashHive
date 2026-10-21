# StashHive — Screen Inventory

**Status:** Proposed screens. The design image currently covers SCR-001, SCR-003, and SCR-004 only as a combined concept board.

| Screen ID | Screen | Purpose | Main actions | Key states | Requirements |
|---|---|---|---|---|---|
| SCR-001 | Library | Starting point showing recently saved/all items with obvious search. | Search, add, filter by type, favorites, sort, open item. | First-run empty state, populated list, loading, load error, no results. | FR-004, FR-005 |
| SCR-002 | Quick Save / Add Item | Save a URL, text note, selected image/document, or shared content. | Choose type, paste/edit URL/text, title, tags, collection, save/cancel. | Validation, permission/picker denied, unsupported file, duplicate suggestion later. | FR-001, FR-002, FR-006–009 |
| SCR-003 | Search Results | Show matches with highlighted matching metadata/text where supported. | Clear query, change type filter, open result, refine query. | No results, query error, unsupported extracted text. | FR-004–005, FR-016 |
| SCR-004 | Item Details | Show saved item and distinguish URL/attachment/preview state. | Open link/file, edit, favorite, move collection, delete. | Missing file, broken URL, unsupported viewer, extraction unavailable. | FR-003, FR-006, FR-011, FR-017 |
| SCR-005 | Collections & Tags | Organize saved items. | Create/rename/delete collection, add/remove tags, open collection. | Empty collection, duplicate tag name, delete confirmation. | FR-010 |
| SCR-006 | Backup & Privacy | Explain local data and let users export/restore. | Export backup, select backup to restore, see result, read privacy/data warning. | Export progress/cancel/failure, invalid backup, unknown version, insufficient storage. | FR-012–015, FR-018 |
| SCR-007 | Settings | Manage display/search/backup/privacy options; no login setting required. | Theme (if approved), data/privacy info, storage info, app version. | Browser limitations, storage pressure, unavailable capability. | FR-018, NFR-002–006 |

## Navigation proposal

Android: Library, Search, Collections, Settings. A visible add action is available on the library screen and in supported share-import flows. Web: same conceptual destinations using responsive navigation; do not assume OS share target support in browser.

## Review checklist

- Every Must journey has a screen and error/empty state.
- Save forms make the item type and storage state clear.
- Link, downloaded/copied file, metadata preview, and offline webpage snapshot are never visually conflated.
- Bulk operations are not required for MVP but can be added later if library management tests justify them.
