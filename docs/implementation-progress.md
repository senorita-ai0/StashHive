# StashHive — Implementation Progress

**As of:** 2026-10-22  
**Active phase:** Phase 3 — Platform assurance (Phase 2 sharing/build validation remains pending)  
**Owner direction:** Develop features first; run CI/builds only when manually requested.

## Previously verified (before Phase 2 changes)

The last pre-Phase-2 CI run passed dependency resolution, Dart formatting, static analysis, unit tests and the Flutter web release build. The Android debug APK later **failed** in Java compilation: GeneratedPluginRegistrant.java referenced the unavailable com.mr.flutter.plugin.filepicker.FilePickerPlugin class. See https://github.com/senorita-ai0/StashHive/actions/runs/39606162778. The declared file_picker dependency is now upgraded to 12.3.0 because the upstream package documents a fix for the 11.x/AGP 9 registration issue; this mitigation is unverified until the manual workflow is run. Historical results apply to the previous commit, not the new Phase 2 source.

## Phase 1 source

- [x] Flutter shell with Library, Search, Collections and Settings.
- [x] Saved-item model for links, notes, images and documents.
- [x] Hive CE repository for local records, attachment bytes, collections and preferences.
- [x] Save/edit form, URL validation, metadata search and item details.
- [x] User-selected image/document imports, with 15 MB per-file cap.
- [x] Favorites, collection/tag browsing, URL opening, image preview and confirmed deletion.
- [x] Versioned JSON backup/restore with validation and merge semantics.
- [x] Model and backup-codec tests.

## Phase 2 source added (verification intentionally pending)

- [x] Changed the GitHub Actions workflow to **manual-only** (workflow_dispatch). Pushes to main no longer start builds.
- [x] Added an artifact upload step to the manual workflow for the web build and Android debug APK (14-day retention, only after a successful full run).
- [x] Upgraded file_picker to 12.3.0 as a candidate fix for the previously observed AGP 9 / plugin registration issue; build verification is pending.
- [x] Added receive_sharing_intent and ShareIntake for Android shared URLs, text, images and supported documents.
- [x] Incoming content prefills Quick Save for user review; it is never saved silently.
- [x] Added bounded, three-second suppression for duplicate initial/stream share events; later deliberate re-shares are accepted after the window.
- [x] Made collection cards listen to saved-item changes so item counts refresh after edits, moves and deletes while the Collections tab stays open.
- [x] Multi-item shares now open one editable draft at a time, with an item-position cue; unsupported or unreadable entries are skipped with feedback while later entries continue. Device verification remains pending.
- [x] Added tool/configure_android_share_intents.py to configure the generated Android manifest idempotently.
- [x] Added tests for share parsing, local persistence across Hive box reopening, attachment restore with ID collision, collection deletion and manifest configuration.
- [x] Hardened backup decoding against missing/wrongly typed saved-item fields, invalid collection structures, malformed attachment metadata and unreferenced attachment payloads; assigned collection names are preserved during backup round-trips.
- [x] Expanded share-intake regression coverage for URLs embedded in prose (including punctuation and path/query strings) and the incoming-text size limit.
- [x] Updated roadmap, test plan, traceability and progress documentation.

## Not yet verified

- [ ] Run Dart analysis and unit tests after Phase 2 changes.
- [ ] Run the Python manifest configurator unit tests.
- [ ] Verify whether the file_picker 12.3.0 upgrade resolves the historical generated Android runner / FilePickerPlugin registration failure at the final build checkpoint.
- [x] Added a manual-workflow artifact step so a successful checkpoint preserves build/web and the Android debug APK for 14 days.
- [ ] Build the web release and Android debug APK after Phase 2 changes.
- [ ] Test sharing a browser URL, plain text, image and PDF/document on a real Android device.
- [ ] Validate cold-start vs warm-start share delivery and confirm one share opens one draft.
- [ ] Manually verify collection counts refresh after saving, editing, moving and deleting items without navigating away.
- [ ] Confirm manifest configuration on an actual generated Android runner.
- [ ] Accessibility and visual comparison against the seven SVG screen references.
- [ ] Run malformed-backup rejection and no-partial-restore regression tests at the manual validation checkpoint.
- [x] Added a fault-injection regression for an exception after item/attachment writes and before collection commit; source attempts best-effort cleanup and restores the previous collection preference value.
- [x] Hardened attachment edits so a failed saved-item write restores the previous attachment bytes instead of deleting the user's existing file; added a save-path fault-injection regression.
- [ ] Run restore and attachment-edit rollback regressions at the manual validation checkpoint; exercise real Hive/filesystem interruption behavior, which is not covered by in-process fault injection.

## Current limitations

- OCR/PDF text extraction is not implemented; search covers stored metadata and user-entered text.
- PDF/document content is not rendered inside StashHive; files are handed off through the platform share flow.
- Multi-item shares are presented sequentially, one editable draft per supported entry; the user explicitly saves or cancels each before the next opens.
- Android runner files are generated rather than committed. After generating them locally, run python3 tool/configure_android_share_intents.py.
- Web and Android libraries remain separate; cloud sync is not present.
- No build runs automatically. When ready for a validation checkpoint, manually run Actions → Manual Flutter validation → Run workflow.

## Next Phase 2 tasks

1. Run the manual workflow only when the owner requests validation; fix failures from actual logs.
2. Test Android share intent delivery from browsers, messaging apps and file providers.
3. Add regression cases for observed provider MIME types and share-event ordering; manually verify multi-item share save/cancel/skip behavior on Android.
4. Compare the running UI against docs/design/screens SVGs and fix layout/accessibility differences.
5. Keep OCR gated on its separate offline feasibility report.

## Restore source-review correction — 2026-10-21

A follow-up source review found two stale references to undeclared `writtenAttachments` and `writtenItems` in `restoreBackup()`. They were redundant because rollback already walks every uniquely staged record. The references have been removed to unblock Dart compilation. The manual-only workflow has not been run; formatting, analysis, tests and both platform builds remain unverified.

## Collection mutation rollback — 2026-10-21

Collection rename and deletion now stage affected item records before committing the collection list, and attempt to restore previously stored item values and collection preferences if a write fails. Added a fault-injection regression for a rename interrupted after one item has been written. Rollback is best-effort and the test is authored but not run; the manual-only workflow remains untouched.

## Item deletion integrity — 2026-10-21

Delete now snapshots the item and attachment values, then attempts best-effort rollback if deletion fails after a record or attachment may already have been removed. Attachment bytes are retained while any other raw saved-item record references the same key. Fault-injection coverage for post-attachment-delete failure and shared references has been added, but not run; manual validation remains pending.

## Save post-write failure recovery — 2026-10-21

The save path now snapshots the prior item map and attachment value before writes, and marks each write as attempted before awaiting storage. If a save fails after an item record may have been committed, it attempts to restore the original map (or remove a new record) as well as the previous attachment bytes. A fault-injection regression simulates an error after the item map write. The test has been authored but remains unrun; rollback is best-effort.

## Phase 3 — platform assurance increment (2026-10-21)

- Backup & Privacy now distinguishes storage in a browser profile from storage in the Android/device app, and gives platform-specific data-loss warnings.
- The restore action enters a busy state before opening the file picker, preventing repeated taps from starting multiple overlapping restore flows. The busy indicator exposes a live-region label for assistive technology.
- This is source-level work only. Web reload/quota behavior, keyboard/screen-reader review and platform flows remain pending manual verification; CI was not run.

## Phase 3 — text-scaling-aware card layout (2026-10-21)

- Added a shared layout metric for saved-item card height that expands with the active text scale, keeping two-line titles and metadata from competing for a fixed-height row on accessibility text sizes.
- Applied the helper to Library and Search grids and added pure unit tests for the default size, scaled sizes, the upper cap and invalid scale input.
- The source and tests are committed as authored; they have not been run. Screen-reader, mobile-width and actual large-text checks remain pending.

## Layout metric source review correction — 2026-10-21

The text-scale layout helper now explicitly converts the bounded `clamp` result to `double`, matching its declared return type. This is a source-level correction only; no Dart analyzer or tests were run.

## Phase 3 — accessible image and favorite labels (2026-10-21)

- Saved-item cards now expose the favorite marker to assistive technology with a meaningful label.
- Stored image thumbnails and the larger item-detail image expose title-based semantic labels instead of appearing as unlabeled pictures.
- Added a widget-level semantics regression test for favorite state. This is source/test work only; no test execution or screen-reader verification has been performed.

## Phase 3 — accessible Library search entry (2026-10-21)

The Library's search-shaped navigation control now exposes a button role, the label “Search your library” and the hint “Opens the Search tab.” The decorative, non-editable text field is excluded from the semantics tree so assistive technology does not announce it as an editable field. Added a widget semantics test source; tests and screen-reader verification remain unrun.


## Phase 2/3 source increments — 2026-10-22

- [x] Share intake: bounded SHA-256 event fingerprints normalize path/MIME/message fields, keep distinct context and batch ordering, clamp batch progress, trim unmatched URL punctuation, and align URL/text length limits.
- [x] Share intake: distinguish a plain word from a bare web address; reject non-web schemes and credential-bearing URLs; prefer known supported filename extensions over conflicting MIME metadata.
- [x] Android share manifest: support mixed-MIME `ACTION_SEND_MULTIPLE` through a `*/*` filter while retaining direct filters for supported single/multiple types.
- [x] Attachment persistence: validate saved-item fields through a shared save/backup validator; reject empty/invalid/missing attachment bytes; detect corrupted legacy byte lists without filtering invalid entries into a different file.
- [x] Backup/restore: add SHA-256 per attachment payload (optional when importing older v1 backups), reject empty payloads and invalid metadata, and test payload tampering/backward compatibility.
- [x] Shared attachments: preserve existing keys for metadata-only edits, allocate copy-on-write replacement keys when a preferred key is shared or occupied, and avoid deleting bytes still referenced by another raw item.
- [x] File picker: use file_picker 12.3.0's single-file `pickFile()` API; check length before lazy byte loading, and keep the post-read size guard.
- [x] MIME mappings: centralize supported image/document extension inference for both Quick Save and OS shares.
- [x] URL safety: share a strict web URL parser across Quick Save, share intake, backup validation and external launch; reject credential-bearing URLs and explicit non-web schemes.
- [x] Accessibility source: contrast-safe muted text, type badges and favorite state; semantic selected state for Quick Save kind options; wrapping kind selector for narrow or enlarged-text layouts; corresponding regression source added.
- [x] Progress/test docs updated through TSK-393 and TC-100.

## Phase 2/3 latest source increments — 2026-10-22

- [x] Strict URL parsing now separates user-entered bare-domain normalization from the strict persisted/open URL guard, rejects embedded credentials and explicit non-web schemes, and gives an inline error for overlong URLs.
- [x] Tag validation rejects empty and untrimmed tags before repository write/backup export.
- [x] New saved-item IDs and replacement attachment keys are allocated against both item IDs and attachment keys, including orphaned or still-referenced-but-missing payloads.
- [x] Local reload validates raw field types and tag bounds before model parsing, then verifies the Hive key matches the embedded item ID. It keeps parseable legacy records with unsafe URLs or missing attachments visible so safe feedback and repair remain possible; truly malformed raw shapes are skipped without crashing the rest of the library.
- [x] Added repository regression source for keeping parseable legacy records visible while skipping unknown kinds and key/ID mismatches.
- [x] Added a skipped-record counter and a Library live-region warning that explains recovery implications when malformed raw entries are not shown.
- [x] Added repository/Library widget regression source for the count and visible recovery warning.
- [x] Added a repository-level guard preventing any caller from writing replacement bytes to a key still referenced by another raw item, plus collision-safe IDs that avoid item/attachment keys and missing-payload legacy references.
- [x] Expanded item-type label contrast coverage to include unselected states on light and dark surfaces; Quick Save now chooses readable foregrounds for all four types.
- [x] Added timestamp range checks for recovered local records, revalidated decoded backup objects before restore writes, included item-only collection assignments in restore capacity checks, and kept case-only duplicate collection names in old v1 backups importable.
- [x] Applied and tested state-aware contrast for Quick Save item-kind icons in selected/unselected light/dark states.
- [x] Centralized attachment byte-list validation, including a pre-iteration length cap for oversized legacy payloads.
- [x] Bound raw local record field sizes during recovery so oversized records are skipped and counted while parseable legacy records with safe-to-display field sizes remain visible.
- [x] Added Item Details regression source for missing legacy image/document payloads and restore guidance.
- [x] Added a common 10,000-item cap enforced before new saves and restore writes, keeping local data representable in the versioned backup format.
- [x] Restore collision preflight now reserves dangling attachment-key references from raw records so imported bytes cannot silently repair or reassign another record's missing payload.
- [x] Direct repository lookups now apply the same raw type/size and box-key/embedded-ID checks as refresh, while retaining recoverable parseable legacy records.
- [x] Raw legacy created/updated timestamps are now bounded before reload/direct lookup so malformed dates do not break date-dependent UI.
- [x] Library card and Item Details favorite actions now show repair guidance when strict saves reject a recoverable but invalid legacy record.
- [x] Backup restore now uses the file_picker single-file API, rejects oversized/unknown-size backups before bulk reads, and repeats the cap check after loading bytes.
- [x] Legacy collection preferences are normalized case-insensitively and capped at 500 on reload; skipped entries share the accessible recovery warning.
- [x] Valid collection names assigned on saved items are merged into collection navigation when absent from preferences; legacy collection strings are canonicalized on read.
- [x] Repository save enforces the 500-collection limit even when a new name is introduced only by item metadata, not by Add Collection.
- [x] Restore revalidates publicly constructible decoded-backup objects and counts item-assigned collection names during capacity preflight before writes.
- [x] OS-shared file bytes are now accumulated through a capped stream reader that cancels before crossing 15 MiB, even if provider length metadata is stale.
- [x] Legacy item deserialization now trims title/URL/filename metadata and lowercases MIME type values, with model regression coverage.
- [x] Quick Save and backup restore now consume picker byte streams through the shared hard-capped reader, complementing bounded OS-share reads.
- [x] Quick Save and OS-share intake now reuse the backup codec's single attachment-byte limit instead of duplicating the 15 MiB literal.
- [x] Backup decode now rejects base64 payloads that cannot fit the remaining combined byte budget before allocating decoded attachment buffers.
- [x] Kept older version-1 backups with case-only duplicate collection labels importable; restore normalizes the names during merge.
- [x] Collection creation now rolls back preference writes when the storage future reports a late failure; a fault-injection regression covers the no-prior-key case.
- [x] Backup restore now fully validates once before showing confirmation, retains only the decoded backup for the accepted restore, and removes the second full JSON decode.
- [x] Unified backup export/decode and restore-picker limits in UTF-8 bytes, avoiding export/restore mismatch for Unicode-heavy content.
- [x] Backup decode drops successfully validated base64 strings from its temporary parsed JSON tree to reduce duplicate memory retention.
- [x] Added a narrow-width, 2× text widget regression and constrained the Library brand title to avoid fixed-row overflow.
- [x] Removed redundant attachment byte-buffer copies during share intake, Quick Save save, and backup restore staging; existing byte-integrity assertions cover these paths.
- [x] Forced-image share intents now avoid persisting a contradictory non-image MIME header; a regression covers an extensionless image with a text MIME header.
- [x] Quick Save checks picked filename presence/length before file I/O, aligning local picker behavior with attachment metadata limits.
- [x] File-share deduplication uses the same extension-first MIME result as intake, suppressing duplicates when platform MIME headers conflict with a recognized filename.
- [x] Share fingerprints canonicalize standalone URL drafts across text/URL media types and image drafts across file/image intents when their normalized target is identical.
- [x] Attachment reads now return validated Uint8List buffers used directly by image preview and file-sharing widgets, avoiding additional UI-side full-payload copies.
- [x] Backup export now reuses the UTF-8 encoder's byte list directly instead of making a second full-size `Uint8List` copy.
- [x] Backup & Privacy now repeats the skipped-record warning and requires explicit confirmation before sharing an export that omits unreadable raw records.
- [x] Backup & Privacy also warns about malformed/duplicate/over-limit collection entries that will be normalized in exports, and requires confirmation before sharing the partial/normalized backup.
- [x] Added contextual accessible names to the Item Details overflow menu and Collection row action menus; widget regressions cover discoverability and action activation.
- [x] Canonicalized legacy and newly saved item collection assignments to the existing collection spelling, preventing case-only name mismatches from hiding saved items.
- [x] Restore now persists imported item collection assignments using canonical names from the merged destination list.
- [x] Backup export now blocks legacy items assigned to collection names beyond the portable cap and explains how to repair those assignments before retrying.
- [x] Partial backups now preserve unreadable-record and legacy-collection omission counts in optional version-1 metadata so restore can warn on another device/profile.
- [x] Collection Contents now matches collection assignments case-insensitively as a fallback for legacy/in-memory casing differences.
- [x] Quick Save attachment picker now exposes one named semantic button with first-file/replacement guidance and the 15 MB limit.
- [x] Share-event canonicalization now follows each media type's effective draft fields; regressions cover equivalent text payloads and ignored file-message metadata.
- [x] Aligned tag normalization/validation across saved-item deserialization, repository writes and backup encode/decode, with case-insensitive duplicate regressions.
- [x] Incoming file shares now bound filename/MIME metadata before file I/O; regressions cover the oversize cases.
- [x] Shared save/backup validation now rejects filename/MIME metadata when no attachment key exists, with repository and export regression source.
- [x] Shared validation now rejects empty/whitespace-only notes at repository and backup boundaries, with regression source.
- [x] Shared URL/text fingerprints now ignore provider metadata not used to build those drafts, while preserving URL context and file MIME distinctions.
- [x] Saved-item deserialization normalizes case-insensitive duplicate tags; strict save/backup validation rejects such duplicates.
- [x] Shared incoming file metadata is bounded to the persisted filename/MIME limits before file I/O.
- [x] Saved-item validation rejects attachment filename/MIME values without an attachment key.
- [x] Shared validation rejects empty note content and timestamps outside the supported DateTime range; raw out-of-range legacy records are skipped and counted.
- [x] Repository save refuses replacement writes to existing orphan keys unless the key belongs to that same item's current attachment, complementing the shared-reference guard.
- [x] Repository collection creation now uses the backup codec's shared 500-collection maximum; regression source verifies the full list remains exportable at the limit.
- [x] Backup restore now preflights the merged collection count and rejects any import that would exceed the portable 500-collection cap before writing records.
- [x] Added credential-bearing URL, URL boundary, tag integrity, collision-safe ID and responsive kind-selector regression source.

## Current validation state — 2026-10-22

No tests, formatter, analyzer, Android build or web build were run for these increments. GitHub Actions remains `workflow_dispatch`-only. All new regression cases are source-authored, not passed. Phase 2 device/restore verification and Phase 3 visual, large-text, keyboard and assistive-technology checks remain open; do not start Phase 4 release-readiness work until the agreed manual validation checkpoint supplies evidence and the remaining source-level acceptance gaps have been reviewed.
