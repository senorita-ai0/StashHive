# StashHive — Feature Backlog

**Last reviewed:** 2026-10-29  
**Implementation rule:** complete each feature as a small vertical slice: source, regression tests, user-facing behavior, documentation, and explicit verification status. Changes go directly to `main`; CI/builds remain manual-only.

## Principles

- Preserve StashHive's local-first and privacy-by-default behavior.
- Core library use must not require an account, cloud backend, or paid AI service.
- Do not claim cross-device sync, OCR, offline website archives, or link status without evidence.
- Avoid silent destructive actions. Duplicate candidates are suggestions; the user decides what to keep.
- Keep platform verification separate from source implementation. Do not report unrun tests/builds as passing.

## Prioritized backlog

| ID | Priority | Feature | Scope and acceptance criteria | Status |
|---|---|---|---|---|
| SH-001 | P1 | Duplicate link detection and review | Normalize URLs for duplicate checking (case-insensitive scheme/host, default ports, trailing slash, fragment and common tracking parameters). On a new link save, show matching saved links and ask whether to continue. Never silently discard or delete an item. Add tests for URL normalization, false-positive boundaries, and exclusion of the current edited item. Extend to exact attachment hashes only in a later slice. | SOURCE IMPLEMENTED — link-only review flow and regression source committed; execution pending |
| SH-002 | P1 | Advanced search and Smart Collections | Add type/tag/collection/domain/favorite/date filters and reusable saved filters. Filters must combine predictably, work offline, and persist locally. | SOURCE IMPLEMENTED — combined filters, saved presets and Organize Smart Searches; regression execution pending |
| SH-003 | P1 | Bulk actions | Allow multi-select, collection assignment, tag add/remove, favorite changes, export, and confirmed deletion. Partial failures must be reported and not silently lose items. | SOURCE IMPLEMENTED — selection, favorite, move, tag add/remove, confirmed delete, Markdown index export; tests unrun |
| SH-004 | P1 | Importers and portable exports | Support a documented, tested bookmark HTML importer and selected service exports where a stable format exists. Add CSV and Markdown export without removing versioned JSON backup/restore. Validate file sizes/shapes and preview import counts before writing. | SOURCE IMPLEMENTED — preview-first browser HTML import, CSV library export and Markdown selected-item index; tests unrun |
| SH-005 | P1 / gated | Local full-text extraction | Prototype offline text extraction for PDFs and OCR for supported images. Measure accuracy across English, Urdu-script samples, Roman Urdu, app size, latency, memory, and failure handling before adopting a dependency. | BLOCKED — desk research documented; runtime spike and measurements required. See `docs/research/local-text-extraction-feasibility.md` |
| SH-006 | P2 | Reader mode, highlights, and annotations | Add optional readable article content only through a user-initiated flow; support highlights and personal notes tied to a saved item. Clearly distinguish bookmark metadata, temporary preview, and an offline archive. | NOT STARTED |
| SH-007 | P2 | Visual library improvements | Improve image/document previews and add useful grid/masonry layouts without degrading list navigation, accessibility, or performance for large libraries. | SOURCE IMPLEMENTED — persistent grid/list toggle and regression source committed; execution pending |
| SH-008 | P2 | Smart organization rules | Offer user-controlled rules and suggested tags. Keep basic tagging functional without AI; suggestions must be explainable, optional, and reviewable before applying. | NOT STARTED |
| SH-009 | P2 | Link health and archive status | Provide an explicit user-triggered or configurable check, record last checked status and time, and explain that network failures may be temporary. No hidden background scraping. | NOT STARTED |
| SH-010 | P2 | Rediscovery and reading progress | Add optional unread/read status, progress, and a revisit view for older saved items. Reminders/notifications require separate UX and permission review. | PARTIAL SOURCE IMPLEMENTED — status/progress model and Item Details controls added; revisit view and verification pending |
| SH-011 | P3 | Optional cross-device sync | Design opt-in encrypted synchronization, conflict resolution, authentication and key recovery only after local reliability is validated. Android and web remain separate until sync is actually implemented and tested. | NOT STARTED |
| SH-012 | P3 | Feeds, newsletters, transcripts, and text-to-speech | Consider RSS/newsletter intake, supported transcript saving, and playback only after the core capture/find loop is stable. Keep network access and content source visible. | NOT STARTED |
| SH-013 | P3 | Semantic and visual discovery | Evaluate local semantic search, similar-image and color search only after performance/privacy feasibility is demonstrated; no required cloud embeddings or paid inference. | NOT STARTED |
| SH-014 | Ongoing | Platform assurance and recoverability | Continue Android share-intent device checks, browser persistence/quota tests, backup/restore and rollback regressions, accessibility checks, performance measurements, and resolution of the historical Android FilePickerPlugin build failure. | IN PROGRESS — manual verification pending |

## Delivery sequence

1. **SH-001:** duplicate links and review prompt.
2. **SH-002:** advanced filters and saved filters.
3. **SH-003:** multi-select and bulk actions.
4. **SH-004:** bookmark import and additional exports.
5. **SH-005:** offline extraction proof of concept; implementation only if evidence meets the size, language and performance gates.
6. **SH-006–SH-010:** reading and workflow enhancements.
7. **SH-011–SH-013:** optional sync and advanced discovery, after privacy/architecture review.

## Definition of done for each feature

- Acceptance criteria are documented and traceable to tests.
- Relevant unit/widget tests are authored and source-reviewed.
- Existing backup compatibility, deletion semantics, and local-data privacy are preserved.
- Error, empty, loading, cancellation, and accessibility states are covered where applicable.
- Documentation states what is and is not implemented.
- Tests/builds are run only at the owner's requested manual validation checkpoint; otherwise explicitly report them as unverified.
