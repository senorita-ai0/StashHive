# StashHive — Technical Source Review

**Checked:** 2026-10-21. These are source references for design decisions, not proof that a package has been integrated or tested in this project.

## Flutter web

- Flutter — Web support: https://docs.flutter.dev/platform-integration/web
  - Describes the web target and the kinds of application-style experiences for which Flutter web is intended.
- Flutter — Web FAQ: https://docs.flutter.dev/platform-integration/web/faq
  - Documents web-specific differences, including that browser apps cannot use `dart:io` to access a native local filesystem. This supports an explicit platform-I/O adapter and means Android file behavior cannot be assumed on web.
- Flutter — Web setup: https://docs.flutter.dev/platform-integration/web/setup
  - Environment/setup reference for future verification after the actual SDK is inspected.

## Local storage candidates

- `hive_ce` package: https://pub.dev/packages/hive_ce
  - Package docs describe cross-platform storage, including browser boxes backed by IndexedDB and file-backed boxes on non-browser platforms. It is a candidate, not yet selected; search/filter, migration, export/restore and maintenance fit still require a proof of concept.
- `isar_community` changelog: https://pub.dev/packages/isar_community/changelog
  - Useful for assessing current maintenance/version compatibility. Do not assume web compatibility merely from historical Isar versions; verify the current package platform declarations and test.
- `sqflite` package: https://pub.dev/packages/sqflite
  - Package page describes Android/iOS/macOS support and points to experimental web support through a separate adapter. A web-first unified storage choice must account for this difference.

## Android sharing and file storage

- Android Developers — Sharing overview: https://developer.android.com/training/sharing
  - Covers Android Sharesheet/intent patterns for passing simple data across apps.
- Android Developers — Receive simple data from other apps: https://developer.android.com/develop/ui/compose/sharing/receive
  - Documents supported intent content types and the need to confirm/edit shared data. Exact integration approach must be validated for the selected Flutter/plugin setup.
- Android Developers — Data and file storage overview: https://developer.android.com/training/data-storage/
  - Outlines private app-specific storage, shared storage, preferences, and structured data storage choices.
- Android Developers — Access app-specific files: https://developer.android.com/training/data-storage/app-specific
  - Notes that app-specific files are removed on uninstall; supports explaining data-loss and backup behavior.
- Android Developers — Access documents with Storage Access Framework: https://developer.android.com/training/data-storage/shared/documents-files
  - Describes user-mediated document access without needing broad storage permission.

## Notes on interpretation

- Do not pin dependencies or claim compatibility based only on these pages. Inspect package version, changelog, licensing, current maintenance and platform matrix at implementation time.
- OCR/PDF extraction library and language support have not been selected. A technical test must use representative real-world sample images/PDFs and record the exact environment and results.
- Cloudflare Pages is only a possible static host for the web build. Before deployment, verify current deployment steps, build/output folder, caching, and free-tier limits against official Cloudflare documentation. Deployment is not part of this planning deliverable.

## Preliminary competitor scan (Google Play listings)

- Screenshot Organizer & Search (Bramhank): https://play.google.com/store/apps/details?id=com.bramhank.screenshotbookmark
- Screenshot Organizer & Search (Gamey Studio): https://play.google.com/store/apps/details?hl=en&id=com.gameystudio.screenshot.organizer
- GYST Screenshot+Link Organiser: https://play.google.com/store/apps/details?id=in.aaremm.gyst
- SnapFind Screenshot Finder: https://play.google.com/store/apps/details?id=com.alisherlabs.snapfind
- Screenshot Organizer: SnapSort: https://play.google.com/store/apps/details?hl=en_AU&id=com.saad.screenshotorganizer

See [`competitor-gap-hypotheses.md`](competitor-gap-hypotheses.md) for a summary and explicit caveats. This is not yet a comprehensive mixed-content competitor audit.


## Packages referenced by the first implementation slice (checked 2026-10-21)

- Hive CE metadata/storage candidate: https://pub.dev/packages/hive_ce (the package page lists native/browser support; validate actual CRUD, backup and platform builds).
- Hive CE Flutter integration: https://pub.dev/packages/hive_ce_flutter (used for Flutter initialization; pin/resolution/build must be checked in CI).
- File selection: https://pub.dev/packages/file_picker (manual image/document and JSON backup intake; real Android/web behavior still needs testing).
- Platform share flow: https://pub.dev/packages/share_plus (used to share backup exports and local files; user must choose a destination to retain an export).
- External links: https://pub.dev/packages/url_launcher (used for opening validated HTTP/HTTPS links in the external browser).

Dependency versions are declared in `pubspec.yaml`; a lockfile has not yet been generated from a successful `flutter pub get`. CI resolution is the first verification gate.
