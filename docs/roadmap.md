# StashHive — Roadmap and Implementation Plan

**Status:** Implementation in progress — Phase 3 platform assurance; Phase 2 sharing/build validation remains pending. Blueprint approved on 2026-10-21; validation workflow is intentionally manual-only.

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
| TSK-313 | Recover from item deletion failures and protect shared attachment references | IN PROGRESS — rollback/source tests added; manual run pending | A deletion failure attempts to restore the item and attachment; referenced attachments are not removed; fault-injection tests pass. |
| TSK-314 | Roll back save errors reported after storage writes | IN PROGRESS — item/attachment rollback and fault-injection test added; manual run pending | A failed save attempts to restore the previous saved-item map and attachment values even when a write may already have taken effect. |
| TSK-315 | Platform-aware backup storage messaging and single-flight restore UI | IN PROGRESS — source added; platform verification pending | Browser users see browser-profile/site-data warnings; Android users see app/device warnings; restore cannot be started twice and busy states are accessible. |
| TSK-316 | Match Library title wrapping to the approved responsive reference | IN PROGRESS — source adjusted; visual check pending | Long titles wrap to two lines on item cards without obscuring actions at narrow widths or large text scaling. |
| TSK-317 | Scale Library/Search result cards with system text settings | IN PROGRESS — shared layout helper and unit tests added; run pending | Card heights grow with system text scaling for two-line titles and metadata, remain bounded for invalid/extreme scales, and pass visual checks on web and Android. |
| TSK-318 | Expose saved-image and favorite state to assistive technology | IN PROGRESS — semantic labels and widget test authored; verification pending | Favorite markers and saved-image previews have meaningful semantics and pass TalkBack/web screen-reader review without duplicate announcements. |
| TSK-319 | Make the Library search teaser accessible as a navigation button | IN PROGRESS — semantics and widget test authored; verification pending | The search-shaped control is announced as a button with a clear name/hint, not as an editable text field, and responds to keyboard/pointer activation. |
| TSK-320 | Announce Search result-count changes to assistive technology | IN PROGRESS — live-region semantics and widget regression authored; run pending | Search result counts expose a single live status such as “1 result” or “0 results” as query/filter results change; screen-reader announcement behavior is manually verified. |

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

### Item deletion integrity — 2026-10-21

TSK-313 adds best-effort rollback if item deletion fails after attachment bytes may have been removed. Delete also checks raw stored item maps before removing an attachment so unreadable records referencing the same key protect its payload. Regression tests are authored but remain unrun; this does not guarantee atomicity under process death or persistent storage failure.

### Save post-write failure integrity — 2026-10-21

TSK-314 marks item and attachment writes as attempted before awaiting the storage operation. When a save fails, it attempts to restore the prior saved-item map or remove a new record, in addition to restoring attachment bytes. An in-process fault-injection test covers a failure after the item record write; Dart tests and platform storage behavior are still unverified.

## Phase 3 — platform assurance started (2026-10-21)

TSK-315 begins source-level platform hardening. Backup & Privacy communicates browser-local storage correctly on web, uses platform-specific data-loss messaging, and disables duplicate restore activation before the picker opens. This does not verify browser quota handling, keyboard/screen-reader behavior, or actual Android/web flows; those remain manual validation tasks. Phase 2 sharing and build checks are still pending.

### Phase 3 responsive Library card refinement — 2026-10-21

TSK-316 adjusts saved-item titles to wrap onto two lines before truncating, following the SCR-001 required long-title state. The responsive result still needs visual inspection at narrow widths and with enlarged text; no screenshot comparison has been marked passed.

### Phase 3 — text scale-aware result layout (2026-10-21)

TSK-317 introduces `savedItemCardExtentForTextScale` and applies it consistently to Library and Search result grids. At the default scale, cards use a 120 logical-pixel extent; larger text scales increase the extent within a fixed upper bound. Helper tests are authored but unrun. Actual large-text and responsive visual inspection remains pending.

### Phase 3 — accessible saved-item labels (2026-10-21)

TSK-318 adds title-based semantic labels to image thumbnails and detail previews, plus an explicit favorite-state label in Library/Search cards. A widget regression test is authored. Assistive-technology checks remain pending and should confirm that labels are useful without being announced twice.

### Phase 3 — accessible Library search control (2026-10-21)

TSK-319 changes the decorative search field on the Library page into a clearly named semantic navigation button while retaining the existing visual style. Its child TextField is excluded from semantics because it is not editable; the actual Search tab contains the editable query field. The widget regression test is authored but has not been executed.


### Phase 3 — semantic activation regression — 2026-10-21

- The Library search accessibility widget test now performs the control's semantic tap action and verifies that the Search navigation callback is invoked, rather than checking only that a tap action exists.
- Semantics handles are registered for teardown so a failed assertion does not leave test semantics enabled. Test source is authored; execution remains pending. Keyboard, pointer and assistive-technology behavior still require validation.


### Phase 3 — live Search result status — 2026-10-22

- Search result counts now expose a live-region semantic label (for example, “1 result” and “0 results”) so assistive technology can detect updates while a query changes. The visible result-count styling is retained, and its child text is excluded from semantics to avoid duplicate announcements.
- A widget regression covers the matching and no-match states and checks the live-region flag. It is authored but unrun; actual announcement timing and verbosity still need screen-reader review.
