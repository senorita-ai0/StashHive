# Changelog

Changes worth noting are recorded here. This project is still in blueprint review; no app implementation has been released.

## Unreleased — 2026-10-21

- Expanded the initial starter notes into a project intake, requirements, architecture, assumptions, roadmap, test plan, traceability matrix, risks, and security/privacy plan.
- Added proposed UX flows, screen inventory, design tokens, and an editable, StashHive-branded vector concept board.
- Added StashHive-specific AI workflow and approval gate.
- No Flutter source code, runtime dependencies, CI workflow, backend, or deployment was added.


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


### Phase 2 refinement — 2026-10-21

- Moved duplicate-share detection to event intake and limited it to a three-second window. This avoids delayed queued duplicate drafts while allowing deliberate re-shares afterward.
- Added a regression test for the de-duplication window.
- Recorded the previous Android APK failure: GeneratedPluginRegistrant could not resolve FilePickerPlugin. CI remains manual-only; no new build was run.


### Android toolchain remediation candidate — 2026-10-21

- Upgraded file_picker from 11.0.3 to 12.3.0 after inspecting the historical Android build logs and the upstream AGP 9 Kotlin-plugin-registration issue.
- Not build-verified yet; CI remains manual-only as requested.
