# StashHive — Tailored AI Project Workflow

This file adapts the supplied AI Project Master Prompt to StashHive. `AGENTS.md` is the persistent entry point; this document records the phase gates.

## Working modes

- **PLAN / REVIEW:** read project docs, inspect changes, improve requirements, architecture, screens, assumptions, risks, and tests. No product implementation.
- **REVISE:** update affected planning documents; return to approval if behavior/platform/cost/privacy changes materially.
- **BUILD:** allowed only after explicit approval of `docs/BLUEPRINT_REVIEW.md`. Work in small, tested vertical slices, update traceability/docs, and report commands actually run.
- **TEST:** run checks, fix in-scope defects, and label anything not executed. Do not describe a docs-only repository as an app that builds.
- **RELEASE:** prepare readiness steps, policies, store assets, rollback and smoke tests. Public release/deployment needs separate explicit approval.
- **AUDIT:** report findings by severity and propose remediation; do not rewrite everything without approval.

## StashHive rules

1. This repository currently holds planning/docs/assets only. Explicit blueprint approval is required before product source code, dependencies, CI implementation, production infrastructure or deployment.
2. Treat Android as proposed primary platform and Flutter web as a companion with distinct storage/import constraints; do not promise iOS/desktop parity.
3. Core product must work without an account, cloud backend, paid AI API or remote OCR.
4. A link, webpage preview, attachment copy and offline webpage snapshot are different states.
5. Metadata search comes first; OCR/PDF text search is gated by an offline proof of concept, app size, language quality (Urdu/Nastaleeq risk), latency and offline execution.
6. Test backup/restore and local-data loss scenarios before release. Never commit user libraries/backups.
7. Keep user content out of logs and network calls. Treat imported files, URLs, extracted text and backup archives as untrusted input.
8. Avoid feature creep: accounts/sync, public sharing, social feed, browser extension, full-site mirroring, AI summaries and billing are outside the proposed MVP.
9. After approval, implement the seven primary screens from `docs/design/screen-reference.md` as the visual baseline. Add all documented empty/loading/error/permission/unsupported states and keep traceability up to date.
10. Do not claim a repository change, remote push, CI run, APK or deployment succeeded without verified evidence.

## Standard increment report after approval

- Task IDs and approved requirement IDs addressed.
- Files changed and user-visible behavior added.
- Commands executed and results, with platform/version notes.
- Tests not run and why.
- Known issues, risks, docs updated, next approved task.

## Approval language

Implementation may begin only after a clear instruction such as: **“I approve the StashHive blueprint. Start implementation.”** A screen-design request sets the requested visual direction but does not by itself resolve all open scope/architecture approval gates.
