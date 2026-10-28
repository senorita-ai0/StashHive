# Contributing to StashHive

Implementation has been approved and source development is in progress directly on `main`. Phase 2 Android/share validation and Phase 3 platform assurance remain open; the app is not release-ready until the owner-requested manual validation checkpoint has evidence.

Read `AGENTS.md` first, then the requirements, architecture, assumptions, roadmap, test plan, traceability matrix, security/privacy plan and seven-screen reference.

## Development workflow

1. Read the requirements, architecture, assumptions, roadmap, test plan, and design docs.
2. Work on one roadmap task/vertical slice at a time.
3. Work directly on `main` as requested by the owner; do not create a branch/PR, force-push, rewrite shared history, or discard another person's work.
4. Add/update tests for changed requirements and record the exact commands and environment used.
5. Update `docs/traceability-matrix.md`, roadmap status, and documentation when behavior changes.
6. Do not commit secrets, app signing files, `.env` secrets, local library backups, user content, or generated build directories.
7. Keep GitHub Actions manual-only. Do not run formatter, analysis, tests or builds until the owner requests the validation checkpoint; never claim a check passed unless it was actually executed.

## License and contributions

The project owner has not selected a repository license or public contribution policy yet. Do not assume contributions are accepted for public redistribution until this is decided.
