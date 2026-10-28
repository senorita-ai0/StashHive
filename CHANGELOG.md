# Changelog

Changes worth noting are recorded here. StashHive is in source development and platform verification; no production release or post-Phase-2 validated build is claimed.

## Unreleased — 2026-10-28

- Bounded incoming Android share batches to 100 ordered entries with a visible warning for the remainder, capped waiting batches at eight, and preflighted share-event fingerprint inputs by raw field lengths before normalizing or serializing.
- Hardened text-share handling when provider message text is the effective content even if its path is empty; oversized aggregate payloads and whitespace-heavy metadata now bypass fingerprint hashing for normal validation.
- Serialized backup export with repository mutations and added source regression coverage for keeping exported item metadata and attachment bytes consistent during an attachment replacement.
- Guarded incoming share processing against HomeShell disposal and released active/queued batch completion futures during teardown; capped waiting share batches and kept file-URI fingerprinting resilient to conversion errors.
- Added Quick Save attachment-picker progress/accessibility and retry regressions, bounded share intake and its waiting queue, guarded unusual file-URI fingerprinting, serialized backup exports with mutations, protected the newest preference choice from stale failures and reset the visible text-size dropdown after a rollback, aligned design references with the StashHive name, and documented direct dependencies/licenses plus remaining transitive audit work.
- Regression source through TC-171 and TC-173–TC-177 is committed but unrun; TC-172 is a manual Android lifecycle scenario. No formatter, analyzer, tests, web build or Android build were run for this update. GitHub Actions remains manual-only.

## Initial blueprint package — 2026-10-21

- Expanded the initial starter notes into a project intake, requirements, architecture, assumptions, roadmap, test plan, traceability matrix, risks, and security/privacy plan.
- Added proposed UX flows, screen inventory, design tokens, and an editable, StashHive-branded vector concept board.
- Added StashHive-specific AI workflow and approval gate.
- At this initial blueprint milestone no Flutter source, runtime dependency set, backend or deployment was part of the starter package; source implementation and manual-only CI work are recorded in the subsequent sections.


### Phase 1 implementation increment — 2026-10-21

- Added initial Flutter source for the local library, add/edit forms, metadata search, item details, favorites, collections/tags, settings, file import and JSON backup/restore.
- Added the Hive CE repository and versioned backup codec with payload size and content validation.
- Added pure unit tests for the saved-item model and backup codec plus GitHub Actions checks.
- Verification pending: no Flutter/Dart SDK is installed in the authoring environment. Do not interpret source added as a passed build or tested platform behavior.


### Phase 1 implementation — 2026-10-21

- Added the first Flutter app shell, saved-item model, local Hive CE repository, add/edit form, local metadata search, item detail, favorites, collections/tags and settings.
- Added manual file selection, JSON backup/restore validation, model/codec unit tests and GitHub Actions format/analyze/test/web/Android build checks.
- Verification still pending: the first CI run found analyzer errors which have been corrected; tests and builds must finish before being marked passed.



### Phase 2 — Android share intake and manual-only CI — 2026-10-21

- Made GitHub Actions manual-only using workflow_dispatch.
- Added Android URL/text/image/document share intake that prefills Quick Save; saving remains an explicit user action.
- Added an idempotent Android manifest configurator and fixture tests.
- Added share-intake and repository persistence/restore regression tests; execution is pending a manual validation checkpoint.
- Fixed stale collection counts by making collection cards rebuild when the saved-item list changes.
- Expanded share parser regression tests for URLs embedded in prose and the documented shared-text size limit.
- Changed multi-item Android shares to a sequential draft-review flow with per-item progress; unsupported/unreadable items no longer stop the rest of the batch.
- Hardened backup validation against malformed record types, invalid collection lists and unreferenced attachments; preserved item-assigned collection names in encoded/restored backups.
- Added regression coverage for malformed mixed-backup rejection without partially importing records; execution is pending the manual validation checkpoint.
- Strengthened best-effort restore rollback after staged item/attachment writes, preserves prior collection preferences when rollback is possible, and added a fault-injection regression.
- Fixed save rollback so a failed attachment edit attempts to restore the previously stored bytes instead of deleting them; added a fault-injection regression.


### Phase 2 refinement — 2026-10-21

- Moved duplicate-share detection to event intake and limited it to a three-second window. This avoids delayed queued duplicate drafts while allowing deliberate re-shares afterward.
- Added a regression test for the de-duplication window.
- Recorded the previous Android APK failure: GeneratedPluginRegistrant could not resolve FilePickerPlugin. CI remains manual-only; no new build was run.


### Android toolchain remediation candidate — 2026-10-21

- Upgraded file_picker from 11.0.3 to 12.3.0 after inspecting the historical Android build logs and the upstream AGP 9 Kotlin-plugin-registration issue.
- Not build-verified yet; CI remains manual-only as requested.

### Restore compile-blocker correction — 2026-10-21

- Removed stale, undeclared restore bookkeeping references that would prevent Dart compilation. No tests or builds were run; CI remains manual-only.

### Collection mutation recovery — 2026-10-21

- Made collection rename/delete update affected item records before committing collection preferences, with best-effort rollback if a write fails.
- Added a fault-injection regression for a rename interrupted during item updates. Test/build execution remains pending.

### Item deletion recovery — 2026-10-21

- Added best-effort recovery for item/attachment delete failures.
- Retained attachment bytes when another raw saved-item record still references the same key.
- Added rollback and shared-attachment regression tests; execution remains pending.

### Save post-write recovery — 2026-10-21

- Extended save rollback to restore the previous item record when an error occurs after the record write may have taken effect, and to include attachment-stage failures in the recovery block.
- Added a fault-injection regression for an error after item write. Test/build execution remains pending.

### Phase 3 platform assurance — 2026-10-21

- Made Backup & Privacy describe browser-profile storage separately from device/app storage and present platform-specific data-loss warnings.
- Disabled repeated restore activation starting before the file picker opens; added an accessible label for the busy indicator.
- Platform verification and CI remain pending by owner request.

### Phase 3 responsive Library refinement — 2026-10-21

- Updated saved-item cards to show titles across up to two lines before truncation, aligning with the SCR-001 long-title requirement.
- Updated phase tracking to reflect that Phase 3 source work has started while Phase 2 build and Android device validation remain outstanding.
- No UI tests, screenshots or builds were run.

### Phase 3 accessibility layout increment — 2026-10-21

- Added a shared text-scale-aware height metric for Library and Search cards. Result cards grow with accessibility text size while staying within a defined maximum.
- Added pure unit test source for the card-height metric; tests and visual checks remain unrun.

### Layout metric type correction — 2026-10-21

- Explicitly converted the bounded text-scale adjustment to a double to match the layout helper's return type. Analysis and unit-test execution remain pending.

### Phase 3 accessibility semantics — 2026-10-21

- Added a meaningful semantic label for favorite markers and title-based labels for image thumbnails and detail previews.
- Added a widget-level regression test for favorite state; it has not been run. TalkBack and web screen-reader verification remain pending.

### Phase 3 accessibility refinement — 2026-10-21

- Exposed the Library search teaser as an accessible navigation button and removed the misleading editable-field semantics from its decorative child.
- Added a widget semantics regression test source. Test execution and manual keyboard/screen-reader verification remain pending.
