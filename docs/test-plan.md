# StashHive — Test Plan

**Status:** Planned only; no application code exists yet. Commands below become concrete after Flutter project initialization and environment inspection.

## Test levels

1. **Unit tests:** validators, URL scheme handling, tag/collection rules, filtering, Unicode normalization/search, backup manifest/version parsing, archive path validation, conflict handling, and delete semantics.
2. **Repository/storage tests:** CRUD, migrations, file references, restart persistence, deletion cleanup, interrupted import, and corrupted metadata recovery.
3. **Integration tests:** manual save → app restart → search → detail → edit/delete; image/PDF import; Android share intent; export → clean library restore; web reload/export/restore.
4. **UI tests/manual accessibility:** loading/empty/error/success states; mobile/desktop layouts; keyboard focus and labels on web; large text; contrast; touch targets; reduced motion if used.
5. **Security/privacy checks:** no library content in application logs; malformed URLs; unsupported file/MIME; malicious backup path entries; oversized archive/file; invalid schema; no hidden network upload.
6. **Performance checks:** metadata query/search at 100, 1,000, and 10,000 items; import thumbnail cost; memory and package size before/after optional OCR.
7. **Platform verification:** actual Android device for sharing/file imports; at least one supported desktop browser for Flutter web; offline tests; browser origin/profile storage behavior.

## Initial test cases

| Test ID | Related requirements | Scenario | Expected result | Status |
|---|---|---|---|---|
| TC-001 | FR-001 | Save one link, image, note, PDF/document | Each item has correct type and available open/view action. | NOT STARTED |
| TC-002 | FR-002 | Add/edit item; enter malformed URL | Data persists; bad URL shows validation, no crash. | NOT STARTED |
| TC-003 | FR-003 | Cancel then confirm delete of item with attachment | Cancel keeps item; confirm removes record; attachment cleanup follows documented rule. | NOT STARTED |
| TC-004 | FR-004 | Filter by type/favorite and sort | Only matching items appear in expected order. | NOT STARTED |
| TC-005 | FR-005, NFR-005 | Search title, URL, note, tags, Urdu script, Roman Urdu, emoji | Expected item appears; Unicode text remains intact. | NOT STARTED |
| TC-006 | FR-006 | Save a URL and open it with network on/off | URL saves offline; external site needs network; no offline-site claim. | NOT STARTED |
| TC-007 | FR-007, FR-014 | Create/edit/search note offline | All operations work offline and survive restart. | NOT STARTED |
| TC-008 | FR-008 | Import image/PDF, cancel picker, choose unsupported/large file | Successful import is durable; cancel creates no item; invalid input shows recoverable error. | NOT STARTED |
| TC-009 | FR-009 | Share text/URL/image from supported Android apps | Confirmation/edit is shown; content saved once; unsupported share explained. | NOT STARTED |
| TC-010 | FR-010 | Rename/delete collection and edit tags | Item relationship updates correctly; deleting collection does not delete saved items. | NOT STARTED |
| TC-011 | FR-011, FR-017 | Open item detail for bookmark, image, and document | Each item's stored state and actions are accurately labeled. | NOT STARTED |
| TC-012 | FR-012 | Export library with several attachments | Versioned archive downloads/writes; manifest and item/attachment counts agree. | NOT STARTED |
| TC-013 | FR-013 | Restore valid, corrupted, path-traversal, and unknown-version archive | Valid archive imports; unsafe/invalid backup is rejected without corrupting current data. | NOT STARTED |
| TC-014 | FR-014 | Disable network after app launch | Local library, note editing and metadata search still work. | NOT STARTED |
| TC-015 | FR-015 | Reload web app in same browser profile, then test separate profile | Data persists locally in first profile; app does not imply cross-profile/device sync. | NOT STARTED |
| TC-016 | FR-016, NFR-008 | Run optional text extraction against a fixed local sample set | Report language-specific accuracy, extraction failure, model/package size, latency and memory. | NOT STARTED / POC |
| TC-017 | FR-017 | Save URL without preview/archival action | The item is represented as a bookmark, not offline content. | NOT STARTED |
| TC-018 | FR-018, NFR-002 | Inspect permissions, logs and network during core flows | Only justified permissions; no saved content in logs or outbound requests. | NOT STARTED |
| TC-019 | FR-019 | Import same item twice | If duplicate suggestion exists, user can decide; no silent loss. | NOT APPLICABLE until feature approved |

## Release quality gates

- Every Must requirement maps to a test or a documented manual verification.
- No critical data-loss, restore-corruption, or privacy regression remains open.
- All tests marked passed have actually been run on a named environment.
- At least one physical Android device is used for share and file import validation before promising those features.
- Web backup/restore and browser data-loss messaging are tested before web is described as durable storage.
- OCR stays optional/blocked until a repeatable POC report is approved.

## Commands

**Not yet available:** no Flutter `pubspec.yaml`, `lib/`, or test suite has been created because implementation is gated. After approval, verify the environment first, then record the exact successful commands for format, analyze, unit/widget/integration tests, Android release build, and web release build. Do not claim these checks pass before they have run.



## Phase 2 test additions — 2026-10-21

- test/share_intake_test.dart: URL, mixed text-and-URL, Unicode text, unsafe scheme and unsupported video.
- test/library_repository_test.dart: persistence across Hive reopen, attachment bytes after restore with ID collision, safe collection deletion, and missing-attachment rejection.
- tool/test_configure_android_share_intents.py: install supported filters, idempotency, and missing MainActivity error.

**Execution status:** tests are present but have not been run for Phase 2. The Flutter workflow is manual-only; no build or test result is claimed until the owner requests a validation checkpoint.
