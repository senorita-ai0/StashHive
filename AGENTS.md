# StashHive — AI Coding Instructions

## Current gate

**Status: BLUEPRINT REVIEW / IMPLEMENTATION NOT APPROVED.** The repository currently contains planning and design artifacts only. Do not create or modify product source code, add runtime packages, initialize the Flutter application, configure production infrastructure, or deploy until the user explicitly approves `docs/BLUEPRINT_REVIEW.md`.

## Read first

1. `README.md`
2. `docs/requirements.md`
3. `docs/architecture.md`
4. `docs/assumptions.md`
5. `docs/roadmap.md`
6. `docs/test-plan.md`
7. `docs/traceability-matrix.md`
8. `docs/security-privacy.md`
9. `docs/design/README.md`

## Product constraints

- StashHive is a personal save-and-find library for links/websites, screenshots/images, text snippets/notes, PDFs, and documents.
- Android is the proposed primary platform; Flutter web is a proposed companion. iOS/desktop support is not promised until validated.
- Core use must not require an account, hosted backend, paid AI API, or ongoing infrastructure spend.
- Local-first means content is stored on the user's device/browser by default. It does **not** mean browser storage is indestructible, app-private files survive uninstall, or two devices sync automatically. Backup and restore are core trust features.
- A saved URL/bookmark, fetched page metadata, and a fully captured offline page are three different states. Never represent a URL as an offline page unless its content is actually available offline.
- OCR/PDF text extraction, particularly Urdu/Nastaleeq, is a risk to validate—not a promise. Do not add large models/dependencies before the proof of concept and approval.
- Do not log users' saved content, URLs, notes, document names, or extracted text. Avoid unrelated permissions and telemetry.
- No auth/cloud sync/social feed/browser extension/payment system is part of the proposed MVP.

## Engineering rules after approval

- Inspect repository status and current files before edits; never discard unrelated work.
- Keep requirements, implementation tasks, screen specs, tests, and documentation traceable by stable IDs.
- Use small changes; add tests with behavior; run and report commands actually executed.
- Keep platform-specific storage and import behavior behind interfaces. Do not assume Flutter mobile and web have identical filesystem/share APIs.
- Do not commit secrets, exported personal libraries, sample private data, signing files, build output, or machine-local configuration.
- Do not make remote commits, push, open a PR, publish a release, enable paid services, or deploy without verified access and the required authorization.
- Do not add a license without an owner decision.

## Status reporting

Use `DONE`, `IN PROGRESS`, `BLOCKED`, `NOT STARTED`, or `NOT APPLICABLE`. State what was actually tested and what remains a hypothesis. Do not claim the app builds before an app project exists and real build checks pass.
