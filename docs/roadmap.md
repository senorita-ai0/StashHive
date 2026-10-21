# StashHive — Roadmap and Implementation Plan

**Status:** Planning draft. No product source files or runtime dependencies should be added before blueprint approval.

## Milestones

### M0 — Blueprint approval and feasibility spikes

| Task | Scope | Requirements | Status | Exit criteria |
|---|---|---|---|---|
| TSK-001 | Review/approve requirements, platform split, MVP exclusions | All | IN PROGRESS | User approves `docs/BLUEPRINT_REVIEW.md` or requests a revision. |
| TSK-002 | Verify current local Flutter/Dart and Android toolchain | NFR-009 | NOT STARTED | Record versions and `flutter doctor` output; no SDK upgrade without reason. |
| TSK-003 | Compare storage candidates on Android + web | FR-012–015, NFR-003, NFR-007 | NOT STARTED | Create/read/update/delete, tags, migrations, 1k/10k metadata benchmark, browser restart, export/restore concept pass. |
| TSK-004 | Android share-intent spike for URL/text/image/file | FR-009 | NOT STARTED | At least one source app successfully shares each supported MIME type; cancellation/error behaviors documented. |
| TSK-005 | OCR/PDF extraction feasibility spike | FR-016, NFR-005, NFR-008 | NOT STARTED | Compare offline options for language support, sample accuracy, binary-size increase, latency and memory. No library commitment until results. |
| TSK-006 | Backup format proof of concept | FR-012–013 | NOT STARTED | Versioned manifest plus files restores on a clean test profile; corrupt archive rejected safely. |
| TSK-007 | Expand competitor scan from screenshot apps to mixed-content libraries and validate the proposed differentiator | RSK-008, product success definition | IN PROGRESS | Record direct competitors, repeated negative-review themes, evidence links, and user test questions; do not claim a gap based only on a short search. |

### M1 — Foundation and capture

| Task | Scope | Requirements | Status | Exit criteria |
|---|---|---|---|---|
| TSK-101 | Initialize Flutter project, analysis options, formatting and test structure | NFR-009 | NOT STARTED | Android and web debug builds run; analysis/test commands documented and successful. |
| TSK-102 | Implement domain entities and storage repository behind an interface | FR-001–003, FR-010 | NOT STARTED | CRUD and migration tests pass; restart persistence works. |
| TSK-103 | Build design-system tokens and responsive navigation | FR-004, FR-011, NFR-006 | NOT STARTED | Library, Search, Collections, Settings navigation works at mobile and desktop widths. |
| TSK-104 | Manual save/edit flows for link and note | FR-002, FR-006–007 | NOT STARTED | Validation, offline use, editing and search tests pass. |
| TSK-105 | Add image and document/file import on supported platforms | FR-001, FR-008 | NOT STARTED | File MIME/size validation, storage, restart, deletion and error states tested. |

### M2 — Library and retrieval

| Task | Scope | Requirements | Status | Exit criteria |
|---|---|---|---|---|
| TSK-201 | Unified list, type filters, favorites, sort, empty/error/loading states | FR-004 | NOT STARTED | UI/integration tests cover each filter and no-result state. |
| TSK-202 | Metadata search and Unicode test matrix | FR-005, NFR-005, NFR-007 | NOT STARTED | Tests for English, Urdu-script user-entered text, Roman Urdu, emoji, accents and punctuation pass. |
| TSK-203 | Item details, tags, collections, favorites | FR-010–011 | NOT STARTED | Collection/tag edits remain consistent after restart; deletion semantics tested. |
| TSK-204 | Android share intake integration | FR-009 | NOT STARTED | The supported share formats from TSK-004 work end-to-end and do not duplicate on repeated event delivery. |
| TSK-205 | Extracted text indexing if POC passes | FR-016 | BLOCKED | Starts only after TSK-005 passes and user approves any material increase in app size/scope. |

### M3 — Data portability and hardening

| Task | Scope | Requirements | Status | Exit criteria |
|---|---|---|---|---|
| TSK-301 | Implement versioned export archive | FR-012 | NOT STARTED | Backup contains manifest, metadata, attachments and version; paths and sizes validated. |
| TSK-302 | Implement restore and conflict strategy | FR-013 | NOT STARTED | Valid archive restored; corrupt/unknown-version archives rejected with no partial corruption. |
| TSK-303 | Platform-specific web persistence and data-loss messaging | FR-015 | NOT STARTED | Same browser profile reload retains test data; different browser does not imply sync; clearing-data warning is clear. |
| TSK-304 | Privacy, accessibility and security review | FR-018, NFR-002, NFR-006 | NOT STARTED | Permission list justified; no saved-content logs; keyboard/contrast/large-text checklist complete. |
| TSK-305 | Performance and recovery regression suite | NFR-003, NFR-007–009 | NOT STARTED | Benchmark report and known limits documented; key flows recover from interrupted operations. |

### M4 — Closed validation, monetization decision, release readiness

| Task | Scope | Requirements | Status | Exit criteria |
|---|---|---|---|---|
| TSK-401 | Opt-in user test and feedback review | Product success definition | NOT STARTED | Users complete save/search/retrieve/backup tasks; key confusion points fixed. |
| TSK-402 | Decide monetization after usage validation | Out of MVP | NOT STARTED | Separate approval for ads or premium; no SDK before its cost/privacy/store implications are reviewed. |
| TSK-403 | Store/domain/trademark/package ID and release checklist | Release gate | NOT STARTED | Public brand is checked; build/sign/store requirements are verified for target platform. |
| TSK-404 | Release candidate build and smoke tests | All Musts | NOT STARTED | Real Android device and web browser test results recorded; no hidden critical blockers. |

## Suggested development order

The first coding increment should be a thin vertical slice: launch app → save a text note/link → persist locally → restart → search and retrieve. Then prove attachment import and storage. Do not start OCR or visual polish before persistence/retrieval fundamentals are proven.

## Release gate

MVP must not be described as ready until create/edit/delete, link open, supported attachment import, metadata search, restart persistence, backup/restore, platform limitations, privacy, and target-device/browser smoke tests have evidence recorded in the traceability matrix.


## Implementation status update — 2026-10-21

The owner approved BUILD mode. TSK-001 (blueprint approval) is now **DONE**. Initial Phase 1 code has been authored for the app shell, local repository, manual save/edit, metadata search, collections/tags, item detail, selected-file imports and version-1 JSON backup/restore. TSK-101 and TSK-102 are **IN PROGRESS — verification pending** because the authoring environment has no Flutter/Dart executable. GitHub Actions is configured to run format, analysis, unit tests and a web build; check its actual run before claiming success.

Next: resolve CI findings, run on a real Android device and Chrome, validate storage/backup edge cases, then wire Android share-intent intake. OCR remains gated; do not promise search inside images/PDFs until tested.


## Current implementation progress — 2026-10-21

- **DONE:** Owner approved the blueprint and visual reference.
- **IN PROGRESS:** Initial Flutter app shell, local persistence, save/edit, metadata search, collections/tags, item detail, file selection and backup/restore are in source; CI is diagnosing the first compile/analyzer issues.
- **IN PROGRESS:** Static tests cover model round-trip, metadata query/Unicode, and versioned backup validation.
- **NOT VERIFIED:** All unit tests, Android build/device run, web release build, actual file import/share behavior, backup recovery under interruption.
- **NEXT:** Finish CI, fix actual failures, manually verify Android and web, then implement Android share-receiver intake.
