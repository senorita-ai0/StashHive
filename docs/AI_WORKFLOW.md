# StashHive — Tailored AI Project Workflow

This file adapts the supplied AI Project Master Prompt to StashHive. `AGENTS.md` is the persistent entry point; this document records the phase gates.

## Working modes

- **PLAN / REVIEW:** read project docs, inspect any repository changes, improve requirements, architecture, screens, assumptions, risks, and tests. No product implementation.
- **REVISE:** update all affected planning documents and explain changes; return to approval if behavior/platform/cost/privacy changes materially.
- **BUILD:** allowed only after explicit approval of `docs/BLUEPRINT_REVIEW.md`. Work in small, tested vertical slices, update traceability/docs, and report commands actually run.
- **TEST:** run available checks, fix in-scope defects, and label anything not executed. Do not describe the docs-only repository as an app that builds.
- **RELEASE:** prepare readiness steps, policies, store assets, rollback and smoke tests. Public release/deployment needs separate explicit approval.
- **AUDIT:** report findings by severity and propose a remediation plan; do not rewrite everything without approval.

## StashHive rules

1. This repository currently holds planning/docs/assets only. The user must explicitly approve the blueprint before product source code, dependencies, CI implementation, production infrastructure or deployment is added.
2. Treat Android as the proposed primary platform and Flutter web as a companion with distinct storage/import constraints; do not silently promise iOS/desktop parity.
3. Core product must be usable without an account, cloud backend, paid AI API, or remote OCR.
4. A link, a webpage preview, an attachment copy, and an offline webpage snapshot are different states in the product and data model.
5. Metadata search comes first; OCR/PDF text search is gated by proof of concept, including app size, language quality (Urdu/Nastaleeq is a special risk), latency, and offline execution.
6. Test backups/restores and local-data loss scenarios before release. Never commit real user libraries/backups.
7. Keep user content out of logs and network calls. Treat imported files, URLs, extracted text, and backup archives as untrusted input.
8. Avoid feature creep: accounts/sync, public sharing, social feed, browser extension, full-site mirroring, AI summaries and billing are outside the proposed MVP.
9. Keep requirement IDs and test IDs stable. Update `docs/traceability-matrix.md` whenever behavior or test coverage changes.
10. Do not claim a GitHub repository, remote push, CI run, APK, or deployment exists unless a tool/command has actually confirmed it.

## Standard increment report after approval

- Task IDs and approved requirement IDs addressed.
- Files changed and user-visible behavior added.
- Commands executed and results, with platform/version notes.
- Tests not run and why.
- Known issues, risks, docs updated, next approved task.

## Approval language

Implementation may begin only after a clear instruction such as: **“I approve the StashHive blueprint. Start implementation.”** A casual “looks good” or “continue” before an explicit approval should be interpreted according to the latest clearly approved phase; if unclear, remain in planning.
