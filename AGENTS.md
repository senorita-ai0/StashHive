# StashHive — AI Coding Instructions

## Current state

**Implementation approved; Phase 2/3 source work is in progress (2026-10-28).** Continue using small, testable vertical slices on `main`. Phase 2 Android/build validation remains pending; do not start Phase 4 release-readiness work until the owner-approved manual validation checkpoint supplies test/build/platform evidence. Never claim a build/test passed without its actual result. Public deployment, publishing, spending and paid services require separate approval.

## Read first

1. `README.md`
2. `docs/FEATURE_STATUS.md` — master feature table and new-chat handoff; update it after every meaningful change.
3. `docs/requirements.md`
4. `docs/architecture.md`
5. `docs/assumptions.md`
6. `docs/roadmap.md`
7. `docs/test-plan.md`
8. `docs/traceability-matrix.md`
9. `docs/security-privacy.md`
10. `docs/design/screen-reference.md`

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
- After every meaningful feature/source/test/validation increment, update `docs/FEATURE_STATUS.md` plus the relevant backlog, implementation-progress, roadmap, test-plan and traceability entries. It is the durable source of truth for resuming work in a new chat.
- Add tests with behavior changes. Run formatter/analyzer/tests/builds when available and report exact results.
- Do not commit secrets, personal library backups, signing files, generated build output or machine-specific config.
- Do not force-push or rewrite shared history. Commit changes directly to `main` as requested by the owner.
- Do not add a license without the owner's decision.

## Status labels

Use `DONE`, `IN PROGRESS`, `BLOCKED`, `NOT STARTED`, or `NOT APPLICABLE`. Label unverified platform behavior and residual risks clearly.
