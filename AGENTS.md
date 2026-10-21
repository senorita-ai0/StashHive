# StashHive — AI Coding Instructions

## Current gate

**Status: BLUEPRINT REVIEW / IMPLEMENTATION NOT APPROVED.** This repository currently contains planning and design artifacts only. Do not create or modify product source code, add runtime packages, initialize the Flutter application, configure production infrastructure, or deploy until the user explicitly approves `docs/BLUEPRINT_REVIEW.md`.

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
10. `docs/design/README.md`

## Product constraints

- StashHive is a personal save-and-find library for links/websites, screenshots/images, text snippets/notes, PDFs, and documents.
- Android is the proposed primary platform; Flutter web is a proposed companion. iOS/desktop support is not promised until validated.
- Core use must not require an account, hosted backend, paid AI API, or ongoing infrastructure spend.
- Local-first does not mean browser storage is indestructible, app-private files survive uninstall, or two devices sync automatically. Backup and restore are core trust features.
- A saved URL, fetched metadata preview, copied local file and full offline page are different states. Never represent a URL as an offline page unless its content is actually available offline.
- OCR/PDF text extraction, particularly Urdu/Nastaleeq, is a risk to validate—not a promise.
- Do not log users' saved content. Avoid unrelated permissions and telemetry.
- No auth/cloud sync/social feed/browser extension/payment system is part of the proposed MVP.
- The first slice uses Hive CE behind the repository interface; database/package compatibility remains subject to CI and platform verification.
- The first slice enforces a 15 MB imported attachment limit and a 100 MB combined attachment limit for version-1 JSON backups.
- After blueprint approval, use the seven screen references in `docs/design/screen-reference.md` as the UI baseline. Preserve IDs, visible hierarchy, navigation, interactions and all required states.

## Engineering rules after approval

- Inspect repository status and current files before edits; never discard unrelated work.
- Keep requirements, implementation tasks, screen specs, tests, and documentation traceable by stable IDs.
- Use small changes; add tests with behavior; run and report commands actually executed.
- Keep platform-specific storage/import behavior behind interfaces. Do not assume Flutter mobile and web have identical filesystem/share APIs.
- Do not commit secrets, exported personal libraries, sample private data, signing files, build output, or machine-local configuration.
- Do not make remote commits, push, open a PR, publish a release, enable paid services, or deploy without verified access and required authorization.
- Do not add a license without an owner decision.

## Status reporting

Use `DONE`, `IN PROGRESS`, `BLOCKED`, `NOT STARTED`, or `NOT APPLICABLE`. State what was actually tested and what remains a hypothesis. Do not claim the app builds before an app project exists and build checks pass.
