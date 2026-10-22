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
- Verify the backup contains one payload for the shared key and both item records preserve that reference. Also reference one 13 MiB attachment from eight items and confirm export stays within the unique-attachment budget instead of counting the bytes eight times.
- Restore into a library where the original IDs and attachment key already exist; confirm the restored items still share one newly mapped key, bytes remain readable, the shared payload is written only once, and each item's saved attachment filename/MIME metadata is preserved.
- Verify export rejects image/document items with missing or empty attachment keys and rejects unsupported item kinds carrying attachments.
- Unit/repository regression source is authored but unrun; manual storage interruption and device persistence checks remain NOT STARTED.


### TC-035 — Same URL with distinct shared context

- Submit two URL share events with identical type/path/MIME but different platform-provided message text; both should be accepted as distinct events.
- Re-submit one of those exact events inside the deduplication window; it should be rejected as a duplicate.
- Unit regression source is authored but unrun. Check that initial-intent and stream copies from an actual source app preserve the same message payload on Android; status remains NOT STARTED.


### TC-036 — Muted text contrast in light and dark themes

- Render the app with its light theme and calculate contrast of the muted foreground against white cards, the light canvas, and input fields; require at least 4.5:1.
- Repeat in dark theme against the dark canvas and input field; require at least 4.5:1.
- Widget test source is authored but unrun. Manual visual review should still check chip states, icons, focus indicators, and text over every surface; status remains NOT STARTED until the UI test runs and manual review is recorded.


### TC-037 — Punctuation around URLs shared as text

- Share text containing a link wrapped in parentheses and followed by sentence punctuation; verify the outer bracket/period is not persisted as part of the URL.
- Share a URL whose own path ends in a balanced parenthesized segment; verify the balanced characters remain part of the URL.
- Unit regression source is authored but unrun. Confirm behavior with actual app shares from browser/chat clients during Android validation; status remains NOT STARTED.


### TC-038 — Backup attachment checksum integrity

- Export a backup with an attachment; verify its SHA-256 digest is included and matches the decoded bytes.
- Change the base64 payload to different but valid bytes without changing the stored digest; restore must reject the backup with a clear integrity error.
- Remove the digest from a version-1 backup and verify it remains importable for backward compatibility.
- Codec regression source is authored but unrun; full restore/storage interruption checks remain NOT STARTED.


### TC-039 — Shared text limit units and error message

- Submit text at the supported 1,000,000-character boundary and confirm it remains eligible for intake.
- Submit text one character above the limit and confirm rejection states the character limit explicitly instead of describing it as a byte-size limit.
- Unit test source is authored but unrun; Unicode-heavy payload behavior remains pending validation.


### TC-040 — Distinguish a single word from a bare web address

- Share a plain single word (for example, `remember`) and confirm it becomes a note rather than a fabricated `https://remember` link.
- Share `example.com/guide` and `example.com:8443/guide`; confirm both become link drafts with the HTTPS scheme and path/port retained.
- Unit regressions are authored but unrun. Verify against real Android browser/chat share payloads; status remains NOT STARTED.


### TC-041 — Equivalent share payload normalization

- Submit a share event with surrounding whitespace in its path/message and mixed-case MIME metadata, then resubmit the same user-visible event with normalized fields.
- Confirm the first event is accepted and the normalized equivalent is suppressed inside the de-duplication window.
- Unit regression source is authored but unrun; verify field consistency for actual initial-intent and stream events on Android; status remains NOT STARTED.


### TC-042 — Mixed-MIME Android multi-share

- Generate/configure the Android manifest and confirm `SEND_MULTIPLE` includes `*/*` as well as each supported MIME family.
- From an Android file manager, select a mixed image/document/text batch; confirm StashHive appears in the chooser, each entry is inspected by its actual type, supported drafts progress sequentially, and unsupported entries are skipped with feedback.
- Python manifest regression is authored but unrun. Chooser matching and URI permission behavior require a real Android device; status remains NOT STARTED.


### TC-043 — Item-type badge text contrast

- Check each Link, Note, Image and Document badge's text accent against its pastel background.
- Compute WCAG contrast and require at least 4.5:1 for the small type labels. Verify icons remain distinguishable on both light and dark surfaces.
- Unit regression source is authored but unrun; manual visual review across themes remains NOT STARTED.


### TC-044 — Favorite-state icon contrast

- Render favorite indicators and the Item Details favorite action in light and dark themes.
- Verify the active star has at least 3:1 contrast against the card/surface, canvas and relevant input surface.
- Automated test source is authored but unrun; visually confirm the favorite status remains recognizable and does not rely on color alone (the semantic label/action text must remain exposed). Status remains NOT STARTED.


### TC-045 — Standalone URL punctuation cleanup

- Share a standalone URL with a trailing sentence period and verify the saved URL excludes that period.
- Share a standalone URL with a balanced parenthesized path segment and verify the parentheses are retained.
- Unit regression source is committed but unrun; validate browser/chat source payloads on Android before marking passed.


### TC-046 — Incoming URL and context size limits

- Share a URL at exactly 4,096 characters; confirm it is accepted.
- Share a URL at 4,097 characters; confirm intake rejects it with a clear limit message.
- Share a valid URL with accompanying text at 1,000,001 characters; confirm the draft is rejected using the stated text-character limit.
- Unit regression source is authored but unrun; cross-check the caps with backup decode/encode limits.


### TC-047 — Shared image/document byte intake

- Share a small TXT document with generic MIME metadata and confirm extension-based MIME fallback, filename, bytes and document type.
- Share a small PNG image and confirm image type, filename, MIME and bytes.
- Share an unsupported `.exe` file and confirm a recoverable unsupported-type error.
- Create a file one byte over the 15 MiB limit and confirm intake rejects it using the length check before reading the full payload.
- Unit regression source is committed but unrun. Android content URI permissions, source-app chooser and actual attachment persistence remain NOT STARTED.


### TC-048 — Edit item kind and attachment cleanup

- Save an image with bytes, edit it into a note/link, and confirm the new record has no attachment key/name/MIME while the unused old payload is reclaimed.
- Attempt to save a link/note with an attachment key and an image/document without a key; repository validation must reject both before mutation.
- Create two items sharing one attachment key, convert one to a note, and confirm the other remains readable and its payload is retained.
- Repository regression source is committed but unrun. Confirm image-to-document switching requires choosing a replacement file in Quick Save and verify actual storage cleanup on Android/web.


### TC-049 — Saved-item validation parity

- Attempt to save/export a URL beyond the shared 4,096-character limit and verify rejection before storage/export.
- Attempt to export a file item whose attachment filename is whitespace-only; export must reject data that restore would reject.
- Verify invalid attachment-kind/key pairs, oversized content, and excessive tag counts are consistently rejected by repository/save, encoder, and decoder validation.
- Regression source is authored but unrun; full save → backup → restore round-trip remains pending.


### TC-050 — Quick Save metadata edits with shared attachments

- Create two image items that intentionally reference one stored attachment key.
- Edit the second item without choosing replacement bytes; save and confirm it retains the shared key and the original bytes remain readable.
- Confirm replacement-file selection uses a per-item key rather than overwriting bytes shared by another item.
- Repository tests TC-048 cover converting an attachment-bearing item to a note directly and verify old metadata/payload cleanup. The current editor keeps item kind fixed.
- Widget regression source is committed but unrun; repeat on Android/web after the manual build checkpoint.


### TC-051 — Consistent MIME inference between picker and share intake

- Verify the shared filename/MIME helper maps common image and document extensions consistently, including BMP, HEIC/HEIF and TIFF.
- Share a TIFF file with generic `application/octet-stream` metadata and confirm intake infers `image/tiff` rather than treating it as an unsupported binary file.
- Unit regressions are committed but unrun; actual decoding/preview capability for each image format needs Android/web device coverage.


### TC-052 — Quick Save URL scheme and tag limits

- Enter an uppercase `HTTPS://` URL and confirm it saves with a normalized lowercase HTTP scheme.
- Enter 101 unique tags; Quick Save should explain the 100-tag limit and save nothing.
- Enter a tag containing 101 characters; Quick Save should explain the per-tag limit and save nothing.
- Widget regression source is committed but unrun; verify the messages are understandable at narrow widths and enlarged text.


### TC-053 — Size-first file-picker intake

- Pick a valid small image/document on Android and web; confirm length is checked before bytes are read and the attachment can be saved.
- Pick a file above 15 MiB; confirm it is rejected before calling the full-byte read path.
- Try an empty file and a cloud/provider file whose size cannot be determined; confirm a clear recoverable error and no saved item.
- Test source for share-file size checks exists, but picker plugin behavior requires manual platform verification. Status remains NOT STARTED.


### TC-054 — Strict URL validation before external navigation

- Validate that HTTP/HTTPS URLs with a host are accepted and scheme casing normalizes.
- Confirm `javascript:`, `file:`, `mailto:`, hostless URLs, whitespace-bearing input and malformed values are rejected.
- Verify Item Details does not invoke the platform launcher for an invalid URL record that predates current repository validation.
- Unit source is authored but unrun. External browser launch and legacy-record behavior remain pending the manual validation checkpoint.


### TC-055 — Reject empty attachment payloads

- Attempt to save an image with no bytes, with a byte value outside 0–255, and with an existing stored attachment record that is empty; all must be rejected before the item record is written.
- Attempt to export and restore an image/document with an empty attachment payload; both paths must reject it rather than treating it as a valid saved file.
- Regression source is committed but unrun; also verify rollback behavior when the underlying storage fails during byte writes.


### TC-056 — Damaged legacy attachment handling

- Corrupt an existing attachment record with a non-integer list entry and confirm `readAttachment` returns no payload rather than silently dropping invalid bytes.
- Attempt backup export and confirm it fails with a useful damaged-attachment message instead of exporting mutated bytes.
- Regression source is committed but unrun; verify recovery instructions and backup/restore from a known-good backup manually.


### TC-057 — Copy-on-write attachment replacement

- Create two saved items sharing a payload whose key equals the owner item's ID.
- Request a replacement key for the owner; it must not equal the shared key, and the original bytes must remain unchanged for the dependent item.
- Verify an unshared item may keep its own key, an existing orphan payload is never silently overwritten, and an attachment key referenced by a damaged legacy record is avoided even when its payload is missing.
- Repository regression source is committed but unrun; perform actual replacement-file workflow on Android and web.


### TC-058 — Quick Save item-kind semantics

- Open Quick Save and confirm Link/Note/Image/Document each expose a named button with a selected state.
- Confirm only the active type is selected, then activate a different type through `SemanticsAction.tap` and confirm selection moves to that option.
- Widget test source is committed but unrun. Verify announcements with TalkBack and a browser screen reader; ensure decorative icon/label children are not double-announced.


### TC-059 — Legacy unsafe URL never reaches platform launcher

- Insert a legacy record with `javascript:alert(1)` directly into local storage, then open Item Details.
- Activate “Open link” and confirm the page reports that only HTTP/HTTPS links are allowed.
- Confirm the external-launch error message is not shown, proving the URL was rejected before the platform launcher was called.
- Widget test source is committed but unrun; verify valid HTTPS links still open correctly on Android and web.


### TC-060 — Shared MIME header versus filename consistency

- Share a PNG file whose source app reports `text/plain`; verify it is treated as an image with `image/png` metadata.
- Share a TXT file whose source app reports `image/png`; verify it remains a document with `text/plain` metadata.
- Confirm bytes and filenames remain intact. Regression source is committed but unrun; gather real MIME-header samples from Android source apps during device verification.


### TC-061 — Quick Save selector at enlarged text scale

- Render Quick Save with text scaling at 2×.
- Confirm Link/Note/Image/Document remain separately named and visible, with Image/Document wrapping into a second row rather than clipping in four narrow columns.
- Confirm the frame has no layout exception. Widget test source is committed but unrun; manually check common phone widths and system accessibility text settings.


### TC-062 — URL entry must not reinterpret non-web schemes

- Verify `example.com` and `example.com:8443/guide` normalize to HTTPS.
- Verify `javascript:alert(1)`, `file:`, `mailto:`, `http:example.com` and malformed host-port strings are rejected at the field boundary and nothing is saved.
- Repeat the classification for incoming shared text/URL parsing using `test/web_url_test.dart` and `test/share_intake_test.dart`.
- Unit/widget test source is committed but unrun; repeat valid-link open flow on Android/web after the manual checkpoint.


### TC-063 — Embedded credentials in web URLs

- Confirm a normal HTTP/HTTPS URL remains valid.
- Confirm a URL containing embedded username/password user-info is rejected before save, import or platform launch.
- Unit test source is committed but unrun; verify the message shown to users remains understandable and does not echo credential data.


### TC-064 — Inline saved URL length validation

- Enter a URL that exceeds the supported 4,096-character limit, attempt to save, and confirm the field exposes the specific limit message.
- Confirm no record is written and the user remains on the form to edit the value.
- Widget source is committed but unrun; repeat at narrow width and enlarged text scale to review error-message wrapping.


### TC-065 — Tag field integrity

- Attempt to save/export tags that are empty, whitespace-only, or have leading/trailing whitespace.
- Confirm the repository and backup encoder reject malformed tags before persistence/export, while Quick Save's comma-separated input continues to trim entries and ignore empty separators.
- Regression source is committed but unrun.


### TC-066 — Generated ID collision avoidance

- Seed the local item and attachment stores with known keys.
- Request a new item ID and verify it is absent from both stores, including orphaned attachment keys and raw attachment references whose payload is missing.
- Repository test source is committed but unrun; concurrent multi-window writes still need platform-level consideration.


### TC-067 — Invalid local-record recovery

- Seed the local store with an unsupported item kind and a record whose stored Hive key differs from its embedded item ID.
- Trigger repository refresh by saving a valid item; confirm the valid item loads and the malformed/mismatched records are skipped without crashing the library.
- Test source is committed but unrun; verify how recoverable damaged records are surfaced to users before release.


### TC-068 — Recovery warning for malformed local records

- Seed local storage with an item record whose kind or required field shape is unreadable, then trigger repository refresh.
- Confirm valid records still load, the skipped-record count matches the malformed raw entries, and the Library displays the recovery warning.
- Verify the warning does not claim malformed raw data is included in exports and recommends a prior backup. Widget/repository test source is committed but unrun.


### TC-069 — Prevent in-place writes to shared attachment keys

- Create two saved items referencing the same attachment key.
- Attempt to save replacement bytes through the repository using that shared key.
- Confirm the write is rejected before record or payload mutation, and both items retain their prior relationship and original bytes.
- Repository regression source is committed but unrun.


### TC-070 — Oversized local record recovery bound

- Seed the local store with a structurally valid record whose note content exceeds the one-million-character storage limit, alongside a valid item.
- Trigger repository refresh and confirm the oversized record is skipped, the valid item stays available, and the skipped-record warning count increases.
- Test source is committed but unrun.


### TC-071 — Quick Save kind-label contrast by theme/state

- Check all four item-type labels when selected and unselected in light and dark themes.
- Require at least 4.5:1 contrast for normal-sized label text against the corresponding light surface, selected pastel fill, or dark surface.
- Unit regression source is committed but unrun; confirm visual consistency and icon distinction during manual theme review.


### TC-072 — Stored attachment byte-list bounds

- Confirm non-empty byte arrays within 15 MiB are accepted.
- Confirm null, empty, non-integer, negative and above-255 byte entries are rejected.
- Supply a lazy list reporting a length above the cap; validation must reject it before iterating over elements.
- Unit source is committed but unrun; actual memory profile and storage-corruption recovery remain pending.


### TC-073 — Missing image/document payload feedback

- Seed a legacy image record whose attachment key has no payload; open/view it and confirm the missing-image message appears.
- Seed a legacy document record with a missing payload; activate Open/share and confirm StashHive advises restoring a backup.
- Confirm the page remains responsive and the item remains in the library. Widget tests are committed but unrun.


### TC-074 — Quick Save kind icon contrast

- Check Link, Note, Image and Document icons when selected/unselected in light/dark themes.
- Require at least 3:1 non-text contrast for decorative icons, with normal-text labels retaining at least 4.5:1 where applicable.
- Unit regression source is committed but unrun; manually confirm visual consistency with borders and selected state.


### TC-075 — Effective-content share-event deduplication

- Deliver text shares with the same effective draft text but different path/message representation; confirm the duplicate is suppressed.
- Deliver file shares with the same path and MIME but different unused message metadata; confirm the duplicate is suppressed.
- Confirm URL shares with different accompanying context are still treated as distinct events and batch ordering is preserved.
- Regression source is committed but unrun; confirm actual initial-intent/stream parity on Android.


### TC-076 — Case-insensitive tag identity

- Deserialize a legacy item with `Reading`, `reading`, `Work`, blank entries and padded duplicates; confirm it normalizes to `Reading`, `Work`.
- Attempt to save/export an item containing both `Reading` and `reading`; strict validation must reject it.
- Test source is committed but unrun; confirm tag chips/counts remain stable after restart and backup restore.


### TC-077 — Incoming attachment metadata limits

- Share a file with a filename longer than 255 characters and verify a clear filename-limit rejection before reading bytes.
- Share an otherwise image-classified file with MIME metadata longer than 128 characters and verify the metadata limit is reported before file I/O.
- Confirm valid file shares continue to preserve their name/MIME/bytes. Test source is committed but unrun.


### TC-078 — Attachment metadata requires an attachment key

- Attempt to save a link/note with a filename or MIME field but no attachment key; repository validation must reject it before writing.
- Attempt to export the same malformed item; backup validation must reject it instead of producing a record that cannot be interpreted consistently.
- Regression source is committed but unrun.


### TC-079 — Empty note rejection at save/export boundaries

- Attempt to save a note whose content is empty or whitespace-only; the repository must reject it before writing a record.
- Attempt to export the same invalid note; backup validation must reject it.
- Confirm ordinary non-empty Unicode notes still round-trip. Test source is committed but unrun.


### TC-080 — Timestamp bounds on reload/save/export

- Seed a raw local record whose update timestamp exceeds the supported date range; trigger refresh and confirm it is skipped, counted, and does not prevent valid records from loading.
- Try to save and export records with out-of-range timestamps; both paths must reject them before persistence/export.
- Regression source is committed but unrun; confirm ordinary current timestamps still render and round-trip.


### TC-081 — Orphan attachment payload cannot be overwritten by a new item

- Seed an attachment payload with no owning saved item.
- Attempt to save a new image using that key with different bytes.
- Confirm the repository rejects the save, does not add the record, and preserves the original orphan payload byte-for-byte.
- Test source is committed but unrun.


### TC-082 — Collection count cannot exceed backup limit

- Seed exactly 500 valid collections and reopen the repository.
- Attempt to add one more; confirm a clear format-limit error and no preference mutation.
- Export/decode the library backup and confirm all 500 collections are retained.
- Regression source is committed but unrun.


### TC-083 — Restore must not exceed the collection portability cap

- Seed a destination library with 500 collections and at least one valid saved record.
- Restore a valid backup that introduces one additional distinct collection.
- Confirm restore rejects before writes, destination items remain unchanged, and the collection list stays at 500.
- Regression source is committed but unrun.


### TC-084 — Saved-item count stays within backup capacity

- Confirm a count of 9,999 plus one new item is accepted and 10,000 plus zero new items is accepted.
- Confirm any count above 10,000 and negative count inputs are rejected by the shared guard.
- Verify repository save and restore call the guard before storage writes; unit/repository regression source is committed but unrun.


### TC-085 — Restore cannot accidentally heal another record's missing attachment

- Seed a legacy image record referencing an attachment key whose payload is missing.
- Restore a valid backup image whose ID/attachment key matches that dangling reference.
- Confirm restore allocates a different ID/key, stores the imported bytes under the new key, and leaves the legacy reference missing rather than silently reassigning its data.
- Repository regression source is committed but unrun.


### TC-086 — Direct lookup must not return skipped raw records

- Seed an unknown-kind record, an oversized-content record and a record whose Hive key differs from the embedded ID.
- Trigger refresh and verify all are skipped and counted; `findById` using each raw Hive key must also return null.
- Confirm parseable legacy records with valid field shape but unsafe URLs/missing attachments remain directly retrievable for repair. Regression source is committed but unrun.


### TC-087 — Invalid legacy item update feedback

- Seed a parseable saved link with a non-web URL, open Item Details and activate Favorite.
- Confirm the repository rejects the invalid record update safely, the favorite flag remains unchanged, repair guidance appears, and no widget exception escapes.
- Widget regression source is committed but unrun; test the equivalent Library card menu on Android/web during the manual checkpoint.
