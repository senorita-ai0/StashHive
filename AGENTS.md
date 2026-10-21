# StashHive — AI Coding Instructions

## Current state

**Implementation approved; Phase 1 is in progress (2026-10-21).** Continue using small, testable vertical slices on `main`. Never claim a build/test passed without its actual result. Public deployment, publishing, spending and paid services require separate approval.

## Read first

1. `README.md`
2. `docs/requirements.md`
3. `docs/architecture.md`
4. `docs/assumptions.md`
5. `docs/roadmap.md`
6. `docs/test-plan.md`
7. `docs/traceability-matrix.md`
8. `docs/security-privacy.md`
9. `docs/design/screen-reference.md`

## Product constraints

- Personal library for links, text, images/screenshots, PDFs and documents.
- Android is primary; Flutter web is a companion with a separate local library. Do not imply automatic sync.
- No account, cloud backend, paid AI API, public feed, browser extension or billing in the MVP.
- Bookmark, fetched metadata preview, copied attachment and offline website snapshot are separate states.
- Search currently covers metadata and user-entered text. OCR/PDF extraction (especially Urdu/Nastaleeq) is not implemented or promised.
- Do not log saved URLs, notes, filenames, or extracted text; avoid unrelated permissions.
- Use the seven screen mockups in `docs/design/screen-reference.md` as the visual baseline; implement their specified loading/empty/error/permission states too.
- Local storage uses Hive CE behind `LibraryRepository`; compatibility remains subject to tests and platform testing.
- Android share intake uses `receive_sharing_intent` and an idempotent manifest configurator. Incoming content must open Quick Save for user review; never save external content automatically.
- CI is manual-only (`workflow_dispatch`). Do not trigger a build unless the owner asks for a build checkpoint.
- Current import cap is 15 MB per attachment; backup v1 caps attachments at 100 MB combined.

## Engineering requirements

- Inspect the current tree and tests before edits; preserve unrelated work.
- Keep model, storage, UI, backup and platform I/O boundaries explicit.
- Keep requirement IDs, task IDs, tests and docs aligned.
- Add tests with behavior changes. Run formatter/analyzer/tests/builds when available and report exact results.
- Do not commit secrets, personal library backups, signing files, generated build output or machine-specific config.
- Do not force-push or rewrite shared history. Commit changes directly to `main` as requested by the owner.
- Do not add a license without the owner's decision.

## Status labels

Use `DONE`, `IN PROGRESS`, `BLOCKED`, `NOT STARTED`, or `NOT APPLICABLE`. Label unverified platform behavior and residual risks clearly.
