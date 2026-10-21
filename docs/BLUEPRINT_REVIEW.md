# StashHive — Blueprint Review Summary

**Status: APPROVED FOR IMPLEMENTATION — Phase 1 in progress.**  
**Blueprint and UI reference prepared:** 2026-10-21. **Owner approved implementation:** 2026-10-21.

## What we propose to build

StashHive is a personal library that saves links/websites, screenshots/images, copied text/notes, PDFs and documents in one place and helps users find them later. It is a direct-to-user product; no service-provider marketplace or customer onboarding is required.

## Core MVP

- Manual saving/editing of links and notes.
- User-selected images/documents, distinguishing local attachment copies from external references.
- Unified library, content type filters, favorites, tags, collections, item details and metadata search.
- Android share intake for supported text/URLs/images/files if the proof of concept succeeds.
- Local/offline core behavior; portable export/restore and privacy/data-loss explanations.
- Proposed Flutter Android-first implementation and a Flutter web companion, but web ships only if persistence and backup tests pass.

## UI design reference

The complete seven-screen set is in [Premium Screen Reference](design/screen-reference.md), with editable SVGs under `design/screens/`: Library, Quick Save, Search Results, Item Details, Collections & Tags, Backup & Privacy, and Settings. The requested screen layouts are the visual baseline for eventual implementation. The build must also include documented empty/loading/error/permission/unsupported states. The static mockups are not app screenshots and do not prove functionality.

## Deliberately excluded from MVP

Cloud sync/accounts, social/public collections, AI summarization, paid API calls, full website mirroring/offline archive, browser extensions, automatic background scraping, notification/reminder system, ads/billing implementation, and iOS/desktop parity before technical validation.

## Recommended technology direction

Flutter + Dart; repository abstractions around platform-specific local storage/file handling. The metadata database remains provisional until Android/web proof-of-concept tests pass. No hosted backend, account service, paid AI API or remote OCR for core use. Metadata search first; OCR/PDF extraction waits until accuracy, offline execution and package-size costs are evidenced.

## Main risks

1. OCR may be too large or inaccurate for Urdu/Nastaleeq.
2. Android share/import and browser storage behave differently.
3. Local data can be lost through uninstall or cleared browser data; backup/restore is critical.
4. Name/store availability and product differentiation remain unverified.

## Approval gate

Review the scope, assumptions and [Premium Screen Reference](design/screen-reference.md). To authorize implementation, reply with a clear statement such as:

> **I approve the StashHive blueprint. Start implementation.**

This authorizes implementation, not public deployment or spending. The UI pack does not silently settle database/OCR choices or waive feasibility/security tests.
