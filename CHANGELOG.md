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
