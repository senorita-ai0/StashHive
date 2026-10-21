# StashHive — Test Plan

**Status:** Implementation and test sources exist. Phase 2 tests have not yet run; the GitHub Actions workflow is manual-only by owner request.

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
| TC-009 | FR-009 | Share text/URL/image/document from supported Android apps, including a multi-item batch | One editable draft is shown at a time; save/cancel advances to the next entry; unsupported or unreadable entries are skipped with feedback; no silent saves. | NOT STARTED — manual Android test |
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
| TC-020 | FR-010, FR-011 | Keep Collections open while saving, editing, moving and deleting saved items | Collection counts update immediately and remain consistent with item assignments. | NOT STARTED — manual UI regression |

## Release quality gates

- Every Must requirement maps to a test or a documented manual verification.
- No critical data-loss, restore-corruption, or privacy regression remains open.
- All tests marked passed have actually been run on a named environment.
- At least one physical Android device is used for share and file import validation before promising those features.
- Web backup/restore and browser data-loss messaging are tested before web is described as durable storage.
- OCR stays optional/blocked until a repeatable POC report is approved.

## Commands

**Manual validation only:** the full Flutter workflow does not run on pushes. At the agreed checkpoint, run formatting, analysis, Python configurator tests, Dart unit tests, web release build and Android debug build. The last pre-Phase-2 Android build failed because the generated runner could not resolve FilePickerPlugin; resolve that before marking Android build verification complete.



## Phase 2 test additions — 2026-10-21

- test/share_intake_test.dart: URL, mixed text-and-URL, URL punctuation/path/query handling, Unicode text, unsafe scheme, text-size limit and unsupported video.
- test/library_repository_test.dart: persistence across Hive reopen, attachment bytes after restore with ID collision, safe collection deletion, and missing-attachment rejection.
- tool/test_configure_android_share_intents.py: install supported filters, idempotency, and missing MainActivity error.

**Execution status:** tests are present but have not been run for Phase 2. The Flutter workflow is manual-only; no build or test result is claimed until the owner requests a validation checkpoint.


## Historical Android build failure to verify at release checkpoint

The previous Android debug build failed when the generated plugin registrant could not resolve FilePickerPlugin. StashHive has upgraded file_picker to 12.3.0 based on the upstream fix reported for 12.x. Do not mark this as fixed until the owner asks for a manual validation run and the Android APK build completes successfully.


### Multi-item share sequence regression — 2026-10-21

- test/share_intake_test.dart covers preservation of draft content/metadata when batch-position information is attached.
- Manual Android checks still need to cover: all supported items in order, cancel then continue, an unsupported entry between supported items, a file-read failure between valid entries, and a cold-start shared batch. These require the owner's final validation checkpoint/device and must not be represented as passed before then.


### Backup validation and failed-import safety — 2026-10-21

- test/backup_codec_test.dart now covers wrong saved-item field types, attachment payloads with no item reference, and preservation of a collection assigned on an item but omitted from older top-level collection lists.
- test/library_repository_test.dart covers a backup with one valid record followed by a malformed record; the restore must fail before importing any record or collection.
- Execution remains pending. The restore is decoded and validated before writes, but simulated Hive write interruptions and rollback of real storage failures still need separate testing.


### Restore write-phase rollback regression — 2026-10-21

- test/library_repository_test.dart injects an exception after the restored item and attachment have been written but before collection preferences commit.
- Expected: the incoming item and its attachment bytes are removed; the previously saved item and collection assignment remain unchanged; the original error remains visible to the caller.
- This regression is authored but unrun. It tests the rollback control flow in-process; it does not simulate process death or a filesystem failure during Hive compaction/flush.


### Attachment edit rollback regression — 2026-10-21

- test/library_repository_test.dart injects a failure after replacement attachment bytes are written but before the saved-item map commits.
- Expected: the original item title and attachment bytes remain intact, and the original save error is returned. The test hook must be reset even if the assertion fails.
- Source/test added, execution pending. Real disk-full, process-death and filesystem failure behavior is still unverified.

### Restore compile-blocker correction — 2026-10-21

- Removed redundant references to undeclared restore bookkeeping variables; rollback continues to clean up every staged item/attachment entry.
- Dart analyzer, unit tests, web build and Android APK build remain pending the owner's manual validation checkpoint.
