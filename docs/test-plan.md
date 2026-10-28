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

- Pick a valid small image/document on Android and web; confirm length is checked first, then bytes arrive via the bounded `readAsByteStream()` reader and the attachment can be saved.
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


### TC-088 — Backup restore picker compatibility and size guard

- Select a valid JSON backup on Android and web; confirm the single-file picker yields a byte stream within the 145 MiB cap and restore proceeds.
- Select an empty/unknown-size file and a backup over 145 MiB; confirm each is rejected before full byte loading.
- Confirm no old `FilePickerResult.files` wrapper is used for the pinned file_picker API and that the post-read cap remains.
- Manual test pending; no plugin/device result is claimed.


### TC-089 — Legacy collection preference recovery

- Seed preferences with case-only duplicates, an empty name, a non-string value, and an overlong name; confirm one canonical instance remains and skipped entries are counted.
- Seed 501 unique collection names; confirm only 500 are exposed and the remainder is reported.
- Confirm the Library warning announces collection normalization/rejection and recovery guidance without throwing. Regression source is committed but unrun.


### TC-090 — Attachment buffer integrity after copy reduction

- Import a shared image/document and confirm the stored bytes match the source exactly.
- Save a picked file and restore a backup containing attachments; confirm every byte remains identical and shared-payload relationships remain intact.
- Existing assertions live in `test/share_intake_test.dart`, `test/library_repository_test.dart`, and `test/backup_codec_test.dart`; execution is pending. Profile peak memory only during the manual performance checkpoint.


### TC-091 — Item-assigned collection reachability

- Save a valid item assigned to a collection that is not yet present in the preference list; confirm the collection appears in navigation and remains represented in backup metadata.
- Deserialize a legacy padded collection name and a whitespace-only assignment; confirm the first is trimmed and the latter becomes unassigned.
- Verify saving/deleting items refreshes inferred collection entries without disturbing explicitly stored collections. Test source is committed but unrun.


### TC-092 — Collection cap cannot be bypassed through saved-item metadata

- Seed 500 valid collections, then attempt to save an otherwise valid item assigned to a new, unlisted collection.
- Confirm the repository rejects the save with the collection limit message, the item remains absent, and the existing collection list is unchanged.
- Repository regression source is committed but unrun.


### TC-093 — Narrow Library/Search layout at 2× text

- Render Library and Search at 320×568 with system text scaling set to 2× and a saved item with a long title/summary.
- Confirm neither screen reports a layout exception; the Library brand row should not overflow and the card grid should remain scrollable.
- Widget regression source is committed but unrun; verify visually on an actual narrow Android device and browser viewport.


### TC-094 — Forced image share with contradictory MIME

- Share an extensionless binary image via the OS image-share intent with `text/plain` MIME metadata.
- Confirm the draft remains an image, its MIME is not falsely stored as `text/plain`, and bytes are preserved.
- Regression source is committed but unrun; validate against real image-source apps on Android.


### TC-095 — Collection creation post-write rollback

- Start with no collection preference key.
- Inject an error after the collection preference write has completed, then attempt to add a collection.
- Confirm the API reports the original error, removes the partially committed preference key, and exposes no new collection in the notifier. Regression source is committed but unrun.


### TC-096 — Validate backup once and restore decoded content

- Select a malformed backup and confirm codec validation rejects it before the merge confirmation appears.
- Select a valid backup with attachments, confirm the merge, and verify restored data/bytes match the source.
- Confirm repository rollback behavior is unchanged when the decoded restore is interrupted.
- Existing decoder/restore regression source covers these paths but is unrun; profile peak memory on a large backup at the manual checkpoint.


### TC-097 — UTF-8 backup size parity

- Verify the shared UTF-8 byte counter matches encoded byte lengths for ASCII, Urdu/Arabic-script text and emoji, including a supplementary character whose Dart string length differs from UTF-8 byte length.
- Confirm backup export/decode and the restore file picker use the same 145 MiB byte cap.
- Unit source is committed but unrun; exercise Unicode-heavy backup export/restore in the final checkpoint.


### TC-098 — Backup decoder does not retain decoded base64 fields

- Decode a backup containing one or more attachments and confirm byte content, metadata, checksum validation and restore output remain unchanged.
- Review the temporary parsed attachment map to confirm its `base64` field is removed only after the corresponding byte payload has passed size and integrity validation.
- Existing backup codec regression source covers the returned behavior but is unrun; measure memory use on a large backup during the manual performance checkpoint.


### TC-099 — Picked attachment filename preflight

- Select a file with a normal filename and confirm it continues to the size-first read flow.
- With a platform/mocked picker fixture returning an empty or more-than-255-character name, confirm the specific filename message appears before `length()` or `readAsBytes()` is called.
- Source is committed; exercise actual picker/provider behavior on Android and web during the manual validation checkpoint.


### TC-100 — MIME-equivalent incoming file events deduplicate

- Deliver the same `.png` file event twice in the duplicate window, once with `text/plain` and once with `image/png` MIME metadata.
- Confirm the first event is accepted and the second is suppressed because both resolve to `image/png` under extension-first intake.
- Regression source is committed but unrun; validate the equivalent provider behavior on Android.


### TC-101 — Cross-type incoming share deduplication

- Deliver a standalone URL once as text (uppercase scheme and trailing punctuation) and once as URL media; confirm one normalized URL draft fingerprint.
- Deliver the same recognized PNG once as a generic file intent with conflicting MIME metadata and once as an image intent; confirm duplicate suppression.
- Confirm non-empty URL context remains distinct. Regression source is committed but unrun; verify real provider event shapes on Android.


### TC-102 — Attachment previews avoid a second byte copy

- Read a saved attachment and confirm returned bytes remain byte-for-byte identical to stored payloads.
- Verify Library thumbnail, Item Details preview and document share accept the returned `Uint8List` directly without an extra UI-side copy.
- Existing repository integrity tests cover the data; execution and Android memory profiling remain pending.


### TC-103 — Backup export buffer integrity after copy reduction

- Export a backup containing non-ASCII metadata and attachment payloads; confirm the shareable JSON bytes decode to the same backup content.
- Confirm export no longer creates an additional `Uint8List.fromList` copy after UTF-8 encoding.
- Existing codec/restore byte-integrity tests apply but are unrun; profile large exports during the manual checkpoint.


### TC-104 — Explicit confirmation before partial backup export

- Seed local storage with a malformed raw record alongside one readable saved item.
- Open Backup & Privacy and confirm it displays the skipped-record count and states that an export will omit unreadable records.
- Start export; confirm the partial-export dialog appears. Cancel and confirm the dialog closes without invoking the share sheet or creating the backup.
- Widget source is committed but unrun; verify the affirmative path exports only after explicit acknowledgement.


### TC-105 — Confirm before exporting normalized legacy collections

- Seed an unreadable local record plus collection preferences with a case-only duplicate and an invalid blank entry.
- Open Backup & Privacy and confirm the recovery banner includes both skipped-record and skipped-collection counts.
- Start export; confirm the dialog describes both omission types and explains raw entries are not deleted. Cancel and confirm it closes without starting the share flow.
- Widget test source is committed but unrun; confirm the affirmative path remains functional at the manual checkpoint.


### TC-106 — Accessible names for secondary action menus

- Open Collections with at least one collection; confirm its overflow menu exposes a contextual name such as `Actions for Learning collection` and reveals Rename/Delete actions.
- Open Item Details; confirm the overflow menu exposes `Item actions` and reveals Edit/Delete actions.
- Widget test source is committed but unrun; verify spoken labels and keyboard activation with TalkBack and browser screen readers.


### TC-107 — Collection assignment casing consistency

- Seed the preference list with `Learning` and a legacy raw saved item assigned to `learning`; reopen the repository and confirm direct lookup and the visible item model use `Learning`.
- Save a new item assigned to `learning`; confirm the Hive record itself stores `Learning` and it remains selectable/filterable in the existing collection.
- Repository regression source is committed but unrun.


### TC-108 — Restore persists canonical collection spelling

- Seed the destination with a `Learning` collection.
- Restore a valid backup whose item and collection metadata use `learning`.
- Confirm the restored item model, the raw persisted record and the visible collection list use one canonical `Learning` spelling.
- Repository regression source is committed but unrun.


### TC-109 — Block export until overflow assignments are repaired

- Seed 500 portable collection names and a legacy saved item assigned to a distinct 501st collection.
- Open Backup & Privacy and start export; confirm it blocks the export before the partial-export dialog and explains how to repair the item's assignment.
- Confirm the item remains present and unmodified. Repository/widget test source is committed but unrun.


### TC-110 — Partial-backup omission metadata survives export/import

- Export a library with one unreadable raw record and two invalid/duplicate collection entries alongside a readable item.
- Decode the generated backup and confirm both omission counts are preserved.
- Confirm old version-1 backups without either optional field decode both counts as zero, and malformed negative/wrong-type counts are rejected.
- Codec/repository regression source is committed but unrun; restore dialog display of both notices remains part of the manual picker validation.


### TC-111 — Collection Contents casing tolerance

- Provide a saved-item model whose collection assignment is `learning`.
- Open Collection Contents for `Learning` and confirm the item appears rather than showing an empty state.
- Confirm no layout/widget exception. Test source is committed but unrun; restart and backup/restore behavior remain part of manual persistence checks.


### TC-112 — Quick Save attachment picker semantics

- Open Quick Save for an image without a selected file.
- Confirm the picker is exposed as one button named `Choose an image`, with a tap action and a hint that a file up to 15 MB can be selected.
- For an existing attachment, confirm the spoken label uses the filename and the hint announces replacement behavior. Widget source is committed but unrun; verify with TalkBack and a browser screen reader.


### TC-138 — Out-of-range legacy timestamp recovery

- Seed local storage with an otherwise well-shaped record whose updated timestamp exceeds the supported DateTime range.
- Trigger repository refresh and confirm it is skipped and included in the recovery count; direct lookup by its stored ID must also return null.
- Verify valid records remain visible. Regression source is committed but unrun.


### TC-139 — Revalidate in-memory decoded backups before restore

- Construct a `DecodedBackup` directly rather than using JSON decode; include missing attachment bytes, invalid attachment metadata or duplicate item IDs and confirm validation fails before any storage write.
- Construct a valid item assigned to a collection absent from the declared collection list; confirm restore includes the assignment in navigation/backup metadata.
- At 500 existing collections, construct a backup whose item alone introduces a new assignment; confirm restore fails before writing the item.
- Regression source is committed but unrun.


### TC-140 — Legacy case-only duplicate collections remain importable

- Start with a valid version-1 backup, change its collection list to contain `Learning` and `learning`, and decode it.
- Confirm decoded-backup preflight permits the historical case-only duplicate and repository merge produces one canonical collection label.
- Regression source is committed but unrun.


### TC-141 — Shared-file streaming size enforcement

- Feed a chunk stream whose total equals the cap and confirm bytes are returned intact.
- Feed a stream whose next chunk would exceed the cap; confirm a clear format error and that the reader does not consume subsequent chunks.
- Existing share-intake tests still cover an oversized local file. Test source is committed but unrun; validate Android content providers with unreliable length reporting during device verification.


### TC-142 — Legacy item metadata normalization

- Deserialize a stored item with whitespace around its title, URL and attachment filename, plus uppercase MIME metadata.
- Confirm the loaded model contains trimmed strings and a lowercase MIME type, while note/content text remains unchanged.
- Model regression source is committed but unrun; confirm the normalized values persist after edit/export/restore.


### TC-143 — Picker imports stay bounded while streaming

- Confirm Quick Save uses `PlatformFile.readAsByteStream()` and the shared byte reader for the 15 MiB cap.
- Confirm Backup & Privacy uses the same reader with the 145 MiB cap and still releases the raw byte buffer after decode/validation.
- Run stream-reader boundary tests, then verify actual Android SAF, browser and cloud-backed files with unreliable length metadata. Source changes/tests are committed but unrun; platform validation remains NOT STARTED.


### TC-144 — Attachment size limit consistency

- Confirm Quick Save, OS-share intake, bounded byte reads and backup codec all use the same attachment byte cap.
- Boundary test source continues to assert the stream accepts exactly the cap and rejects a chunk that would cross it. Source inspection completed; tests remain unrun.


### TC-145 — Preflight combined attachment bytes before decoding

- Verify the encoded-length helper rounds byte budgets up to base64's 4-character quantum for 0–4 decoded bytes and rejects negative budgets.
- Confirm backup decoding checks each encoded payload against remaining combined bytes before base64 allocation, then still checks actual decoded sizes.
- Helper regression source is committed but unrun; profile a near-100 MiB backup only at the manual performance checkpoint.


### TC-146 — Unsupported image preview fallback

- Save an image-kind item with bytes that the current decoder cannot display.
- Open Item Details and activate View image; confirm a readable preview-unavailable message is shown, no widget exception escapes, and the saved attachment remains available for sharing.
- Widget regression source is committed but unrun; verify real TIFF/HEIC behavior on Android/web because support varies by platform decoder.


### TC-147 — Attachment bytes remain intact after base64 copy reduction

- Decode a backup with one or more attachments and confirm the stored byte sequences match the original source.
- Confirm SHA-256 tamper detection, empty-payload rejection and combined-byte-limit preflight continue to apply.
- Existing codec tests cover the behaviors; execution and near-limit memory profiling remain pending.


### TC-113 — Collection row counts match case-insensitive contents

- Create a visible `Learning` collection and an item whose legacy assignment is `learning`.
- Confirm the collection row displays `1 saved item`, and that Collection Contents also lists it.
- Widget regression source is committed but unrun.


### TC-121 — Search result sorting parity

- Save three items with deliberately different titles, creation timestamps and update timestamps.
- Confirm the default Recently saved order uses newest updates first, Title A–Z uses a case-insensitive title comparison, and Oldest first uses creation timestamps ascending.
- Confirm changing sort order does not change saved-item metadata. The widget regression source is committed but unrun; check menu usability at narrow width and enlarged text during manual visual/accessibility review.


### TC-114 — Partial backup of unexportable legacy items

- Seed an unsafe legacy URL and a missing-payload image beside a valid item.
- Confirm the repository's export preflight counts the two unexportable records, creates a backup containing only valid records, records the omission count in optional metadata, and keeps the original records unchanged locally.
- On Backup & Privacy, attempt export and confirm the dialog explains invalid fields/missing attachments and asks before omission; cancel and confirm no share flow starts.
- Confirm restore displays that unexportable items omitted from the source backup cannot be recovered from that file. Regression source is committed but unrun.


### TC-116 — Metadata-only performance baseline

- After dependencies are resolved, run `dart run tool/benchmark_library_repository.dart` from the repository root when the owner requests a measurement checkpoint.
- Capture output for 100, 1,000 and 10,000 metadata-only items. Record the date, OS, Flutter/Dart versions and JSON output; note the runtime mode and any unusual machine load.
- Review repository open/validation, repeated search and favorites filtering, an existing-item edit, and backup encoding results. Rerun surprising results on the same environment before comparison.
- The harness imposes no latency threshold and must not be used to claim attachment or Android/web performance. Source is committed; measurements are pending. This is a deliberate local command, not an automatically triggered CI job.


### TC-115 — Portable item cap for legacy library export

- Seed 10,001 structurally valid local notes directly into the store to represent an older library exceeding the current cap.
- Confirm repository state retains all 10,001 records, export produces a valid backup with 10,000 items, and metadata reports one omitted unexportable record.
- Confirm the repository's collection-overflow gate is computed from items that will actually be exported, not records omitted by the portable item/attachment checks.
- Test source is committed but unrun.


### TC-118 — Unicode search coverage

- Create a note with English words, Urdu-script text, Roman Urdu, an accented title/collection, an emoji, and punctuation including a hash token and square brackets.
- Confirm the model finds each exact stored script/emoji/punctuation token and matches uppercase/lowercase accented text where Dart lowercase conversion applies.
- Confirm punctuation is preserved as literal substring content (for example, `release#42` matches and `release 42` does not). Do not infer OCR behavior or canonical-equivalence matching for differently normalized Unicode sequences.
- Regression source is committed but unrun. Full widget search testing and target-device/browser text-entry behavior remain part of the manual validation checkpoint.


### TC-119 — Backup encoder rejects duplicate item IDs

- Pass two otherwise valid item records with the same ID but different titles/timestamps to the encoder.
- Confirm export rejects the input before JSON output; the decoder's unique-ID rule and encoder rule must agree.
- Codec regression source is committed but unrun.


### TC-117 — Backup size preflight for large aggregate item metadata

- Reuse a moderate source string across enough valid item records that JSON escaping takes the serialized backup beyond the 145 MiB cap.
- Confirm the encoder rejects it with the portable-size error before producing a full backup string.
- Test source is committed but unrun; compare peak memory during the manual performance checkpoint.


### TC-120 — Portable backup encoding size preflight

- Encode multiple small attachment records with UTF-8 metadata (including accented, Urdu/CJK, and emoji text), quoted/backslash attachment keys, and payload byte lengths that exercise base64 rounding.
- Confirm the encoder returns a portable backup within the 145 MiB UTF-8 byte cap, that its UTF-8 count matches the actual encoded bytes, and that decode preserves each attachment payload byte-for-byte.
- This regression checks that the size estimate does not falsely reject normal escaped/multibyte metadata. It does not simulate an over-limit allocation; the pre-allocation rejection boundary and peak memory remain pending manual validation.
- Source committed but unrun; keep CI manual-only.


### TC-122 — Caller cannot mutate bytes after passing them to save

- Pass a mutable `Uint8List` to repository save.
- Mutate the caller's input buffer during the post-attachment/pre-item-commit hook.
- Confirm `readAttachment` returns the original byte sequence, independent of later caller mutations.
- Repository regression source is committed but unrun.


### TC-123 — Reject unreferenced backup attachment payloads

- Decode a backup containing no items but one attachment entry with invalid base64; confirm the decoder rejects the orphan key with a reference error before reporting a base64 error.
- Construct a `DecodedBackup` directly with an attachment not referenced by any item; confirm restore-boundary validation rejects it too.
- Codec regression source is committed but unrun; confirm compatibility with valid version-1 backups on the manual checkpoint.


### TC-124 — Deterministic tie-breaking across sort modes

- Create items with equal updated timestamps, equal creation timestamps and duplicate case-insensitive titles but distinct IDs.
- Sort with Recently saved, Oldest first and Title A–Z; confirm each mode follows documented primary ordering and the same deterministic secondary ordering on repeated runs.
- The model comparator regression is committed but unrun; widget parity and narrow/enlarged-text sort controls remain pending manual checks.


### TC-125 — Current StashHive brand is visible in the Library

- Open the Library and confirm the visible header says `StashHive`.
- Confirm the widget builds without layout exceptions; review the web-installed name and Android launcher label after the manual runner/build checkpoint.
- The Android configurator's Python regression also asserts the generated manifest application label is StashHive and remains idempotent. Test source is committed but unrun.


### TC-126 — Version-1 backup identifier remains backward compatible

- Decode a valid version-1 backup whose `app` field is `StashHive`, then encode it again.
- Confirm the marker remains `StashHive` and the backup remains readable; do not rename that schema marker as part of UI branding.
- Codec regression source is committed but unrun; old files must remain importable after the StashTrail rename.


### TC-127 — Delete an unreadable legacy record and reclaim orphaned bytes

- Seed a raw item record whose shape cannot be decoded but whose `attachmentKey` is a string, then seed bytes under that attachment key.
- Confirm the unreadable-record count includes the item, delete it by storage ID, and confirm both the raw item key and its now-unreferenced attachment payload are removed.
- Regression source is committed but unrun; verify behavior against legacy-store fixtures at the manual checkpoint.


### TC-128 — Do not delete an attachment still referenced by another item

- Seed an unreadable item and a valid image/document item that reference the same stored attachment key.
- Delete the unreadable record and confirm the valid item remains readable and the original attachment bytes are unchanged.
- Regression source is committed but unrun; reference safety is required even when the remaining/deleted record is not decoded normally.


### TC-129 — Roll back failed deletion of an unreadable legacy record

- Seed an unreadable raw item and its referenced attachment payload.
- Trigger the existing post-attachment-delete fault seam so the delete operation reports an error after removing the payload.
- Confirm the raw item is restored, the original attachment bytes are restored, and the unreadable-record count reflects the record again.
- Regression source is committed but unrun; recovery under actual storage interruption still needs platform validation.


### TC-130 — First-launch local-storage safety reminder

- Start with a fresh preferences box and launch StashHive. Confirm the Library shows a dismissible reminder that the library is local-only, with wording specific to the browser profile on web or app/device storage on Android.
- Confirm the message states that clearing local data can erase the library and that it does not sync automatically. Activate **Backup options** and verify Backup & privacy opens directly; return and test **Got it**.
- Confirm dismissal is persisted in the same local preferences store and the reminder does not reappear after closing and reopening the boxes. With a fresh browser profile/device store, confirm the reminder appears again.
- Repository and widget regression source is committed but unrun; web/Android first-launch behavior remains pending the manual validation checkpoint.


### TC-131 — Collection-delete storage failure is recoverable

- Create a collection and assign a saved item to it. Start collection deletion and confirm the action.
- Inject a failure during the repository's collection mutation. Confirm the UI shows a recoverable error instead of an uncaught framework exception, the collection remains listed, and the item's assignment remains intact after rollback.
- Regression source is committed but unrun. Real storage-write interruption and rollback success still need the manual validation checkpoint.


### TC-132 — Item deletion storage failure is recoverable

- Save an image with local attachment bytes, open Item Details, choose Delete saved item, and confirm.
- Inject a failure after the repository has attempted to remove the attachment. Confirm the screen remains open, a recoverable error is shown, and rollback preserves the saved record and original attachment bytes.
- Regression source is committed but unrun; actual storage-write interruption recovery remains pending the manual validation checkpoint.


### TC-133 — Attachment storage wording matches the platform

- Open Item Details for an image or document on Android and confirm the attachment section describes storage inside StashHive on the device.
- Open the same screen in the web app and confirm the label says the file is stored in this browser profile, not on the device or in the cloud.
- Check this copy together with Backup & privacy's local-storage warning. Widget source currently asserts the native label; both platform branches still require manual review because tests/builds have not been run.


### TC-134 — Dark-mode preference write failure is recoverable

- Start with the dark-mode preference absent/false and request dark appearance.
- Inject a storage failure after the preference write takes effect. Confirm repository rollback returns to the previous preference, the UI switch reverts to the persisted value, and no unhandled exception reaches the widget test.
- Regression source is committed but unrun; actual browser/device preference persistence remains pending the manual validation checkpoint.


### TC-135 — Search help copy reflects searchable fields and platform

- Open Settings → Search & saved content. Confirm its subtitle distinguishes browser-local scope on web from device-local scope on Android.
- Open the explanation and confirm it lists titles, URLs, notes, tags and collection names. Confirm it does not imply OCR/PDF extraction or cross-device search.
- Widget regression currently asserts the native copy and searchable-field explanation; the web-specific label and end-to-end behavior need manual platform review. Test source is committed but unrun.


### TC-136 — Unexpected storage/plugin errors use safe user-facing messages

- Inject a repository error during item deletion and collection deletion. Confirm the user sees a clear retry message, the underlying exception text is not displayed, and the rollback regression continues to preserve affected data.
- Cause unexpected errors during file selection, save, backup export and restore. Confirm raw plugin/storage details are not rendered into normal operation messages. App-defined `FormatException` validation guidance should remain actionable (including file/backup limits and invalid fields).
- The collection/item deletion widget regressions assert generic fallback text and that the injected exception is absent. Remaining error branches and platform-provided messages need manual review; test source is committed but unrun.


### TC-137 — Startup storage errors do not expose raw diagnostics

- Render the startup failure screen and confirm it gives platform-appropriate recovery instructions without a selectable/raw exception string.
- Confirm web guidance refers to browser-profile storage and native guidance to device storage. Neither branch should display an exception that may include filesystem paths.
- Widget regression source checks the fallback copy and absence of `SelectableText`; source is committed but unrun.



### TC-148 — Search hint matches indexed metadata

- Open Search and confirm the field hint lists titles, URLs, notes, tags and collections.
- Confirm the disclosed collection search scope matches the actual saved-item search behavior and the Settings explanation.
- Widget regression source is committed but unrun; visual wording review on web and Android remains pending.

### TC-149 — Empty Search state explains and clears an unmatched type filter

- Save a note, open Search with an empty query, and select a type that has no saved items (for example, Images).
- Confirm the empty state says "No items in this filter", explains that another type can be chosen, and offers "Clear filter" instead of implying the whole library is empty.
- Activate "Clear filter" and confirm the note and the overall result count return.
- Enter a query that has no matches and select Images; confirm the recovery button says "Clear search and filter", then activate it and confirm the query is empty and all items return.
- Widget regression source is committed but unrun; inspect the empty state with narrow widths, enlarged text, keyboard and screen-reader navigation during the manual checkpoint.

### TC-150 — Favorite update storage failure gives actionable safe feedback

- Save a link that is not favorited, open its item-action menu, and select **Add to favorites** while injecting an error after the favorite record write.
- Confirm the operation displays "Could not update this item. Check local storage and try again." rather than telling the user to repair unrelated URL/file fields.
- Confirm the internal simulated storage exception text is not displayed and the repository rolls the favorite state back to false.
- Widget regression source is committed but unrun; real storage failure behavior remains pending the manual platform validation checkpoint.


### TC-151 — Settings text-size preference persists and layers over system scaling

- Open Settings and change **App text size** from **System default** to **Large**, then confirm the screen and other app routes render at the larger scale.
- Confirm the selected size persists after closing and reopening the app/browser profile.
- With device accessibility text scaling enabled, confirm the app preference adds scale without reducing the platform-provided scale; check long labels and Settings at a narrow viewport.
- Change the preference back to **System default** and confirm the platform's text scale remains active.
- **Status:** Repository and widget regression source is authored but unrun; narrow-width, Android and browser verification remains pending.


### TC-152 — Item Details favorite failure uses the same safe recovery message

- Open a saved, non-favorite link in Item Details and tap **Favorite** while injecting a storage error after the favorite write.
- Confirm the user sees "Could not update this item. Check local storage and try again." The message must not tell the user to repair unrelated URL/file fields.
- Confirm the injected diagnostic text is not displayed and best-effort repository rollback leaves the item un-favorited.
- Widget regression source is committed but unrun; real browser/device storage failure behavior remains pending the manual validation checkpoint.

### TC-153 — Extra-large text preference persists and can be reset

- Open Settings → Text size, select **Extra large**, and confirm the stored preference is `1.3`.
- Recreate the app widget using the same repository and confirm the Settings control initializes to **Extra large** from the persisted preference.
- Select **System default** and confirm the stored multiplier returns to `1.0` without an uncaught widget exception.
- **Status:** Regression source is committed but unrun. Execute during the requested manual validation checkpoint; real browser/device restart behavior remains pending.


### TC-154 — Restore rollback preserves attachment bytes when item cleanup fails

- Start with an existing saved item and collection, then prepare a backup containing an image and its attachment bytes.
- Inject an interruption after restore has staged the imported record, and separately inject a failure while rollback tries to delete that staged item.
- Confirm the restore reports the original interruption, keeps the surviving item and its attachment bytes consistent, and restores the collection preferences to their pre-restore value.
- **Status:** Regression source is committed but unrun. The case checks best-effort recovery when storage refuses a rollback deletion; it does not claim that a real browser/device storage interruption has been validated.

### TC-155 — Acknowledge launch-time share before Quick Save review

- Launch StashHive from an Android share intent while the app is closed. Confirm the intent is retrieved and reset before the Quick Save draft waits for user review.
- Keep the draft open, then stop/restart the app before confirming the save. Confirm the same already-consumed launch intent is not automatically replayed on next launch.
- Inject a reset/acknowledgement failure in the service regression and confirm the already-read media is still queued rather than silently discarded.
- **Status:** Service regression source is committed but unrun. The app-stop/restart behavior and real Android intent delivery require manual device verification.

### TC-156 — Quick Save preserves note text across item-type changes

- Open Quick Save and select **Note**. Enter text in the note field, switch to **Link**, then switch back to **Note**.
- Confirm the previously entered text remains in the shared content field and no item was saved as a side effect of changing type.
- Repeat from a file or image draft where optional notes are entered; changing type may clear the type-specific attachment selection, but should not silently erase shared content.
- **Status:** Widget regression source is committed but unrun. Verify the interaction with keyboard, screen reader, and enlarged text during the manual checkpoint.

### TC-157 — Reselecting the active type keeps a shared attachment

- Open Quick Save using an incoming shared image or document so its attachment is prefilled.
- Tap the already-selected **Image** or **Document** type option, then save the draft.
- Confirm the attachment remains present, the correct item kind is saved, and the stored bytes match the originally shared payload.
- **Status:** Widget regression source is committed but unrun. Validate with real Android image/document shares at the manual checkpoint.

### TC-158 — Collection rename rolls back after preferences write commits

- Create a collection and assign at least two saved items to it.
- Inject a failure immediately after the updated collection preferences are written during rename.
- Confirm the rename reports the original error, both item assignments are restored, the collection list returns to its prior value, and raw persisted records/preferences agree with the visible state.
- **Status:** Repository regression source is committed but unrun. Real storage interruption and rollback-write failures remain part of the manual validation checkpoint.

### TC-159 — Concurrent library mutations do not lose updates

- Start adding one collection and pause the first operation immediately after its preference write.
- Request a second collection before releasing the first operation.
- Confirm the second mutation waits instead of deriving its write from stale in-memory state, then confirm both names exist in the visible list and the stored preference value.
- The same repository mutation queue covers item save/delete, collection add/rename/delete, and backup restore, preventing these structural writes from interleaving.
- **Status:** Regression source is committed but unrun. Real browser/Android persistence and rollback-write failure behavior remain pending the manual validation checkpoint.

### TC-160 — Mutation queue is released after a failed collection creation

- Pause the first collection creation immediately after its preference write, then queue a second collection creation.
- Let the first operation throw after the write so it exercises its rollback path.
- Confirm the second request did not start before the first failure was handled, then confirm it completes successfully and only the second collection remains in visible state and persisted preferences.
- **Status:** Regression source is committed but unrun. Confirm failure recovery against browser/Android persistence during the manual validation checkpoint.

### TC-161 — Simultaneous favorite toggles use the latest saved value

- Start with one saved item and call `toggleFavorite` twice without awaiting the first call.
- Confirm the two queued operations behave as two sequential user actions, so the final favorite value matches the original value.
- Check the repository notifier and the raw stored item record agree.
- **Status:** Regression source is committed but unrun. Validate repeated favorite actions during the manual persistence checkpoint.

### TC-162 — A late dark-mode failure cannot overwrite a newer choice

- Pause the first dark-mode write after the underlying preference write, then request the opposite setting.
- Allow the first operation to fail and roll back.
- Confirm the second request waited, then persisted its chosen value and left the preference key present.
- **Status:** Regression source is committed but unrun. Confirm preference persistence and recovery during the manual validation checkpoint.

### TC-163 — A late text-size failure cannot overwrite a newer choice

- Pause a text-size preference write after the underlying write, then request a different supported multiplier.
- Allow the first operation to fail and roll back.
- Confirm the second request waited and the final notifier getter and stored preference both show the second multiplier.
- **Status:** Regression source is committed but unrun. Confirm persistence with web and Android storage during the manual checkpoint.

### TC-164 — Discard attachment selections that belong to an outdated draft type

- Start a file-picker request from an Image draft and leave its result pending.
- Change the draft to Document, then complete the earlier request with a delayed image result.
- Confirm the stale result is discarded before file I/O, the Document draft still has no selected attachment, and it cannot be saved until a document is selected.
- Repeat by switching away from the requested type and back before completing the picker, ensuring the request revision—not just the current type—invalidates old results.
- **Status:** Widget regression source is committed but unrun. Verify native picker behavior on Android and file selection in web/desktop browsers at the manual checkpoint.


### TC-165 — Invalidate a picker result after switching away and back

- Start a file-picker request in an Image draft and leave the result pending.
- Change the draft to Document, then back to Image before resolving the original request.
- Complete the old picker with an image-shaped file and confirm the request revision invalidates it even though the current type again matches the original type.
- Confirm the stale result is discarded before file I/O and the draft cannot be saved until a fresh attachment is selected.
- **Status:** Widget regression source is committed but unrun. Android and browser/desktop picker behavior remains pending the manual validation checkpoint.


### TC-166 — Lock Quick Save controls while an item save is pending

- Pause the repository after the saved-item record has been written but before the save call completes.
- Confirm the text fields, type choices, collection selector, attachment picker and navigation controls, including a simulated system-back action, do not permit edits or cancellation while the snapshot is being persisted.
- Release the save and confirm the saved link, URL and note content match the values visible when saving began.
- **Status:** Widget regression source is committed but unrun. Verify slow-storage behavior and screen-reader state during the manual validation checkpoint.


### TC-167 — Recover Quick Save after a delayed save failure

- Enter a valid URL and note text, then pause the repository after the item write has started/committed but before save completes.
- Confirm the form remains locked while the write is pending.
- Release the operation with a simulated late storage failure and confirm the repository rolls back the item, Quick Save unlocks, and the entered URL/note remain in the controllers.
- Retry the save without changing the draft; confirm exactly one item is saved with the original URL and note and no framework exception escapes.
- **Status:** Widget regression source is committed but unrun. Verify late storage errors, retry behavior and accessible error feedback during the manual validation checkpoint.

### TC-168 — Recover after an attachment-picker error

- Open an Image draft and pause the first file-picker request while the attachment area is showing its progress state.
- Release the picker request with an unexpected provider error and confirm Quick Save reports safe retry guidance, does not expose the raw exception details, clears the busy state and does not create an item.
- Retry file selection with a valid image. Confirm the selected filename is shown and saving the draft persists the exact file bytes.
- **Status:** Widget regression source is committed but unrun. Verify picker cancellation, provider failures, byte-reading failures and retry behavior on Android and supported browser/desktop platforms at the manual checkpoint.

### TC-169 — Bound incoming share batches and fingerprint work

- Provide a batch with more than 100 entries and confirm the batch limiter preserves the first 100 items in original order and reports the remaining count instead of queuing the entire selection.
- Provide oversized shared text to the event deduplicator and confirm it bypasses JSON/UTF-8 fingerprint construction, reaches normal input validation, and is rejected with the documented length error.
- Provide a batch containing whitespace-only provider messages whose aggregate raw field length exceeds the fingerprint budget; confirm length preflight bypasses hashing before trimming those fields.
- Confirm ordinary in-limit events still deduplicate during the short window.  
- **Status:** Regression source is committed but unrun. Verify the warning and sequential review flow with Android source apps on a real device at the manual checkpoint.

### TC-170 — Accept text shares when the provider message is the only content

- Provide a text share whose path is empty but whose message contains valid note text.
- Confirm the message becomes an editable note draft rather than being rejected because an unused provider path is empty.
- Confirm URL, text, provider path and MIME length checks occur before potentially large trim/case-normalization copies.
- **Status:** Regression source is committed but unrun. Confirm provider-field conventions with real Android share sources at the manual checkpoint.

### TC-171 — Keep attachment metadata and bytes consistent during backup export

- Save an image, then begin replacing its attachment and item metadata with a repository operation paused after the item write.
- Request backup export while the replacement is still pending and confirm the export waits for the repository mutation queue.
- Release the write, decode the backup, and confirm the exported item metadata and attachment bytes both reflect the same completed edit.
- **Status:** Repository regression source is committed but unrun. Validate backup consistency during concurrent saves/deletes/restores and real browser/Android storage operations at the manual checkpoint.

### TC-172 — Ignore incoming share events after the home shell is disposed

- Start a share event, then close/dispose the host app shell while the Android share stream is being canceled.
- Confirm an event delivered after disposal is ignored without creating a queued completion future, showing SnackBars on a dead context, or starting new navigation.
- Confirm any share batch already being reviewed is allowed to unwind and its pending completion is released.
- **Status:** Manual lifecycle case; source guard is committed, but plugin cancellation and app-stop/restart behavior require Android device verification at the manual checkpoint.

### TC-173 — Bound the waiting queue for incoming share batches

- Keep one share batch active for user review, then deliver more unique share events until the waiting-batch limit is reached.
- Confirm the queue accepts no more than `maxPendingIncomingShareBatches` waiting batches and explicitly tells the user that the newly received share was not queued and must be shared again after current batches finish.
- Confirm the active batch can complete and waiting batches continue in FIFO order after capacity is available. An event declined for queue pressure must not be recorded in the de-duplication cache, so it can be retried after capacity returns.
- **Status:** Queue-limit unit regression source is committed but unrun; queue-full feedback, event ordering and teardown behavior still need Android device verification at the manual checkpoint.

### TC-174 — Do not throw while fingerprinting unusual file URIs

- Provide an incoming file event with a `file://` URI containing a non-local authority.
- Confirm duplicate-event fingerprinting remains best-effort and does not throw before the item can reach the normal intake error path.
- **Status:** Regression source is committed but unrun. Verify actual URI shapes emitted by file providers on Android at the manual validation checkpoint.

### TC-175 — Keep the newest dark-mode choice after an older write fails

- Start a dark-mode write and pause it after the preference write; queue two newer switch actions before releasing the first operation with a simulated failure.
- Confirm the repository serializes the writes, the newest queued value persists, the visible switch stays aligned with the latest user choice and the injected exception does not escape the UI.
- **Status:** Widget regression source is committed but unrun. Verify rapid theme changes with actual browser/device storage latency at the manual checkpoint.

### TC-176 — Keep the newest text-size choice after an older write fails

- Start a text-size preference write and pause it after the preference write; choose a different text scale while the first operation is still pending.
- Release the earlier operation with a simulated failure and confirm the newest scale persists and remains selected rather than being reset by the stale failure handler.
- **Status:** Widget regression source is committed but unrun. Verify rapid text-size changes under storage delay on web and Android at the manual checkpoint.

### TC-177 — Restore the visible text-size selection after persistence failure

- Start from System default, choose Large, then inject a late preference write failure.
- Confirm the repository rolls back to the original multiplier and the dropdown visibly shows System default again, rather than retaining an internal stale FormField selection.
- **Status:** Widget regression source is committed but unrun. Verify the selection and actual text scale after storage failures on web and Android at the manual checkpoint.

### TC-178 — Persist the last backup-prepared timestamp

- Record the timestamp only after the repository has generated the portable backup JSON.
- Confirm invalid timestamps are rejected without replacing the previously stored value.
- Close and reopen the repository boxes and confirm the latest valid timestamp remains available locally.
- **Status:** Repository regression source is committed but unrun. Confirm the informational preference remains separate from the backup payload and survives browser/native repository reopen at the manual checkpoint.

### TC-179 — Show backup preparation status truthfully

- Open Backup & privacy before any backup has been generated and confirm the status reads “Not prepared yet.”
- Generate a backup through `LibraryRepository.createBackup()` and rebuild the page; confirm the generated timestamp is persisted and the formatted local date/time is displayed.
- Confirm the explanatory text says this is the time the backup file was generated, not proof that the share-sheet destination saved it.
- **Status:** Widget regression source is committed but unrun. Verify status updates after the share sheet returns, including when it is canceled, on web and Android at the manual checkpoint.

### TC-180 — Keep backup export successful when optional status storage fails

- Store a prior valid last-backup-prepared timestamp, then inject a failure after the next timestamp write has committed.
- Create a backup and confirm valid backup JSON is still returned and decodes successfully.
- Confirm best-effort rollback restores the previous timestamp in both the repository getter and raw preferences.
- **Status:** Repository regression source is committed but unrun. Verify quota/storage failure behavior during backup generation on browser and Android at the manual checkpoint.

### TC-181 — Wait for delete rollback before creating a backup

- Save an image with known bytes, then pause deletion after its record and attachment have been removed.
- Request a backup while deletion is pending; confirm backup generation does not complete before deletion resolves.
- Release the delete with a simulated late failure. Confirm the repository restores the item and its attachment, then confirm the queued backup contains the original item metadata and exact original bytes rather than recording the temporary missing-file state.
- **Status:** Repository regression source is committed but unrun. Verify concurrent delete/backup consistency and rollback against browser and Android storage at the manual checkpoint.

### TC-182 — Wait for restore rollback before creating a backup

- Store an existing link and collection, then begin restoring a backup containing a new image and attachment.
- Pause restore after its staged records/attachment have been written but before collection preferences are committed; request a backup and confirm it waits.
- Release the restore with an injected interruption. Confirm restore rollback removes the staged item and attachment, and the queued backup contains only the original library item and collection with no orphan attachment payload.
- **Status:** Repository regression source is committed but unrun. Verify backup/restore concurrency and interruption recovery on web and Android at the manual checkpoint.

### TC-183 — Wait for save rollback before creating a backup

- Save an image with known bytes, then begin a replacement save and pause it after the new attachment and item record have been written.
- Request a backup while the replacement is pending; confirm the export waits rather than using the temporary replacement values.
- Release the save with a simulated late failure. Confirm rollback restores the old metadata and attachment bytes, then confirm the queued backup contains those restored values.
- **Status:** Repository regression source is committed but unrun. Verify concurrent backup/failed-save behavior against browser and Android storage at the manual checkpoint.

### TC-184 — Wait for collection changes before creating a backup

- Create a collection and assign a saved item to it, then begin renaming the collection.
- Pause rename after its persisted item assignments and collection preference write but before the repository refreshes its visible state. Request a backup and confirm export waits.
- Release the rename successfully. Confirm the backup contains the renamed collection and the saved item's matching assignment, not the old collection state.
- **Status:** Repository regression source is committed but unrun. Verify backup consistency with concurrent collection changes on browser and Android at the manual checkpoint.

### TC-185 — Use effective text when an unused provider path is oversized

- Provide a text share with a valid short message but a provider path longer than the normal shared-text limit.
- Confirm fingerprinting skips its expensive canonicalization for the oversized provider fields, while normal intake uses the effective message and produces an editable note draft.
- Confirm the unused path is neither required nor copied into the saved note.
- **Status:** Regression source is committed but unrun. Verify provider-field conventions and memory behavior on real Android share sources at the manual validation checkpoint.

### TC-186 — Recover from attachment size metadata failure

- Open an Image draft and return a file object whose size lookup throws an unexpected provider error.
- Confirm Quick Save shows safe retry guidance, does not display the raw provider detail, clears its progress state, and leaves the draft available without creating an item.
- Select a valid image on the next attempt, save it, and confirm the persisted attachment bytes match the chosen file.
- **Status:** Widget regression source is committed but unrun. Verify browser/desktop/Android provider failure behavior at the manual validation checkpoint.

### TC-187 — Recover when an attachment byte stream fails

- Open an Image draft and return a file whose size lookup succeeds but whose byte stream emits an unexpected provider error.
- Confirm Quick Save reports safe retry guidance, hides raw provider details, clears its busy indicator and creates no item.
- Select a valid image on the next attempt, save it, and confirm the stored attachment bytes exactly match the successful selection.
- **Status:** Widget regression source is committed but unrun. Verify provider stream failures, partial reads and retry behavior on Android and supported browser/desktop pickers at the manual validation checkpoint.

### TC-188 — Reject oversized Quick Save inputs before parsing

- Paste a URL longer than 4,096 characters and confirm validation reports the configured limit before attempting URL normalization.
- Paste a tags field longer than 12,000 characters and confirm the form shows a clear inline input-limit error without creating an item or splitting the oversized string into a tag list.
- Confirm normal URLs and valid tag sets continue to save as expected.
- **Status:** Widget/source regression is committed but unrun. Review paste behavior, validation wording and responsiveness on web and Android at the manual checkpoint.

### TC-189 — Bound search-query work on large input

- Provide an initial search query longer than 4,096 characters with at least one saved item present.
- Confirm the Search page reports the query-length limit, returns no results without scanning saved items, and remains free of layout/framework exceptions.
- Confirm ordinary search still normalizes the query once and matches case-insensitively across title, URL, note, tags and collection names.
- **Status:** Widget and model regression sources are committed but unrun. Review paste behavior, Unicode matching, responsiveness and accessibility on web and Android at the manual checkpoint.

### TC-190 — Recover from backup file size lookup failure

- Open Backup & privacy and provide a file picker result whose size lookup throws an unexpected provider error.
- Confirm the restore action returns to its idle state, the raw provider detail is hidden, no library records are changed, and the user can retry.
- On the second attempt provide a valid backup; confirm the merge confirmation appears and the valid item is imported.
- **Status:** Widget regression source is committed but unrun. Verify picker metadata errors, large/empty backup handling and retry behavior on web/Android at the manual validation checkpoint.

### TC-191 — Ignore oversized whitespace in an unused share message

- Send a text-share event whose path contains a short valid note while the provider's message field contains more than 1,000,000 whitespace characters.
- Confirm the message is recognized as empty without trimming/copying the oversized field, the path is used as the effective content, and an editable note draft is returned.
- Confirm oversized messages that contain real content still receive the configured length error and ordinary message-only shares remain supported.
- **Status:** Service regression source is committed but unrun. Verify whitespace handling and provider-field combinations with real Android share sources at the manual checkpoint.

### TC-192 — Recover from a backup byte-stream failure

- Open Backup & privacy and provide a backup file whose size lookup succeeds but whose byte stream throws an unexpected provider error.
- Confirm the restore action exits its busy state, hides private provider details, and leaves the current library unchanged.
- Retry with a valid backup; confirm the merge dialog is shown and the backup imports successfully.
- **Status:** Widget regression source is committed but unrun. Verify partial read, stream error, size lookup and retry behavior with real browser/Android pickers at the manual checkpoint.

### TC-193 — Prevent leaving Backup & privacy during an active restore commit

- Open Backup & privacy through a pushed route, choose a valid backup and confirm the merge.
- Pause repository restore after staged writes but before collection commit. Confirm the screen shows a restoring state, the app-bar Back action is disabled, and a simulated system-back action cannot dismiss the route.
- Release the restore and confirm it completes, shows feedback, preserves existing items and adds the backed-up item without a framework exception.
- **Status:** Widget regression source is committed but unrun. Verify Android system-back behavior and navigation during slow browser/native storage writes at the manual checkpoint.

### TC-194 — Show oversized-share warning after batch review

- Deliver an operating-system share batch with more than 100 entries.
- Confirm StashHive reviews the first 100 supported entries one editable draft at a time, without showing the truncation warning behind the first Quick Save route.
- If another share batch is already waiting, confirm its drafts are reviewed before the omission warning is shown; the warning should not be covered by a later Quick Save route.
- After all already-queued batch reviews finish, confirm the home screen shows the combined number of omitted entries and advises sharing the remainder in smaller batches.
- Confirm the warning remains readable when the batch contains unsupported entries and the app returns to the Library tab.
- **Status:** Manual UX regression documented; no device test is claimed. Verify sequential review, skipped count, and warning visibility on a real Android share source at the manual checkpoint.

### TC-195 — Summarize share-batch omissions after the waiting queue drains

- Keep one share batch active for review and queue another batch behind it. Include unsupported entries and at least one invalid/unreadable entry; make one of the batches exceed the 100-item limit.
- Confirm StashHive continues sequential review without presenting transient per-item SnackBars immediately before opening the next Quick Save route.
- After the last queued batch finishes, confirm one combined summary reports counts for unsupported items, items that could not be prepared and additional entries omitted by the batch limit. The message may include a maximum of three distinct safe validation hints, without provider diagnostics.
- Confirm the summary appears on the Library/home screen and that a normal batch with no skipped entries does not show an unnecessary warning.
- **Status:** Manual UX regression documented; no device test is claimed. Verify waiting-queue timing, count accuracy and feedback readability with Android share events at the manual checkpoint.

### TC-196 — Bound and de-duplicate share review summary hints

- Build a share-review summary with unsupported, invalid/unreadable and over-limit counts.
- Confirm singular/plural counts are clear, duplicate or blank validation hints are removed, no more than three distinct hints are shown, and the app-defined guidance is retained.
- **Status:** Service regression source is committed but unrun. End-to-end timing and screen-reader behavior remain covered by manual case TC-195.

### TC-197 — Suppress empty share-review summaries

- Request a share-review summary with zero unsupported, invalid and omitted entries, even when an unused validation hint is supplied.
- Confirm no summary is produced, so ordinary successful shares do not receive unnecessary error feedback.
- **Status:** Service regression source is committed but unrun. End-to-end share queue behavior remains pending the manual validation checkpoint.

### TC-198 — Release the restore navigation guard after a failed restore

- Open Backup & privacy through a pushed route, choose a valid backup and confirm the merge.
- Inject an interruption before the collection commit so the repository rolls back the staged import.
- Confirm the UI shows safe failure guidance, the existing library remains intact, raw injected diagnostics are hidden, and the restoring state clears.
- Trigger system back after the failure and confirm the route can now close; the guard must not trap the user after an error.
- **Status:** Widget regression source is committed but unrun. Verify rollback, SnackBar feedback and back navigation on web/Android at the manual validation checkpoint.

### TC-199 — Distinguish backup share result states

- Verify backup export feedback separately for `ShareResultStatus.success`, `dismissed`, and `unavailable`.
- Confirm a completed share action tells the user to verify the destination rather than promising the file was saved; a dismissed sheet advises retrying when the file was not saved; an unavailable result states that the destination outcome is unknown and recommends checking Downloads/selected destination.
- Confirm uncertain outcomes never display the older generic message that implies a destination should still be chosen after the share sheet has already closed.
- **Status:** Message-mapping regression source is committed but unrun. Platform-specific share-sheet behavior and delivery remain unverified until the manual validation checkpoint.

### TC-200 — Restore an owned snapshot of mutable decoded input

- Construct a valid decoded backup using caller-owned mutable item/collection lists, a mutable item tag list, a mutable attachment map, and a mutable attachment byte buffer.
- Pause restore after it has validated and copied those inputs but before its first persistent write.
- Mutate/clear the original caller-owned structures and replace the original attachment bytes while restore is paused.
- Release restore and confirm it imports the original validated item metadata, tags, collection assignment and exact attachment bytes; mutations made to the source objects must not alter the in-flight restore.
- **Status:** Repository regression source is committed but unrun. Verify restore snapshot memory behavior and web/Android persistence at the manual validation checkpoint.

### TC-201 — Snapshot caller-owned item tags before save writes

- Create a saved item with a mutable caller-owned tags list and pause repository save immediately before the item record write.
- Mutate and extend the original tag list while save is waiting.
- Release save and confirm the repository notifier and raw stored item record both contain the tag values validated at save start, not the later caller mutations.
- **Status:** Repository regression source is committed but unrun. Verify metadata persistence and failure rollback at the manual validation checkpoint.

### TC-202 — Wait for a replacement commit before reading attachment bytes

- Save an image with known bytes, then start replacing its attachment while pausing after the attachment payload write but before the item-record write.
- Request the same attachment through the repository while the save is paused.
- Confirm the read remains pending rather than exposing the replacement payload alongside the old item metadata.
- Release the save and confirm the read returns the new bytes only after the matching item record commits.
- **Status:** Repository regression source is committed but unrun. Verify attachment preview/share behavior on web and Android with slow storage at the manual validation checkpoint.

### TC-203 — Wait for attachment rollback before reading bytes after a failed replacement

- Save an image with known original bytes, then start replacing its payload and pause before the item-record write.
- Queue an attachment read, then release the write hook with a simulated failure so the repository restores the original bytes.
- Confirm the queued read remains pending during rollback and returns the original bytes after the failed save has completed.
- Confirm the saved item metadata and the stored attachment still match the original image.
- **Status:** Repository regression source is committed but unrun. Verify real storage-failure recovery on web and Android at the manual validation checkpoint.

### TC-204 — Distinguish a pending image read from a missing attachment

- Start an attachment replacement and pause the repository after the payload write but before the item record commits.
- Open Item Details while the repository attachment read is waiting behind the in-flight save.
- Confirm the preview shows an accessible loading status, not missing-file guidance; open the image dialog and confirm it also shows loading rather than a false missing attachment message.
- Release the save and confirm both readers leave the loading state without an uncaught framework exception.
- **Status:** Widget regression source is committed but unrun. Verify loading, missing-file and preview-error states with slow web/Android storage at the manual validation checkpoint.

### TC-205 — Reuse an image thumbnail read across unrelated rebuilds

- Create a library item with an image attachment and count repository attachment reads through the test seam.
- Render the Library, then trigger an unrelated parent rebuild without editing the saved item.
- Confirm the existing thumbnail reuses its pending/completed read future rather than adding another serialized read for the same item revision.
- **Status:** Widget regression source is committed but unrun. Review thumbnail refresh behavior after item edits and attachment replacement on web/Android at the manual checkpoint.

### TC-206 — Coalesce same-key reads without crossing queued writes

- Save an image with known original bytes and pause the first repository attachment read before storage access.
- Request a second read for the same key while the first read is pending; confirm both calls share one read operation.
- Queue a replacement write, then request another read of the same key. Confirm this later read is not attached to the old future and waits until the replacement commits.
- Release the first read and confirm both earlier callers receive the original bytes while the later caller receives the replacement bytes; confirm only two storage reads were started.
- **Status:** Repository regression source is committed but unrun. Verify shared-key thumbnails and Item Details preview behavior with slow web/Android storage at the manual validation checkpoint.

### TC-207 — Retry an attachment read after a transient failure

- Save an image with known attachment bytes and inject one unexpected failure before the first repository read.
- Confirm the first read reports the injected failure to its caller and the repository's pending-read registry is released.
- Request the same attachment again and confirm the fresh read returns the stored bytes and the read hook is called twice total.
- **Status:** Repository regression source is committed but unrun. Verify storage read errors do not leave previews or queued readers stuck on web/Android at the manual validation checkpoint.

### TC-208 — Keep synchronous item lookup aligned with the published snapshot

- Save an image with known bytes, then begin replacing the image metadata and bytes.
- Pause the repository after the raw saved-item record has been written but before the save operation finishes and refreshes the visible notifier.
- Confirm the raw storage record contains the staged title while both the public items notifier and `findById` still return the previously published item.
- Release the save and confirm `findById` returns the updated item and the attachment read returns the replacement bytes.
- **Status:** Repository regression source is committed but unrun. Verify lookups during delayed save, delete and restore operations on web and Android at the manual validation checkpoint.

### TC-209 — Keep published lookup visible during delete rollback

- Save an image with known attachment bytes and start deleting it.
- Pause deletion after the raw item record and unreferenced attachment payload have been removed but before the simulated delete failure is released.
- Confirm the raw item key is temporarily absent while the public items list and `findById` still return the last published item.
- Release the injected failure and confirm rollback restores the item record, exact attachment bytes and published lookup.
- **Status:** Repository regression source is committed but unrun. Verify lookup consistency during delete rollback and real slow-storage deletion on web and Android at the manual validation checkpoint.

### TC-210 — Keep staged restore records out of synchronous lookup

- Save an existing item, then begin restoring a backup that contains a new item and pause after the restore writes the staged item record but before the collection commit.
- Confirm raw storage contains the incoming record but `findById` returns null and the public item list does not show the staged item.
- Confirm lookups for previously published items remain stable during the pause.
- Release the restore and confirm the incoming item appears through both `findById` and the items notifier only after the restore commits.
- **Status:** Repository regression source is committed but unrun. Verify staged visibility and rollback behavior during restore on web and Android at the manual validation checkpoint.

### TC-211 — Expose repository state through read-only reactive interfaces

- Bind the public item and collection accessors to `ValueListenable` interfaces and subscribe to their changes.
- Confirm the public accessors expose wrapper objects rather than the underlying mutable `ValueNotifier` instances.
- Add a collection and save an item through the repository; confirm listeners are notified and the public snapshots contain the committed data.
- Confirm the published item and collection lists reject direct mutation.
- **Status:** Repository regression source is committed but unrun. Check widget reactivity and API compatibility during the manual validation checkpoint. No test/build result is claimed.

### TC-212 — Keep malformed backup version errors bounded

- Create a JSON backup candidate whose `formatVersion` field is a very long non-integer string.
- Confirm the codec rejects the invalid version with the short, fixed message “The backup format version is invalid.”
- Confirm the error does not echo attacker-controlled version content into an exception or UI message; unknown integer versions should still report the numeric version.
- **Status:** Codec regression source is committed but unrun. Verify malformed backup error handling with large inputs at the manual validation checkpoint.

### TC-213 — Snapshot mutable save inputs before queueing

- Start a repository save and pause it after the item record is written so a second save must wait behind it.
- Submit a second image save with caller-owned mutable tags and attachment bytes, then mutate both original inputs before releasing the first save.
- Confirm the queued second save persists the tags and byte payload as they were when its `save()` call was made, even though the caller's original lists were later changed.
- **Status:** Repository regression source is committed but unrun. Verify queued save consistency and rollback behavior at the manual validation checkpoint.

### TC-214 — Snapshot mutable restore inputs before queueing

- Start a repository save and pause it after the raw item record write so a restore request must wait behind it.
- Submit a valid `DecodedBackup` with caller-owned mutable item/tag lists, collection list, attachment map and byte buffer.
- Mutate/clear all original input collections and alter the attachment bytes while the restore remains queued.
- Release the blocking save and confirm restore uses the validated values captured at the time of the restore call, including the original tags, collection assignment and exact attachment bytes.
- **Status:** Repository regression source is committed but unrun. Verify restore input isolation and peak memory with large backups during the manual validation checkpoint.

### TC-215 — Reject oversized tags before copying the tag list

- Build a valid saved item using a test tag-list implementation whose declared size exceeds the 100-tag limit and whose element access throws if the list is traversed.
- Call item validation, backup encoding and in-memory decoded-backup validation with that item; confirm each rejects with the expected `FormatException` before iterating/copying the caller-owned tag list.
- **Status:** Codec regression source is committed but unrun. Verify oversized tag and content boundaries through repository save, backup encode and decoded-backup validation at the manual checkpoint.

### TC-216 — Reject more attachment entries than saved items

- Validate a directly constructed `DecodedBackup` with more attachment entries than saved items and confirm it receives the fixed count error before scanning or validating all payloads.
- Decode a JSON backup candidate with more attachment keys than item records; confirm decode stops at the count invariant before iterating attachment keys/base64 metadata.
- **Status:** Codec regression source is committed but unrun. Verify malformed backup limits and restore preflight at the manual validation checkpoint.

### TC-217 — Reject oversized collection lists before traversing input

- Call BackupCodec.encode with a collection list whose declared length exceeds BackupCodec.maxCollections and whose indexed element access throws.
- Confirm the encoder returns the fixed too-many-collections FormatException without reading any collection entries or constructing a combined declared/assigned collection list.
- Confirm an in-limit collection list still encodes and is normalized against item assignments as before.
- **Status:** Codec regression source is committed but unrun. Check direct encoder limits and legacy collection normalization at the manual validation checkpoint.

### TC-218 — Bound saved-item type fields before parsing

- Construct a malformed backup whose saved-item `kind` field contains a very long string. Confirm decoding rejects it using a fixed size-limit message before `SavedItem.fromMap` can create an exception containing the value.
- Construct a backup with a short but unknown kind and confirm the decoder reports a fixed invalid-type message rather than echoing the raw value.
- Call model parsing with a non-string, oversized or unknown kind and confirm it produces the same bounded error.
- Place a raw local record with an oversized kind beside a valid item; reopen the repository and confirm the malformed row is counted/skipped without hiding the valid item.
- **Status:** Regression source is committed but unrun. Verify malformed import and legacy-record recovery at the manual validation checkpoint.

### TC-219 — Bound optional backup export timestamp metadata

- Decode a valid version-1 backup whose optional `exportedAt` field is much longer than a normal timestamp. Confirm the optional metadata is normalized to an empty value while valid saved items remain available.
- Pass a directly constructed `DecodedBackup` with an overlong `exportedAt` string through restore preflight and confirm a fixed validation error is returned before any repository write.
- Confirm normal ISO timestamp values and older backups without this field remain compatible.
- **Status:** Regression source is committed but unrun. Verify malformed timestamp handling alongside the malformed-backup and restore-preflight matrix at the manual validation checkpoint.

### TC-220 — Check raw metadata lengths before normalization

- Decode a backup containing a 100,000-character whitespace-only tag, an oversized whitespace-only collection name, and an oversized attachment filename. Confirm each is rejected with its documented fixed validation error before normalization.
- Validate a directly constructed decoded backup with an oversized collection name and an attachment whose name is oversized; confirm preflight rejects it before normalization/copying.
- Call backup encoding with an oversized declared collection name and confirm the declared-name cap is applied before normalization.
- Reopen a local repository whose collection preferences include an oversized whitespace-only name. Confirm the malformed entry is skipped/counts toward recovery feedback while valid collection names remain available.
- **Status:** Regression source is committed but unrun. Verify malformed backup/local-preference recovery and storage behavior at the manual validation checkpoint.

### TC-221 — Preflight direct model fields before normalization

- Call `SavedItem.fromMap` directly with an overlong raw title and an overlong tag, without routing through the repository or backup validators.
- Confirm the factory rejects each value with fixed size-limit errors before trimming strings or iterating/copying oversized tag content.
- Confirm an ordinary valid map still round-trips and the existing legacy tag-normalization behavior for in-limit values remains supported.
- **Status:** Model regression source is committed but unrun. Validate direct model callers alongside malformed backup and raw-record recovery cases at the manual checkpoint.

### TC-222 — Bound direct URL and search helper input

- Call both URL parsing helpers directly with oversized whitespace input and confirm they return no URL before trimming or normalization.
- Call both `SavedItem.matchesQuery` and `SavedItem.matchesNormalizedQuery` with a query longer than the supported search limit and confirm they return false before trimming/lowercasing or scanning saved fields, while ordinary case-insensitive searches still work.
- **Status:** Regression source is committed but unrun. Verify the direct helper behavior alongside form-level URL validation, metadata search and large-input handling at the manual validation checkpoint.

### TC-223 — Bound recovery scans of legacy collection preferences

- Store more than 10,000 local collection preference entries containing repeated names, then reopen the repository.
- Confirm recovery inspects no more than the configured scan budget, counts duplicate/uninspected entries in the skipped-entry counter, and still restores a valid collection assignment from a saved item.
- Confirm the raw preference list is not rewritten during recovery; the app reports what it skipped rather than silently erasing legacy data.
- **Status:** Repository regression source is committed but unrun. Verify the bounded scan and recovery feedback against browser/Android local storage at the manual validation checkpoint.

### TC-224 — Sanitize invalid provider file-URI failures

- Submit a supported document share whose `file://` URI uses a non-local authority, causing platform path conversion to fail.
- Confirm the intake path returns fixed recovery guidance without exposing the provider URI or raw exception details; the item is reported as skipped and the rest of the share batch can continue.
- Confirm ordinary local file paths and local `file://` URIs still reach extension/MIME and bounded-byte validation.
- **Status:** Share-intake regression source is committed but unrun. Verify provider URI shapes and recovery summaries using real Android share sources at the manual validation checkpoint.

### TC-225 — Bound share-review summary hint processing

- Supply a summary hint longer than `maxShareReviewHintCharacters` followed by an ordinary app-owned hint. Confirm the oversized hint is skipped before trimming and the safe hint remains available in the concise summary.
- Supply an iterable with many empty hints and confirm the helper inspects no more than `maxShareReviewHintCandidates` entries before returning a summary without details.
- Confirm count summaries and the first three distinct, in-limit validation hints remain unchanged.
- **Status:** Regression source is committed but unrun. Verify share feedback remains concise after malformed/unsupported batches on Android at the manual validation checkpoint.

### TC-226 — Prevent overlapping backup export and restore UI operations

- Start a backup export and pause it after the JSON has been prepared but before the export action returns.
- Confirm the Restore action is disabled and says “Backup in progress…”. The status is exposed as a live region, and a second tap must not start the file picker.
- While a restore is committing, confirm Create backup is disabled and shows “Restore in progress…” as an announced live status.
- Release the active operation and confirm the opposite action becomes available again. The repository queue remains the data-integrity backstop; this UI guard prevents competing file picker/share-sheet flows.
- **Status:** Widget regression source is committed but unrun. Verify native share-sheet and file-picker behavior on Android and browser flows during the manual checkpoint.

### TC-227 — Prevent backup export while backup selection is pending

- Open the restore file picker and leave its future unresolved.
- Confirm the Create backup action is disabled and shows “Backup selection in progress…” as a live status. Tap the disabled state and confirm backup preparation does not begin.
- Cancel the picker and confirm Create backup becomes available again; no restore is started and existing library contents are unchanged.
- **Status:** Widget regression source is committed but unrun. Verify platform picker cancellation and state recovery on Android and web at the manual checkpoint.

### TC-228 — Release the backup JSON source before waiting on the share sheet

- Prepare a backup containing Unicode metadata and several attachment payloads, then export it using the normal share flow.
- Confirm the file exposed through the share sheet remains valid UTF-8 JSON and can be decoded with the same item metadata and attachment bytes as the prepared backup.
- Review the export path's memory lifetime: once UTF-8 bytes have been produced, the UI should drop its reference to the large JSON string before awaiting the share-sheet result.
- **Status:** Source change is committed; no memory profile or platform export was run. Check payload integrity and peak memory on web/Android during the manual validation checkpoint.

### TC-229 — Recover safely when Item Details cannot read a saved attachment

- Save a document with known attachment bytes, open Item Details, then inject an unexpected storage-read failure when the user selects “Open / share file.”
- Confirm the page shows safe retry guidance rather than a raw storage/path exception, no system share sheet is launched, and the saved record and attachment remain intact.
- Clear the fault and confirm ordinary file sharing remains available.
- **Status:** Widget regression source is committed but unrun. Verify read-failure feedback and recovery under real Android/browser storage conditions at the manual validation checkpoint.

### TC-230 — Retry an image preview after a transient attachment-read error

- Save an image, inject a single transient read error, open Item Details and choose **View image**.
- Confirm the preview shows a recoverable message and a **Retry preview** action without exposing internal storage diagnostics.
- Retry and confirm a fresh repository read occurs, the retry action disappears after the read succeeds, and the saved attachment remains intact.
- **Status:** Widget regression source is committed but unrun. Verify retry behavior and screen-reader feedback with real browser/Android storage errors at the manual validation checkpoint.

### TC-231 — Keep the local library usable when native share-stream setup fails

- On an Android-targeted app launch, inject an exception while requesting the incoming-share stream, before a stream subscription is created.
- Confirm the app remains on the local library, offers manual capture guidance, and hides raw plugin/channel diagnostics.
- Confirm startup continues without an uncaught framework exception, the screen's normal navigation remains available, and the independent launch-time intent read is still attempted even if the stream cannot start.
- **Status:** Widget regression source is committed but unrun. Verify behavior against native plugin/channel failures and normal Android share delivery at the manual validation checkpoint.

### TC-232 — Keep Quick Save open while attachment selection is pending

- Open an Image draft and pause the file-picker request before it returns.
- Confirm the in-form Back and Cancel actions are disabled and a simulated system-back action does not close the route while the picker is still pending.
- Resolve the picker as canceled, confirm the busy state clears and navigation becomes available again, then navigate back normally.
- **Status:** Widget regression source is committed but unrun. Verify native picker cancellation and route navigation on Android and supported browser/desktop platforms at the manual checkpoint.

### TC-233 — Preflight direct SavedItem serialization dimensions

- Construct a SavedItem with an overlong title and call toMap() directly, without the repository or backup codec; confirm a fixed field-limit error is raised before the map is returned.
- Repeat with an overlong tag and with more than 100 tags; confirm tag limits reject both before a copied tag list is allocated.
- Confirm ordinary toMap() output retains the existing field names and tags round-trip through SavedItem.fromMap().
- **Status:** Model regression source is committed but unrun. Validate alongside TC-221 direct model parsing and TC-222 direct helper bounds at the manual checkpoint.

### TC-234 — Bound direct SavedItem search-field processing

- Construct SavedItem instances directly with an overlong title, overlong content, one overlong tag and more than 100 tags.
- Confirm matchesQuery() and matchesNormalizedQuery() reject these invalid searchable fields before building the searchable-field list or lowercasing stored values.
- Confirm ordinary valid item search still succeeds.
- **Status:** Model regression source is committed but unrun. Verify alongside TC-221 direct model parsing, TC-222 helper input limits and TC-233 direct serialization at the manual checkpoint.

### TC-235 — Reject out-of-range timestamps in direct model parsing

- Construct raw saved-item maps whose created or updated timestamp is just outside the supported DateTime range, then call SavedItem.fromMap() directly without the repository/backup validators.
- Confirm the factory emits a fixed timestamp-range FormatException instead of constructing a model whose createdAt/updatedAt getter may throw later.
- Confirm a normal in-range map still parses and preserves both timestamps.
- **Status:** Model regression source is committed but unrun. Validate along with malformed local records, backup decoding and the shared timestamp constants at the manual checkpoint.

### TC-236 — Reject out-of-range timestamps in direct model serialization

- Construct a `SavedItem` directly with a `createdAtMs` beyond the supported maximum and another with an `updatedAtMs` below the supported minimum.
- Call `toMap()` on each object without repository or backup validation and confirm a fixed timestamp-range `FormatException` is thrown before returning a serialized map.
- Confirm a normal in-range item still serializes its timestamp values unchanged.
- **Status:** Model regression source is committed but unrun. Validate alongside TC-233 and TC-235, backup encoding and repository-save timestamp checks at the manual checkpoint.

### TC-237 — Reject out-of-range timestamps in direct date getters

- Construct a public `SavedItem` with a created timestamp above the supported maximum and another with an updated timestamp below the supported minimum.
- Read `createdAt` and `updatedAt` directly and confirm each reports the fixed timestamp-range `FormatException` rather than leaking a lower-level date-construction error.
- Confirm ordinary in-range timestamp fields remain unchanged and existing valid model behavior is preserved.
- **Status:** Model regression source is committed but unrun. Validate alongside TC-235/TC-236 and repository recovery cases at the manual checkpoint.

### TC-238 — Preserve inclusive timestamp boundaries

- Create valid saved items with both timestamps set to the minimum supported millisecond value and, separately, the maximum supported value.
- Confirm direct model serialization and parsing accept both inclusive boundaries and preserve the exact timestamp values.
- Confirm the existing TC-235–TC-237 cases still reject values one millisecond outside the range.
- **Status:** Regression source is committed but unrun. Run at the manual validation checkpoint with the model, repository and backup timestamp suites.

### TC-239 — Keep copied SavedItem tags immutable

- Call SavedItem.copyWith() with a mutable replacement tag list, mutate the caller-owned list after the call, and confirm the copied item retains the submitted snapshot.
- Call copyWith() without replacement tags on a directly constructed item with a mutable tag list, mutate the original list, and confirm the copied item remains unchanged.
- Confirm attempts to mutate the copied item tag list throw UnsupportedError.
- **Status:** Regression source is committed but unrun. Run with model round-trip, repository save snapshot and backup validation tests at the manual checkpoint.


### TC-240 — Keep synchronous lookups on the last committed item revision

- Save an existing item, then pause a replacement save after it enters the write phase but before the item record commits.
- While the save is paused, confirm findById() and the public items listenable both expose the prior title, not a staged record.
- Release the write and confirm both lookup surfaces update to the new title together.
- **Status:** Regression source is committed but unrun. Execute at the manual validation checkpoint; no CI or build was triggered.


### TC-241 — Snapshot tags at SavedItem construction

- Construct a SavedItem using a caller-owned mutable tag list, mutate that list after construction, and confirm the item retains only the original tags.
- Confirm direct mutation through the item's tags list throws UnsupportedError.
- **Status:** Regression source is committed but unrun. Run with TC-239 and the model/repository/backup regression suites at the manual checkpoint; CI remains manual-only.


### TC-242 — Reject invalid share de-duplication limits

- Construct ShareEventDeduplicator with a zero and a negative time window; confirm each construction throws ArgumentError.
- Construct ShareEventDeduplicator with zero and negative cache capacities; confirm each construction throws ArgumentError rather than failing later during cache eviction.
- Preserve control coverage for ordinary positive values and bounded-cache eviction.
- **Status:** Regression source is committed but unrun. Execute with the complete share-intake suite at the manual validation checkpoint; CI remains manual-only.

### TC-243 — Preserve Android manifest when atomic replacement fails

- Start from a valid temporary AndroidManifest.xml and simulate an operating-system replacement error after the updated manifest has been serialized.
- Confirm configure_manifest propagates the replacement error, leaves the original manifest byte-for-byte unchanged, and removes the temporary file.
- Retain coverage for malformed input, missing application/activity, MIME filters, app label, launch mode and idempotent configuration.
- **Status:** Regression source is committed but unrun. Execute the Python configurator suite at the manual validation checkpoint; CI remains manual-only.
