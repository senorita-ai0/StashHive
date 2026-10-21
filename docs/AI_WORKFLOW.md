# StashHive — AI Project Workflow

Implementation was explicitly approved by the owner on 21 October 2026. BUILD mode is active for Phase 1; don't ask for the same approval again.

## Modes

- **PLAN / REVIEW:** understand existing code/spec, identify risks, update design, architecture, tests or backlog.
- **REVISE:** incorporate feedback and update related docs/requirements.
- **BUILD:** implement the next approved vertical slice, preserving working behavior and the seven-screen references.
- **TEST:** run real format/analyze/unit/integration/build checks; fix failures based on actual output.
- **RELEASE:** prepare readiness, rollback and store/deploy documentation. Publishing/deployment requires separate explicit approval.
- **AUDIT:** report findings by severity before performing broad rewrites.

## StashHive implementation rules

1. Follow `docs/design/screen-reference.md` as the UI visual baseline; its mockups are static specs, not running app screenshots.
2. First slice uses Hive CE behind `LibraryRepository`, but do not lock the persistence choice until CI and Android/web tests pass.
3. No core cloud account/sync/server or paid AI service.
4. Keep separate semantics for bookmark, preview metadata, locally copied file and true offline snapshot.
5. Metadata search first; OCR remains gated on accuracy, app-size, language, platform and offline proof-of-concept evidence.
6. Backup/restore and data-loss messaging are core trust features; never commit real personal libraries.
7. Treat URLs, files, extracted text, and backup archives as untrusted input.
8. No unnecessary permissions, content logging or telemetry.
9. Keep `docs/traceability-matrix.md` and `docs/implementation-progress.md` up to date as requirements are implemented.
10. Do not claim any run, commit, push, app package or deployment succeeded without confirmation from a command/tool result.

## Verification notes

The current GitHub Actions run is the first executable verification because this author's environment does not have Flutter/Dart installed. Format, analyzer, tests, web build and Android debug build must all report their actual outcome.
