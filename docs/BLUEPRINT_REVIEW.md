# StashHive — Blueprint and Implementation Status

**Blueprint:** Approved for implementation on 21 October 2026.  
**Current phase:** Phase 1 — Core local library.  
**Current verification:** CI is in progress/being corrected; no successful build should be assumed.

## Product

StashHive is a local-first personal library for links, images/screenshots, notes/snippets, PDFs and documents, searchable from one place.

## MVP direction

- Android primary; Flutter web companion only after browser persistence/backup validation.
- Manual saving/editing; typed library; local metadata search; tags, collections, favorites and item detail.
- User-selected image/document attachments.
- Versioned export/restore and clear privacy/data-loss warnings.
- No required account, server, paid AI API or cloud sync.

## Design baseline

Seven primary screen mockups live at `docs/design/screens/scr-001-library.svg` through `scr-007-settings.svg`; the behavior specification is [Premium Screen Reference](design/screen-reference.md). Implement visible hierarchy plus empty/loading/error/permission/unsupported states.

## Explicit MVP exclusions

Cloud sync/accounts, public sharing/social feeds, AI summaries/semantic search, automatic full website archiving, browser extension, ads/subscriptions, and promised OCR/Urdu-Nastaleeq OCR. iOS/desktop parity is deferred pending validation.

## Phase 1 source status

The first Flutter source increment contains the app shell, local repository/model, add/edit, metadata search, item detail, favorites/delete, collections/tags, settings, file selection and versioned JSON backup/restore. Unit tests and GitHub Actions checks are present. This is source implementation—not a claim that build or tests have passed.

## Remaining verification and scope gates

- Run analyzer, tests, web release build and Android debug build; fix issues based on CI logs.
- Validate on a real Android device and in a browser.
- Test backup handling, local-storage loss scenarios and import errors.
- Implement Android share-intent receiver after manual-save/search flow is verified.
- OCR dependencies remain unselected until a separate feasibility report.
- Owner approval authorizes implementation only—not deployment, purchases, store publishing, paid services or monetization.
