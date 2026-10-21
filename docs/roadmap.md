# StashHive — Roadmap and Implementation Plan

**Status:** Implementation in progress — Phase 2. Blueprint approved on 2026-10-21; validation workflow is intentionally manual-only.

## Milestones

### M0 — Blueprint approval and feasibility spikes

| Task | Scope | Requirements | Status | Exit criteria |
|---|---|---|---|---|
| TSK-001 | Review/approve requirements, platform split, MVP exclusions | All | DONE | User approves `docs/BLUEPRINT_REVIEW.md` or requests a revision. |
| TSK-002 | Verify current local Flutter/Dart and Android toolchain | NFR-009 | NOT STARTED | Record versions and `flutter doctor` output; no SDK upgrade without reason. |
| TSK-003 | Compare storage candidates on Android + web | FR-012–015, NFR-003, NFR-007 | NOT STARTED | Create/read/update/delete, tags, migrations, 1k/10k metadata benchmark, browser restart, export/restore concept pass. |
| TSK-004 | Android share-intent spike for URL/text/image/file | FR-009 | IN PROGRESS | At least one source app successfully shares each supported MIME type; cancellation/error behaviors documented. |
| TSK-005 | OCR/PDF extraction feasibility spike | FR-016, NFR-005, NFR-008 | NOT STARTED | Compare offline options for language support, sample accuracy, binary-size increase, latency and memory. No library commitment until results. |
| TSK-006 | Backup format proof of concept | FR-012–013 | IN PROGRESS | Versioned manifest plus files restores on a clean test profile; corrupt archive rejected safely. |
| TSK-007 | Expand competitor scan from screenshot apps to mixed-content libraries and validate the proposed differentiator | RSK-008, product success definition | IN PROGRESS | Record direct competitors, repeated negative-review themes, evidence links, and user test questions; do not claim a gap based only on a short search. |

### M1 — Foundation and capture

| Task | Scope | Requirements | Status | Exit criteria |
|---|---|---|---|---|
| TSK-101 | Initialize Flutter project, analysis options, formatting and test structure | NFR-009 | IN PROGRESS | Android and web debug builds run; analysis/test commands documented and successful. |
| TSK-102 | Implement domain entities and storage repository behind an interface | FR-001–003, FR-010 | IN PROGRESS | CRUD and migration tests pass; restart persistence works. |
| TSK-103 | Build design-system tokens and responsive navigation | FR-004, FR-011, NFR-006 | IN PROGRESS | Library, Search, Collections, Settings navigation works at mobile and desktop widths. |
| TSK-104 | Manual save/edit flows for link and note | FR-002, FR-006–007 | IN PROGRESS | Validation, offline use, editing and search tests pass. |
| TSK-105 | Add image and document/file import on supported platforms | FR-001, FR-008 | IN PROGRESS | File MIME/size validation, storage, restart, deletion and error states tested. |

### M2 — Library and retrieval

| Task | Scope | Requirements | Status | Exit criteria |
|---|---|---|---|---|
| TSK-201 | Unified list, type filters, favorites, sort, empty/error/loading states | FR-004 | IN PROGRESS | UI/integration tests cover each filter and no-result state. |
| TSK-202 | Metadata search and Unicode test matrix | FR-005, NFR-005, NFR-007 | IN PROGRESS | Tests for English, Urdu-script user-entered text, Roman Urdu, emoji, accents and punctuation pass. |
| TSK-203 | Item details, tags, collections, favorites | FR-010–011 | IN PROGRESS | Collection/tag edits remain consistent after restart; deletion semantics tested. |
| TSK-204 | Android share intake integration | FR-009 | IN PROGRESS — source added; build/device validation pending | The supported share formats from TSK-004 work end-to-end and do not duplicate on repeated event delivery. |
| TSK-205 | Extracted text indexing if POC passes | FR-016 | BLOCKED | Starts only after TSK-005 passes and user approves any material increase in app size/scope. |

### M3 — Data portability and hardening

| Task | Scope | Requirements | Status | Exit criteria |
|---|---|---|---|---|
| TSK-301 | Implement versioned export archive | FR-012 | IN PROGRESS | Backup contains manifest, metadata, attachments and version; paths and sizes validated. |
| TSK-302 | Implement restore and conflict strategy | FR-013 | IN PROGRESS | Valid archive restored; corrupt/unknown-version archives rejected with no partial corruption. |
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


## Suggested development order (updated 2026-10-21)

1. **Phase 1 — Core local library:** source is implemented. Historical CI passed analyzer, tests and web build; the Android APK failed because the generated runner could not resolve FilePickerPlugin. StashHive now pins file_picker 12.3.0 as an unverified mitigation.
2. **Phase 2 — Capture and recovery:** validate Android URL/text/image/document share intake; add repository persistence, attachment, restore and manifest tests.
3. **Phase 3 — Platform assurance:** compare screens against the SVGs; validate browser persistence and real-device file/share flows; improve accessibility, backup recovery and performance.
4. **Later phases:** consider OCR only after an offline feasibility study, then run the full manual validation workflow at the owner's release checkpoint.

## Release gate

MVP must not be described as ready until create/edit/delete, link open, supported attachment import, metadata search, restart persistence, backup/restore, platform limitations, privacy, and target-device/browser smoke tests have evidence recorded in the traceability matrix.



## Phase 2 — capture from other Android apps (started 2026-10-21)

| Task | Scope | Status | Exit criteria |
|---|---|---|---|
| TSK-204 | Register supported Android share intents; receive incoming URL/text/image/document and prefill Quick Save | IN PROGRESS — sequential multi-item source added; device test pending | Share from browser/text app/files app; review each supported item one at a time; unsupported/oversized entries are skipped with feedback; confirm save/cancel flows. |
| TSK-306 | Repository persistence and attachment restore regression tests | IN PROGRESS — tests added, manual run pending | Saved data survives Hive reopen; attachment survives restore with an ID collision; collection deletion keeps its items. |
| TSK-307 | Idempotent Android manifest configurator and tests | IN PROGRESS — source added, Python test pending | Adds supported MIME filters once, sets singleTask, and fails clearly if MainActivity is missing. |
| TSK-308 | Manual-only validation workflow | DONE | Workflow only has workflow_dispatch; commits/pushes do not trigger builds. |
| TSK-309 | Resolve historical Android FilePickerPlugin registration/build failure | IN PROGRESS — file_picker 12.3.0 declared; manual Android build pending | The generated Android runner compiles and produces a debug APK with incoming-share filters registered. |

| TSK-310 | Strict backup decoding and failed-import regression coverage | IN PROGRESS — source/tests added, manual run pending | Invalid item shapes, malformed collections and unreferenced attachments are rejected; a malformed mixed batch writes no records; assigned collection references survive round-trip. |
| TSK-311 | Restore write-phase rollback | IN PROGRESS — rollback strengthened and fault-injection test added; manual run pending | An exception after staged item/attachment writes removes imported payloads and preserves pre-existing data and collection preferences; real device/storage interruption remains documented. |
| TSK-312 | Preserve attachments on failed item edits | IN PROGRESS — save rollback strengthened and fault-injection test added; manual run pending | If the item map write fails after replacement bytes are staged, the prior item and attachment are preserved; new staged bytes are removed when there were no prior bytes. |

The owner requested development first and builds at the final checkpoint. Do not dispatch GitHub Actions unless the owner explicitly asks for validation. A successful manual workflow will retain the web build and Android debug APK artifacts for 14 days.


## Phase 2 refinement — 2026-10-21

Share de-duplication happens at event intake using a short three-second window. This suppresses near-simultaneous initial-intent/stream duplicates while allowing a later deliberate re-share. The new regression test is authored but intentionally unrun; CI remains manual-only.


## Android toolchain follow-up — 2026-10-21

The previous manual-run candidate failed with a missing FilePickerPlugin symbol in generated Android registration. Updated file_picker from 11.0.3 to 12.3.0 based on upstream notes indicating the AGP 9 registration fix is in 12.x. Keep this task IN PROGRESS until a later manually requested Android build confirms the result; no workflow was dispatched for this change.


## Multi-item share handling — 2026-10-21

Share batches are now presented as sequential Quick Save drafts instead of silently preparing only the first item. Each draft shows its position in the batch. A skipped unsupported or unreadable item reports feedback and does not prevent later supported items from being offered. This is source-complete but still requires manual Dart tests and Android device verification; workflow_dispatch remains the only CI trigger.


## Backup integrity increment — 2026-10-21

TSK-310 adds strict shape/type checks ahead of model construction, validates collection and attachment metadata, rejects unattached payload blobs, and preserves item-assigned collection names in backup round-trips. Regression tests are authored but unrun. Storage interruption after the write phase begins remains a separate recovery test, not claimed as solved.


## Restore rollback increment — 2026-10-21

TSK-311 hardens restore cleanup after a failure during the write phase. Imported identifiers are selected against both item and attachment box keys, every staged entry is eligible for rollback, and cleanup attempts continue even if one delete fails. A test-only fault-injection hook covers failure just before collection preference commit. This is not claimed as crash-atomic storage behavior until manual tests have run.


## Attachment edit integrity — 2026-10-21

TSK-312 addresses a data-loss path in save(): replacement bytes previously overwrote the old attachment before the item record was committed, and a failed record write deleted that key. Save now snapshots the existing attachment and best-effort restores it on failure; a test seam covers the failure between attachment staging and record commit. CI remains manual-only; this regression has not been run.
