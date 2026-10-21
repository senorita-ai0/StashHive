# StashHive — Implementation Progress

**As of:** 2026-10-21  
**Phase:** 1 — Core local library  
**Owner approval:** Received 2026-10-21  
**Verification:** First CI compile/analyze/test run is underway. The previous analyzer run caught and fixed code/API errors; the latest analyzer run had only style-level info findings, so CI now uses `flutter analyze --no-fatal-infos`. A successful final run is not confirmed yet.

## Source implemented (verification pending)

- Flutter app shell and premium light theme, plus dark appearance preference.
- Four main tabs: Library, Search, Collections, Settings.
- Saved-item model for links, notes, images and documents.
- Hive CE repository abstraction for items, attachment bytes, collection names and preferences.
- Save/edit link and note forms with HTTP/HTTPS validation, tags and collection assignment.
- User-selected image/document import with a 15 MB per-file cap.
- Case-insensitive local metadata search across title, URL, note/text, tags and collection name; Unicode content is retained.
- Item details, external link opening, in-app image preview, platform file share, favorite and confirmed delete.
- Collection create/rename/delete; deleting a collection unassigns its items.
- Version 1 JSON backup/restore, with schema/version/ID/URL/size/attachment checks, merge semantics and collision ID remapping.
- Tests for model serialization/search/Unicode/copy behavior and backup codec.
- CI workflow for package resolution, Dart format, analyzer, tests, Flutter web release build and Android debug APK build.

## CI status

- First run: dependencies resolved and formatter passed; analyzer failed on the callback signature and old `FilePicker.platform` API. Tests/builds skipped.
- Second run: those code issues are fixed. It reported style-level info lints only; default Flutter analyzer treats infos as fatal, so the workflow and run instructions now use `flutter analyze --no-fatal-infos`.
- Current run after the analyzer flag adjustment: not yet confirmed complete at the time this document was prepared.

## Not implemented / not verified

- No OCR or PDF text extraction. Search is metadata/user-entered text only.
- No Android share receiver from other apps yet; manual file selection is in source.
- PDF/document contents are shared to a platform app instead of rendered internally.
- Real Android device, browser persistence, storage quotas and file/share behavior require testing.
- Accessibility pass and pixel comparison against SVG mockups remain.
- Backup rollback under interrupted storage failures requires further tests.
- No public deployment or release.

## Next tasks

1. Finish CI: analyzer, tests, web build, Android debug build.
2. Fix all real errors from new CI logs; don't hide compiler errors.
3. Test save/edit/search/delete and backup/restore in Chrome and on a real Android device.
4. Add Android share receiver and repository integration tests.
5. Evaluate OCR separately; no OCR promise before proof of concept.
