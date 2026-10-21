# StashHive — Blueprint Review Summary

**Status: WAITING FOR USER APPROVAL — product implementation is paused.**  
**Prepared:** 2026-10-21

## What we propose to build

StashHive is a personal library that saves links/websites, screenshots/images, copied text/notes, PDFs and documents in one place and helps the user find them later. It is a direct-to-user product; no service-provider marketplace or customer onboarding process is needed.

## Core MVP

- Manual saving and editing of links and notes.
- User-selected images/documents, with clear distinction between local attachment copy and external reference.
- Unified library, content type filters, favorites, tags, collections, item details and metadata search.
- Android share intake for supported text/URLs/images/files if the proof of concept succeeds.
- Local/offline core behavior; portable export/restore and privacy/data-loss explanations.
- Proposed Flutter Android-first implementation and a Flutter web companion, but web ships only if persistence and backup tests pass.

## Deliberately excluded from MVP

Cloud sync/accounts, social/public collections, AI summarization, paid API calls, full website mirroring/offline archive, browser extensions, automatic background scraping, notification/reminder system, ads/billing implementation, and iOS/desktop parity before technical validation.

## Important design references

See `docs/design/screens/stashhive-mobile-core-flows.svg`. It contains concept versions of Library, Search Results, and Item Detail. The vector board is a design direction, not an approved finished UI or a working app screenshot. Design tokens and screen inventory are drafts.

## Recommended technology direction

- Flutter + Dart, reusing one domain/UI codebase where suitable.
- Repository abstraction that separates domain logic from local storage and platform file handling.
- `hive_ce` is the leading candidate for cross-platform metadata persistence because its docs describe IndexedDB storage in browsers and file-backed boxes elsewhere; **do not lock it before a proof of concept**.
- Android private app storage and web browser-origin storage use different adapters and have different data-loss risks.
- No hosted backend, account service, paid AI API or remote OCR for core use.
- Metadata search first; OCR/PDF text extraction is optional and requires evidence for accuracy, offline use, package size, and language support.

## Costs and external dependencies

- Core development can target zero recurring infrastructure cost by keeping data on-device and using free development/static-hosting tools.
- This is not a guarantee of zero total cost: store publication, domain/trademark work, ad networks, app signing/distribution, or future sync may have separate requirements/costs.
- Ads or premium purchases are deferred until user testing demonstrates value and retention. Monetization choices require a later approval.

## Main risks

1. OCR might be too large or inaccurate for Urdu/Nastaleeq.
2. Android share/import and browser storage behave differently.
3. Users can lose local data through uninstall or cleared browser site data; backup/restore is critical.
4. Store/name conflicts and organic discovery remain unverified.
5. Search/organizing apps are competitive; differentiation needs user validation.

## Open assumptions requiring attention

See `docs/assumptions.md`; material ones are: Android-first + companion web, no automatic sync, staged OCR, backup/restore as release requirement, and English UI first with Unicode-safe user content.

## Approval gate

Please review the scope, screen concept and assumptions. To authorize implementation, reply with a clear statement such as:

> **I approve the StashHive blueprint. Start implementation.**

Or request revisions. Approval here authorizes the next implementation phase only; it does not authorize public deployment, paid services, purchases, or publishing. No app source code, runtime dependencies, CI implementation, or production infrastructure has been created in this deliverable.
