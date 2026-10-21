# StashHive — Implementation Progress

**As of:** 2026-10-21  
**Phase:** 1 — Core local library (in progress)  
**Approval:** Owner approved implementation on 2026-10-21.  
**Verification note:** Flutter/Dart are not installed in the authoring environment. Source code and tests have been added, but local format/analyze/test/build results are not available yet. GitHub Actions has been configured to verify them.

## Implemented in source (verification pending)

- [x] Flutter app entry point and premium light theme, with a dark theme preference.
- [x] Four-tab shell: Library, Search, Collections, Settings.
- [x] Saved-item model for links, notes, images and documents.
- [x] Hive CE repository abstraction for local metadata, attachments and preferences.
- [x] Create/edit links and notes with URL validation, tags and collection assignment.
- [x] User-selected image/document import with a 15 MB per-file limit.
- [x] Local metadata search across titles, URLs, notes, tags and collections.
- [x] Item details, external link opening, image preview, document sharing, favorites and confirmed deletion.
- [x] Collections CRUD and derived tag browsing.
- [x] Version-1 JSON backup/restore with validation and merge semantics.
- [x] Unit tests for model/search/Unicode and backup-codec behavior.
- [x] GitHub Actions workflow for format, analysis, tests and web build; Android scaffolding is generated in CI if missing.

## Not yet verified

- [ ] Flutter dependency resolution, formatter, analyzer and tests.
- [ ] Android debug build / real-device run.
- [ ] Web release build and browser persistence.
- [ ] Real Android/web file-picker and share-sheet behavior.
- [ ] Large/malformed backup and rollback tests.
- [ ] Accessibility and visual comparison against the SVG screens.

## Known limitations in this increment

- OCR/PDF-text extraction is not implemented; search uses stored metadata and user-entered text only.
- PDFs/documents are passed to the platform share flow rather than rendered internally.
- Android share-receiver intents from other apps are not yet implemented; manual file selection is in source.
- Base64 JSON backups can be large; the codec enforces per-file and combined attachment limits.
- Platform folders are generated in CI; local developers should follow README bootstrap instructions if absent.
- No public deployment or release has occurred.

## Next tasks

1. Run CI and fix failures from actual logs.
2. Test on Android and Chrome; compare layout directly against the SVG screen files under docs/design/screens.
3. Add Android share-intent intake.
4. Add repository integration tests and broader backup/restore recovery tests.
5. Revisit OCR only after a separate offline feasibility test.
