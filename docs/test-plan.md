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

### Collection mutation recovery — 2026-10-21

- A fault-injection regression checks that a failed collection rename does not leave only some saved items assigned to the new collection.
- Rename/delete rollback is best-effort; storage interruption behavior requires the owner's manual validation checkpoint and platform-level testing.

### Delete rollback and attachment-reference tests — 2026-10-21

- A fault-injection test simulates an error after an attachment has been deleted and expects both its item record and original bytes to be restored.
- A shared-reference test ensures deleting one item does not remove bytes still referenced by another item.
- These tests are authored, not executed. Rollback remains best-effort if the storage layer rejects the recovery writes too.

### Save post-write failure regression — 2026-10-21

- A fault-injection test throws after the saved-item record write and verifies that both the prior item fields and prior attachment bytes are restored.
- Storage rollback remains best-effort if the underlying storage also rejects recovery writes. This regression is authored but not executed.

### Phase 3 platform-specific storage copy and restore guard — 2026-10-21

- Verify the Backup & Privacy screen says “Stored in this browser” on web and explains browser-profile/site-data boundaries.
- Verify Android copy refers to app/device storage and that clearing app data/uninstalling may remove the local library.
- Rapidly activate restore and confirm only one file picker/restore flow can be active; verify cancel resets the button and screen-reader announcements describe the busy action.
- Run these checks on web and Android at the owner's manual validation checkpoint. No automated execution is claimed.

### TC-021 — Library card title wrapping and text scaling

- Seed the library with short, medium and very long item titles.
- At narrow mobile widths, confirm a title can wrap to a second line without overlapping favorite or overflow actions.
- Increase system text scaling and verify actions remain reachable and cards scroll without horizontal overflow.
- Compare with SCR-001; status remains NOT STARTED until a real UI run is inspected.

### TC-022 — Text-scaling-aware result cards

- Verify the shared card extent returns a 120 logical-pixel baseline at default text scale and increases at larger scale factors.
- Verify extreme or invalid scale values are bounded to prevent unbounded card growth.
- On web and Android, manually inspect Library and Search at 100%, 150% and 200% text scale; long titles should remain readable and action controls must not overlap.
- Automated unit test source is added but execution remains pending the manual validation checkpoint.

### TC-023 — Saved-item semantics

- With a favorite item in the Library, inspect the semantics tree and confirm its favorite state is announced as “Saved as a favorite.”
- Confirm the stored image thumbnail and item-detail preview expose a useful title-based image label.
- Use TalkBack on Android and a screen reader on web to ensure the added labels are understandable and not redundantly repeated. Manual assistive-technology checks remain NOT STARTED.

### TC-024 — Library search navigation semantics

- Confirm the search-shaped Library control is announced as a button named “Search your library,” with the hint that it opens Search.
- Confirm assistive technology does not announce a text-editing field on the Library tab; the actual Search tab field remains editable.
- Confirm keyboard activation and pointer activation both open Search. Widget test source is added but not run, and manual screen-reader checks remain pending.


### TC-025 — Semantic activation of Library search

- Confirm the Library search teaser is named “Search your library,” exposes a tap action, and semantic activation invokes the Search navigation callback.
- Verify the real control with keyboard and pointer on web/desktop and TalkBack/screen reader on supported platforms. The widget regression is authored but not run; platform checks remain NOT STARTED.


### TC-026 — Search result status announcements

- Seed a saved item, search for a matching term, then change the query to a no-match term.
- Confirm the result count exposes “1 result” and then “0 results” as a live semantic status without duplicate text announcements.
- Widget regression source is authored but not run. Verify announcement clarity and avoid excessive chatter during rapid typing using TalkBack and a supported web screen reader; status remains NOT STARTED.


### TC-027 — Saved-item action menu context

- Seed and render a saved-item card, confirm its action-menu tooltip identifies that item's title, verify “View details” calls the details callback, then verify “Add to favorites” changes the saved item's favorite state.
- Widget regression is authored but not run. Confirm tooltip verbosity and menu operation using keyboard/pointer and screen readers on web and Android; status remains NOT STARTED.


### TC-028 — Saved-item action command behavior

- Use the saved-item action menu to open details and mark an item as a favorite.
- Verify the detail callback fires and the repository state changes for the expected item. Test source is authored but unrun; manual keyboard/screen-reader testing remains NOT STARTED.


### TC-029 — Share-event deduplication batch and cache boundaries

- Submit a two-item batch, then the same items in reverse order; both distinct ordered batches should be accepted.
- Submit the reversed batch again inside the deduplication window; it should be rejected as a duplicate.
- With a one-entry cache, submit a different batch and verify the oldest fingerprint is evicted and can be accepted again.
- Widget/unit test source is authored but unrun. Real Android initial-intent and stream delivery checks remain NOT STARTED.


### TC-030 — Incoming-share batch progress bounds

- Clone a share draft with a position below one and confirm it normalizes to position one.
- Clone a draft with a position greater than the total and confirm the position clamps to the total.
- Supply an invalid total and confirm both normalized total and position are one.
- Unit test source is authored but unrun; end-to-end Android batch presentation remains NOT STARTED.


### TC-031 — Collision-safe share-event fingerprinting

- Submit two batches with distinct contents that could alias under a delimiter-based fingerprint (for example, paths `a|b` and `c` versus `a` and `b|c`); both should be accepted as distinct events.
- Re-submit an identical batch inside the deduplication window and confirm it is rejected.
- Unit regression source is authored but unrun. Android initial-intent/stream integration remains NOT STARTED.


### TC-032 — Nonlinear text-scale layout sizing

- With the default text scale, verify Library and Search cards use the baseline extent.
- With enlarged accessibility text (including a platform nonlinear text scaler), verify the card extent derives from a representative body font size rather than a 1-pixel sample, and remains bounded at extreme values.
- Unit regression source is authored but unrun. Visual inspection with enlarged text, screen readers and narrow widths on Android and web remains NOT STARTED.


### TC-033 — Android multi-select MIME coverage

- Run the manifest configurator against a generated runner and verify SEND_MULTIPLE intent filters exist for every supported SEND MIME family.
- Confirm the configurator remains idempotent and preserves singleTask launch mode.
- Python test source is authored but unrun. Verify in Android's chooser that multi-select text/URL/document batches can target StashHive, then confirm each item is presented sequentially and unsupported items are skipped with feedback; status remains NOT STARTED.


### TC-034 — Shared attachment backup and restore

- Save two image/document items that point to the same attachment key; export and decode the backup.
- Verify the backup contains one payload for the shared key and both item records preserve that reference.
- Restore into a library where the original IDs and attachment key already exist; confirm the restored items still share one newly mapped key, bytes remain readable, the shared payload is written only once, and each item's saved attachment filename/MIME metadata is preserved.
- Verify export rejects image/document items with missing or empty attachment keys and rejects unsupported item kinds carrying attachments.
- Unit/repository regression source is authored but unrun; manual storage interruption and device persistence checks remain NOT STARTED.


### TC-035 — Same URL with distinct shared context

- Submit two URL share events with identical type/path/MIME but different platform-provided message text; both should be accepted as distinct events.
- Re-submit one of those exact events inside the deduplication window; it should be rejected as a duplicate.
- Unit regression source is authored but unrun. Check that initial-intent and stream copies from an actual source app preserve the same message payload on Android; status remains NOT STARTED.
