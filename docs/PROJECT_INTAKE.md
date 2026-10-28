# StashHive — Project Intake Summary

**Status:** Blueprint approved for implementation on 21 October 2026; Phase 2/3 source development continues while platform verification remains pending.  
**Prepared:** 2026-10-21

## Problem statement

People save useful digital items across different apps and locations—screenshots, website links, articles, social/video links, copied text, notes, PDFs, and documents. Later they forget which app/source contained the item or cannot search inside the content. StashHive aims to make saving, organizing, and retrieving those items feel like one personal library.

## Intended users

- People who regularly save screenshots, links, posts, and snippets.
- Students collecting study resources and PDFs.
- Professionals and creators collecting references and ideas.
- Users who prefer not to create another online account or upload a personal archive.

## Intended outcome

A polished, reliable Android-first app with a companion web experience. A user can save diverse content, search it in one place, and recover their library through export/restore without needing a hosted service.

## Confirmed direction

- Product name: **StashHive** (current user-facing brand; domain/trademark clearance remains separate).
- Broad purpose: more than screenshot management; links, websites, notes, snippets, PDFs, and documents are in scope for product planning.
- Product model: direct-to-user app; no external service providers or customer marketplace are required.
- Cost constraint: prefer free tools and local processing; avoid recurring backend and paid-API costs for the core product.
- Framework preference: Flutter, based on the user's established app workflow.
- Workflow: keep requirements, architecture, traceability and test plans aligned; source implementation is approved, while public publishing, spending and paid services require separate approval.

## Identity compatibility

StashHive is the current visible product name. Preserve the existing `stashhive` Dart package and Hive box identifiers and the version-1 JSON backup marker (`StashHive`). Earlier StashTrail-branded backup files remain a compatibility concern; do not change storage/schema identifiers without a separate migration plan.

## Approved defaults (platform validation still pending)

- Android is the primary MVP target; Flutter web is a companion target with browser-specific limitations.
- App language is English initially; saved text should handle Unicode, including Urdu and Roman Urdu. UI localization and Urdu OCR require validation before being promised.
- No account, cloud sync, public sharing, social feed, or AI API in the MVP.
- User controls backups; local browser storage can be lost if site data is cleared, and app-private files can be removed on uninstall.
- First search version covers title, URL, notes, tags, and manually entered text. OCR/PDF extraction is a staged capability subject to proof-of-concept results.
- Monetization comes after core value and retention validation; investigate ads and optional one-time premium later without degrading privacy or core usability.

## Initial MVP scope

1. One library for links, images/screenshots, text/notes, and documents.
2. Manual add/edit/delete and item details.
3. Unified browse/search/filter and saved metadata.
4. Collections, tags, favorites, sorting, and a clear distinction between link and file.
5. Android sharing/import proof of concept for URLs, text, images, and user-selected files.
6. Versioned export/restore, interruption handling, and clear privacy/data-loss explanations.
7. Responsive web companion with browser-local storage, if the storage/backup proof of concept succeeds.

## Not in the first release

Cloud sync/accounts; social/shared collections; automatic full-site mirroring; AI summaries/semantic search; a browser extension; automatic discovery of everything in the phone gallery; paid API dependencies; automatic web scraping; subscription/payment infrastructure; iOS/desktop parity before validation.

## Main risks

- Search inside images/documents (OCR) can increase app size and may not support Urdu/Nastaleeq accurately.
- Android share/import support and the web browser have different constraints.
- Local-only data can be lost without backup; web browser data may be cleared by the user/browser.
- A diverse personal library can become cluttered without fast capture and retrieval.
- A save-and-search category has competitors; a focused differentiator and organic distribution need validation.

## Success definition for the prototype

Testers can save one link, one image, one note, and one PDF/document; close/reopen the app; search and find prior entries; understand the difference between a bookmark and an offline copy; and successfully export/restore test data. Performance and app-size targets should be set after measuring the proof of concept, not invented in advance.

## Open decisions

See `docs/assumptions.md` and `docs/BLUEPRINT_REVIEW.md`. The initial scope/platform split was approved on 21 October 2026. Continue the approved Phase 2/3 source work; close the remaining Android/browser validation gates before release-readiness work.
