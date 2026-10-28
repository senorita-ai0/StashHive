# StashHive — Implementation Progress

**As of:** 2026-10-28  
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
- [x] Progress/test docs updated through TSK-417 and TC-122.

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
- [x] Collection row counts now use the same case-insensitive assignment matching as Collection Contents.
- [x] Backup export now distinguishes unreadable raw records from visible but unexportable legacy items, asks for confirmation, filters them from the portable snapshot, and carries their omission count through restore warnings.
- [x] Partial backup snapshots now cap export at 10,000 items for over-limit legacy libraries and retain all omitted items locally.
- [x] Backup encoding now rejects duplicate item identifiers so exported JSON obeys the same uniqueness rule as restore.
- [x] Backup encoding now preflights aggregate item JSON and attachment/base64 output size before allocating the final JSON string.
- [x] Repository save snapshots caller-owned mutable attachment buffers before awaiting storage, preventing post-call mutations from changing saved bytes.
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
- [x] Item Details now handles image decoder failures with a recoverable preview-unavailable message while keeping the original attachment saved/shareable.
- [x] Backup attachment decoding now avoids an immediate extra byte-buffer copy after base64 conversion; existing byte/checksum tests cover integrity.
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

## Phase 3 — Search result sorting parity (2026-10-22)

- [x] Added Search sort state and the three options already supported in Library: Recently saved, Oldest first and Title A–Z.
- [x] Kept filtering and sort operations separate from persistence; changing sort order does not mutate saved items.
- [x] Wrapped the result count/live status and sort control so they can reflow on narrow screens and at enlarged text sizes.
- [x] Added TC-121 widget regression source for all three sort modes.
- [ ] Execute TC-121 and review narrow-width/large-text layout at the manual validation checkpoint.
- [ ] Complete keyboard and screen-reader checks; no visual or assistive-technology pass is claimed.

## Phase 3 — metadata performance baseline harness (2026-10-22)

- [x] Added `tool/benchmark_library_repository.dart` with temporary Hive fixtures for 100, 1,000 and 10,000 metadata-only items.
- [x] Added `docs/performance-benchmark.md` with the deliberate run command, metric definitions, and environment-recording guidance.
- [x] Added TC-116 and linked TSK-412 to roadmap and traceability; no CI trigger or timing threshold was introduced.
- [ ] Run the harness at an owner-approved measurement checkpoint and record output plus OS/Flutter/Dart versions.
- [ ] Complete the broader storage recovery/device and browser verification; benchmark source does not replace platform tests.

## Phase 3 — expanded Unicode search coverage (2026-10-22)

- [x] Expanded model regressions to cover case-insensitive accented words, emoji, hash tokens, bracketed text and punctuation alongside existing English, Urdu-script and Roman Urdu tests.
- [x] Added TC-118 and traced it to FR-005/NFR-005; explicitly documented that this does not claim OCR or normalization-equivalence support.
- [ ] Run TC-118 at the manual validation checkpoint and review end-to-end search with Urdu-script and emoji input on supported platforms.

## Phase 2 — unique item IDs in exported backups (2026-10-22)

- [x] Added an encoder-boundary guard rejecting duplicate saved-item IDs, keeping direct encode calls consistent with decoder/restore identity validation.
- [x] Added TC-119 and traced the behavior to backup portability requirements.
- [ ] Run TC-119 at the manual validation checkpoint; no backup test execution is claimed.

## Phase 2 — portable backup size preflight (2026-10-22)

- [x] Added incremental UTF-8 byte estimation for item JSON and attachment entries before allocating their base64 strings, with a final exact-size guard retained.
- [x] Added TC-117 for the large-aggregate-metadata rejection boundary and TC-120 for multibyte/escaped metadata, base64 boundary lengths, output byte-count parity and attachment byte round-trip coverage.
- [ ] Run TC-117 and TC-120; validate over-limit export rejection plus peak-memory behavior at the manual checkpoint.

## Phase 2 — repository-owned attachment input snapshots (2026-10-22)

- [x] `LibraryRepository.save` now snapshots caller-provided bytes after validation and before its first storage await; later changes to the caller's mutable buffer cannot change the stored attachment payload.
- [x] Added TC-122 to mutate the caller buffer through the test seam during save and verify persisted bytes match the original snapshot.
- [ ] Run TC-122 at the manual validation checkpoint and verify picker/storage behavior on supported platforms.

## Phase 2 — reject unreferenced backup attachment payloads (2026-10-22)

- [x] TSK-418 rejects orphan attachment keys before base64 decoding and applies the same reference invariant to direct in-memory restore objects.
- [x] Added TC-123 for an orphan with intentionally invalid base64 and for direct `DecodedBackup` construction.
- [ ] Run TC-123 and confirm valid version-1 backups remain compatible at the manual validation checkpoint.

## Phase 3 — deterministic Library/Search sorting (2026-10-22)

- [x] TSK-419 centralizes the three sort modes and uses deterministic timestamp/title/ID tie-breakers in Library and Search.
- [x] Added TC-124 to cover tie ordering across Recently saved, Oldest first and Title A–Z.
- [ ] Run TC-124 and complete the paired widget, keyboard and assistive-technology checks.

## Phase 3 — StashTrail product-brand alignment (2026-10-22)

- [x] Updated visible Flutter copy, web install metadata, README and current product/design references to StashTrail; the Android configurator sets the generated launcher label.
- [x] Kept the `stashhive` package, `stashhive_*_v1` Hive box identifiers and the version-1 `StashHive` backup marker unchanged for existing-data compatibility.
- [x] Added TC-125 for visible Library branding and TC-126 for a version-1 backup-marker round trip.
- [x] Extended `tool/test_configure_android_share_intents.py` to assert the generated Android application label is StashTrail, including idempotent reconfiguration.
- [ ] Execute TC-125 and TC-126 at the manual validation checkpoint; tests and builds are not claimed.

## Phase 2 — attachment cleanup for unreadable records (2026-10-22)

- [x] TSK-421: deleting an unreadable legacy item now checks its raw string attachment reference and removes the payload only when no remaining raw record references it.
- [x] Added TC-127 for reclaiming an orphan payload and TC-128 to prove bytes shared with a valid item are preserved.
- [x] Added TC-129 to verify a failed delete restores both the unreadable raw record and its attachment bytes.
- [ ] Run TC-127–TC-129 during the manual validation checkpoint; rollback behavior and legacy-store recovery remain unverified on target platforms.

## Phase 3 — first-launch local-storage safety reminder (2026-10-22)

- [x] Added a one-time Library reminder that explains browser-profile storage on web and app/device storage on Android, including local data-loss and no-sync limitations.
- [x] Added **Got it** and **Backup options** actions; the latter opens Backup & privacy directly.
- [x] Persisted the acknowledgement in the existing local preferences box and added repository/widget regression source plus manual case **TC-130**.
- [ ] Run the new regressions and inspect the reminder at narrow widths, enlarged text and on both target platforms during the manual checkpoint.

## Phase 3 — recoverable collection deletion failures (2026-10-22)

- [x] Collection deletion now catches repository/storage failures and reports them through a SnackBar instead of leaking an uncaught UI exception.
- [x] Added **TC-131** fault-injection regression source to check the collection and item assignment remain intact after a failed delete.
- [ ] Run TC-131 and verify collection mutation recovery against the target storage implementations at the manual checkpoint.

## Phase 3 — recoverable deletion failures in the UI (2026-10-22)

- [x] Item Details now catches repository delete failures, keeps the details screen open and displays an error message.
- [x] Added **TC-132** fault-injection regression source to verify the item and attachment survive the simulated post-removal failure; the preceding increment added **TC-131** for collection deletion.
- [ ] Run TC-131 and TC-132 during the manual checkpoint; storage rollback is best-effort and has not been platform-verified.

## Phase 3 — platform-specific attachment storage wording (2026-10-22)

- [x] Item Details now says attachments are stored in the browser profile on web, while native builds say they are stored inside StashTrail on the device.
- [x] Added a widget regression for native attachment-location wording and manual case **TC-133** for both web and Android.
- [ ] Run the regression and inspect the platform-specific copy on real web/native builds at the manual checkpoint.

## Phase 3 — dark-mode preference write recovery (2026-10-22)

- [x] `LibraryRepository.setDarkMode` now attempts to restore the prior preference if a write reports an error after it may have committed.
- [x] The app catches persistence errors and re-syncs the visible theme to the persisted value instead of leaking an unhandled async exception.
- [x] Added repository and widget regression source plus manual case **TC-134**.
- [ ] Run TC-134 and verify theme preference persistence on web and Android at the manual checkpoint.

## Phase 3 — accurate search scope and platform wording (2026-10-22)

- [x] Settings now names collection names as searchable and uses browser-specific wording for web rather than calling every installation a device.
- [x] Added a widget regression for the native subtitle and the disclosed search fields, plus manual case **TC-135** for web wording and no-OCR/no-sync clarity.
- [ ] Run TC-135 and review the Settings wording on web and Android at the manual checkpoint.

## Phase 3 — safe user-facing operation error messages (2026-10-22)

- [x] Unexpected errors in file selection, save, item/collection deletion, backup export and restore now use actionable fallback text rather than raw plugin/storage exception details; app-defined `FormatException` guidance is retained.
- [x] Updated TC-131/TC-132 widget regression assertions so injected internal exception text must not appear to the user; added manual case **TC-136** for the wider error-path review.
- [ ] Run the regressions and review remaining startup/platform-provided messages at the manual privacy checkpoint.

## Phase 3 — privacy-safe startup failure screen (2026-10-22)

- [x] Startup failure UI no longer displays the raw storage initialization exception; it gives platform-appropriate recovery steps and explains why technical details are hidden.
- [x] Added widget regression source and manual case **TC-137**.
- [ ] Run TC-137 and review startup recovery copy on web and Android during the manual privacy checkpoint.

## Current validation state — 2026-10-28

No tests, formatter, analyzer, Android build or web build were run for the latest source increments. GitHub Actions remains `workflow_dispatch`-only. Regression cases through TC-171, TC-173–TC-186 are source-authored, not passed; TC-172 remains a manual lifecycle case. TC-116 benchmark measurements are pending. Phase 2 Android share/device and restore verification, plus Phase 3 visual, large-text, keyboard and assistive-technology checks remain open. Do not start Phase 4 release-readiness work until the agreed manual validation checkpoint supplies evidence and remaining source-level acceptance gaps have been reviewed.


## Phase 3 — accurate Search hint and traceability IDs (2026-10-23)

- [x] Updated the Search input hint to disclose collection names, matching the fields already included by the saved-item matcher and the Settings explanation.
- [x] Added TC-148 widget regression source and TSK-440 traceability.
- [x] Reassigned the duplicate second-block test IDs TC-093–TC-102 to TC-138–TC-147 and the associated duplicate task IDs TSK-386–TSK-395 to TSK-430–TSK-439, preserving the original IDs for the earlier cases.
- [x] Removed a redundant, misnumbered traceability row for attachment snapshots; the canonical entry is TSK-417 / TC-122.
- [ ] Run TC-138–TC-148 and complete the pending manual platform/accessibility checkpoint. No tests, formatter, analyzer, or builds were run for this increment.


## Phase 3 — actionable empty Search state (2026-10-23)

- [x] Search's empty state now explains when the active content-type filter has no matches instead of implying that the library has no content.
- [x] Added a clear-filter action for an unmatched type filter; if a query and filter both contribute to the empty result, the recovery action clears both.
- [x] Added TC-149 widget regression source and TSK-441 traceability; expanded the regression to cover clearing both a non-matching query and an unmatched type filter.
- [ ] Run TC-149 and review the empty state at narrow widths, enlarged text, keyboard navigation and with a screen reader. Tests/builds remain unrun.

## Phase 3 — favorite update storage-error feedback (2026-10-25)

- [x] Favorite-toggle failures now use the common safe-error helper: app-defined validation messages are retained, while unexpected storage errors show actionable local-storage/retry guidance.
- [x] Added TC-150 widget regression and TSK-442 traceability. It injects a late item-write failure and checks that diagnostic details are hidden and favorite rollback leaves the record un-favorited.
- [ ] Run TC-150 and verify favorite persistence under real browser/device storage failures at the manual checkpoint. No tests, formatter, analyzer, or builds were run for this increment.


## Phase 3 — Settings text-size control (2026-10-25)

- [x] Added System default, Large and Extra large choices to Settings, persisted in the local preferences box.
- [x] Applied the choice as an additional multiplier over the platform-provided text scaler, retaining device/browser accessibility scaling.
- [x] Added repository regression source for preference persistence and late-write rollback, plus widget regression **TC-151** for the Settings interaction and effective scale; traced as **TSK-443**.
- [ ] Run TC-151 and inspect Settings/Library at narrow widths, with enlarged device text, keyboard navigation and screen readers on web and Android. Tests, formatter, analyzer and builds remain unrun.


## Phase 3 — consistent Item Details favorite error feedback (2026-10-25)

- [x] The Item Details favorite button now uses the same safe operation-error helper and storage-specific recovery message as the Library tile.
- [x] Added widget regression **TC-152** and traceability task **TSK-444**. It injects a late favorite-write failure, checks that diagnostic details and unrelated URL/file repair advice are absent, and verifies best-effort rollback leaves the item un-favorited.
- [ ] Run TC-152 and verify favorite persistence under real browser/device storage failures at the manual checkpoint. No tests, formatter, analyzer or builds were run for this increment.

## Phase 3 — text-size preference recovery coverage (2026-10-25)

- Added TC-153 regression source for selecting **Extra large**, recreating app state using the same repository to check preference initialization, and returning to **System default**.
- Updated the test plan and traceability matrix.
- This is source-only progress. The test, analyzer, formatter, web build and Android build have not been run; CI remains manual-only.


## Product rename consistency — 2026-10-25

- Updated the app's user-facing labels and startup messages to StashHive while retaining explicit compatibility wording for importing legacy StashTrail backups.
- Updated widget test expectations and README product identity to match the renamed repository/application.
- Source and test changes are committed, but tests and builds have not been executed; validation remains at the manual checkpoint.
- Extended rename consistency to the generated Android launcher label (and its configurator regression tests), browser page title, installable web-app manifest, requirements, and roadmap. The configurator's Python tests have not been run; Android/web builds remain deferred.

## Product rename consistency follow-up — 2026-10-25

- [x] Corrected remaining user-facing backup/share validation messages and inline source comments from StashTrail to StashHive; backup validation still preserves the stable version-1 `StashHive` schema marker.
- [x] Corrected the test-plan and traceability document headings and TC-125 brand expectations to match the current StashHive product name.
- [ ] Validation remains intentionally pending: no formatter, analyzer, test suite, Python configurator tests, web build, or Android build was run. CI stays manual-only as requested.

## Product rename consistency — collection-limit recovery messages (2026-10-25)

- [x] Updated collection-cap errors during save, collection creation, and backup restore to use the current StashHive brand rather than the retired product name.
- [x] Existing repository regression cases already cover the collection-limit message shape; the expected limit wording remains unchanged.
- [ ] No tests, formatting, analysis, or platform builds were run. Manual-only CI remains unchanged.


## Phase 3 — attachment-safe backup restore rollback (2026-10-28)

- [x] Restore rollback now attempts all staged-item deletions before cleaning up attachment payloads; a payload is removed only if no raw stored item still references it.
- [x] Shared imported attachment keys are cleaned once, and visible item/collection notifiers are refreshed after best-effort rollback so they reflect persisted state if storage refuses a deletion.
- [x] Added repository regression **TC-154** and traceability task **TSK-446** for a staged-item deletion failure after a restore interruption.
- [ ] Run TC-154 and the related restore/attachment regression set at the agreed manual validation checkpoint. No tests, formatter, analyzer, web build, or Android build were run for this change; CI remains manual-only.

## Phase 3 — early acknowledgement of launch-time shares (2026-10-28)

- [x] Launch-time incoming media is now reset/acknowledged immediately after retrieval, before Quick Save can wait on a user reviewing a long-running batch.
- [x] A reset failure no longer discards media that was already fetched; delivery continues, with a possible replay acknowledged as a limitation if the plugin could not clear its stored intent.
- [x] Added two service-level regression cases and documented **TC-155** / **TSK-447**.
- [ ] Run the share-intake tests and verify app-stop/restart behavior on Android at the manual checkpoint. No tests, formatter, analyzer, or builds were run; CI remains manual-only.

## Phase 3 — preserve Quick Save content across type changes (2026-10-28)

- [x] Removed the unconditional clear of the shared Notes/content field when changing an unsaved draft's item type. Type-specific selected attachment bytes and metadata are still cleared to avoid attaching the previous file to another kind.
- [x] Added widget regression **TC-156** and traceability task **TSK-448** to guard against silent loss of user-entered text.
- [ ] Run TC-156 and verify the type-switch flow with keyboard, screen reader, and enlarged text at the manual checkpoint. No tests, formatter, analyzer, or builds were run; CI remains manual-only.

## Phase 3 — prevent attachment loss on same-kind selection (2026-10-28)

- [x] The kind-selection handler now does nothing if the requested item type is already selected, preserving a prefilled shared image/document and its metadata. Changing to a different kind still clears the old attachment selection.
- [x] Added widget regression **TC-157** and traceability task **TSK-449**, covering a shared image whose active type is tapped before saving.
- [ ] Run TC-156/TC-157 and related Quick Save tests at the manual validation checkpoint. Tests, formatting, analyzer and builds remain unrun; CI stays manual-only.

## Phase 3 — late collection-preference failure coverage (2026-10-28)

- [x] Added a collection mutation fault-injection seam after the preference write, exercising failures where the storage write may already have committed.
- [x] Added regression **TC-158** for a collection rename with multiple assigned items and verified in source assertions that item maps, visible collections and raw preferences should roll back to their prior values.
- [x] Added traceability task **TSK-451**.
- [ ] Run TC-158 and related collection mutation regressions during the manual validation checkpoint. No tests, formatting, analyzer or builds were run; CI remains manual-only.

## Phase 3 — serialize repository mutations against stale snapshots (2026-10-28)

- [x] Added a per-repository asynchronous mutation queue around item save/delete, collection add/rename/delete and decoded backup restore. An operation releases the queue even when it throws, so a failed write does not permanently block later work.
- [x] Added concurrency regression **TC-159** for two overlapping collection creation requests and traceability task **TSK-452**.
- [ ] Run TC-159 and related repository mutation/rollback tests at the manual validation checkpoint. No tests, formatting, analyzer, web build or Android build were run; CI remains manual-only.


## Phase 3 — mutation queue failure-path regression (2026-10-28)

- [x] Added repository regression **TC-160** to exercise a queued collection mutation after the preceding mutation fails after writing preferences.
- [x] The test asserts the second request waits for rollback, then leaves only its own collection in the visible list and persisted preference value.
- [x] Added traceability task **TSK-453**.
- [ ] Run TC-159/TC-160 and related mutation rollback cases at the manual validation checkpoint. No tests, formatter, analyzer, web build or Android build were run; CI remains manual-only.


## Phase 3 — serialize favorite toggles against stale reads (2026-10-28)

- [x] Moved the favorite read-and-update sequence inside the repository mutation queue. Concurrent toggles now read the latest stored item after earlier queued actions complete.
- [x] Added repository regression **TC-161** for two overlapping toggles and assertions against the visible notifier and raw persisted record.
- [x] Added traceability task **TSK-454**.
- [ ] Run TC-161 and the related favorite-update persistence/error tests at the manual validation checkpoint. No tests, formatter, analyzer, web build or Android build were run; CI remains manual-only.


## Phase 3 — serialize preference writes against late rollback (2026-10-28)

- [x] Dark-mode and text-size preference read/write/rollback sequences now enter the shared mutation queue, preventing an older failed operation from erasing a later setting.
- [x] Added regressions **TC-162** and **TC-163** and traceability tasks **TSK-455** and **TSK-456**.
- [ ] Run TC-162/TC-163 and related preference persistence tests at the manual validation checkpoint. No tests, formatter, analyzer, web build or Android build were run; CI remains manual-only.


## Phase 3 — invalidate stale Quick Save file-picker results (2026-10-28)

- [x] Quick Save now records the selected type/revision before opening the file picker, and discards results if the draft type changed before the picker, size read or byte read completes.
- [x] Prevented duplicate simultaneous attachment-picker requests and retained the existing attachment size bound.
- [x] Added widget regressions **TC-164** and **TC-165** with a delayed `PlatformFile` test double compatible with the pinned `file_picker: ^12.3.0` API; traceability tasks **TSK-457** and **TSK-458** document both stale-result cases.
- [ ] Run TC-164 and verify image/document selection on real Android plus supported web/desktop flows at the manual checkpoint. No tests, formatter, analyzer or builds were run; CI remains manual-only.


## Phase 3 — cover picker invalidation after switching back (2026-10-28)

- [x] Added a second Quick Save regression for Image → Document → Image while the original picker remains unresolved. It checks the revision token invalidates the stale result even when the current kind matches the request's original kind.
- [x] Added **TC-165** and traceability task **TSK-458**.
- [ ] Run TC-164/TC-165 and verify delayed picker behavior on real Android and supported browser/desktop platforms during the manual checkpoint. No tests, formatter, analyzer or builds were run; CI remains manual-only.


## Phase 3 — lock Quick Save during pending saves (2026-10-28)

- [x] Quick Save now disables draft editing, type changes, collection selection, attachment selection and in-form navigation while repository save is in progress.
- [x] Added a PopScope guard against system-back navigation while a save is pending; successful persistence re-enables the route pop before closing the screen.
- [x] Save now also guards against reentry and reports the busy activity as either saving or selecting a file.
- [x] Added widget regression **TC-166** and traceability task **TSK-459** for a delayed repository save, including a simulated system-back action.
- [ ] Run TC-166 and review busy-state keyboard/screen-reader behavior at the manual validation checkpoint. No tests, formatter, analyzer or builds were run; CI remains manual-only.


## Phase 3 — verify Quick Save unlocks after failed persistence (2026-10-28)

- [x] Added widget regression **TC-167** for an injected late save failure while Quick Save is in its busy state.
- [x] The regression checks rollback leaves no item, editable URL/note draft values survive, busy controls re-enable, and retry can save the original content.
- [x] Added traceability task **TSK-460**.
- [ ] Run TC-167 and test retry/error feedback under browser and Android storage failures at the manual validation checkpoint. No tests, formatter, analyzer or builds were run; CI remains manual-only.

## Phase 3 — visible attachment picker progress and retry recovery (2026-10-28)

- [x] Quick Save's attachment area now changes from the idle upload label/icon to a “Selecting file…” status and progress indicator while file selection and reading are pending; the busy state is exposed as a semantics live region for screen readers.
- [x] Added widget regression **TC-168**: a delayed provider error must clear the busy state, show safe retry guidance without leaking raw exception details, and allow a second picker attempt to save valid attachment bytes.
- [x] Added traceability task **TSK-461** and updated the test plan.
- [ ] Run TC-168 and inspect picker/byte-read progress and recovery on real Android and supported browser/desktop platforms at the manual checkpoint. No tests, formatter, analyzer, web build or Android build were run; CI remains manual-only.

## Phase 2/3 — bound incoming share processing before fingerprinting (2026-10-28)

- [x] One operating-system share event is now limited to 100 entries in original order. Larger selections show a warning explaining that remaining items should be shared in smaller batches.
- [x] Share-event fingerprinting now performs a length-only first pass over raw fields and aggregate character budget before any trimming/normalization or JSON/UTF-8 serialization. Oversized payloads (including many whitespace-only messages) bypass deduplication hashing and reach the normal validation/error path instead of allocating a large aggregate fingerprint copy.
- [x] Text intake now accepts the provider's message as the effective content when the path is empty or unused. Unsupported video shares skip path parsing, and URL/provider-path/MIME limits are checked before trim/case-normalization work.
- [x] Added regression source **TC-169** for the batch limit/order and oversized-text fingerprint bypass, plus **TC-170** for message-only text shares. Added traceability task **TSK-462**.
- [ ] Run TC-169/TC-170 and verify real source-app MIME/path fields, batch warning/order and share cancellation on a physical Android device at the manual checkpoint. No tests, formatter, analyzer, web build or Android build were run; CI remains manual-only.

## Phase 3 — make backup exports wait for repository mutations (2026-10-28)

- [x] `LibraryRepository.createBackup()` now takes a place in the shared mutation queue, so a backup cannot read old item notifier values alongside newly written attachment bytes during an in-flight edit.
- [x] Added repository regression **TC-171**: pause an attachment replacement after its item write, confirm backup waits, then decode the export and verify both metadata and bytes match the completed edit.
- [x] Added traceability task **TSK-463** and updated the test plan.
- [ ] Run TC-171 and exercise backup during concurrent saves/deletes/restores on web and Android at the manual validation checkpoint. No tests, formatter, analyzer, web build or Android build were run; CI remains manual-only.

## Documentation consistency and dependency inventory (2026-10-28)

- [x] Corrected stale StashTrail branding in the project intake, architecture, security/privacy, risk, performance, AI workflow, blueprint, assumptions and design references/mockups while preserving explicit legacy-backup compatibility wording.
- [x] Aligned the requirements document's approval status with the approved blueprint and the still-pending platform verification state.
- [x] Added `docs/dependency-register.md` with the direct `pubspec.yaml` constraints, current Pub.dev license metadata, purpose and compatibility notes; linked it from the README and traceability matrix (**TSK-464**).
- [ ] Complete the transitive license/security review after resolving and committing a dependency lockfile at the manual validation checkpoint. No package upgrades, tests, formatting, analysis or builds were run.

## Phase 3 — ignore share events received after disposal (2026-10-28)

- [x] `HomeShell._enqueueShareBatch` now returns immediately when the host state is no longer mounted, covering an event that was already in flight while the stream subscription is being canceled. The active batch completer is also tracked and released during disposal, as are batches waiting in the queue.
- [x] Added **TC-172** as a manual lifecycle scenario and traceability task **TSK-465**.
- [ ] Exercise share-stream cancellation, app stop/restart and active-batch completion on Android at the manual validation checkpoint. No tests, formatter, analyzer or builds were run; CI remains manual-only.

## Phase 2/3 — cap queued incoming share batches (2026-10-28)

- [x] Added `maxPendingIncomingShareBatches = 8` for waiting batches; the active batch is tracked independently, so repeated distinct events cannot grow the waiting queue without a limit while a user reviews prior shares.
- [x] Events arriving at queue capacity are rejected with a recoverable message to finish current shares before sending more.
- [x] Added unit regression source **TC-173** for queue admission at and beyond the configured capacity; traced as **TSK-466**.
- [ ] Run TC-173 and verify queue-full feedback, FIFO draining and teardown recovery with real Android share events. No tests, formatter, analyzer or builds were run; CI remains manual-only.

## Phase 2/3 — tolerate unusual file URIs during share fingerprinting (2026-10-28)

- [x] Duplicate-share MIME inference now treats `file://` URI-to-path conversion as best-effort and uses the bounded raw provider path if conversion throws on the current platform.
- [x] Added source regression **TC-174** for a file URI with a non-local authority and traced it to **TSK-467**.
- [ ] Run TC-174 and verify provider-specific URI handling against real Android file-source apps. No tests, formatter, analyzer, web build or Android build were run; CI remains manual-only.

## Phase 3 — preserve the newest preference choice after stale failures (2026-10-28)

- [x] Added request revisions for dark-mode and text-size preference callbacks; only the latest request is allowed to roll the visible setting back after a persistence error.
- [x] Added widget regressions **TC-175** (rapid dark-mode choices), **TC-176** (text-size choice while an older write fails), and **TC-177** (visible dropdown rollback after failed persistence), traced as **TSK-468**. The text-size form field is keyed to the effective multiplier so its internal selection resets with the parent state.
- [ ] Run TC-175/TC-176 and verify theme/text-scale state under slow or failing persistence on web and Android. No tests, formatter, analyzer or builds were run; CI remains manual-only.

## Phase 3 — expose the last backup-prepared timestamp (2026-10-28)

- [x] The repository stores the timestamp when portable backup JSON generation succeeds, while still holding the serialized snapshot operation. This prevents a queued mutation from slipping between snapshot creation and timestamp storage. It is local informational metadata and is not embedded in the backup itself.
- [x] Backup & privacy now displays “Last backup prepared” with a localized date/time and explicitly states this does not confirm the share-sheet destination saved the file. Timestamp-write failure does not block an already prepared backup from being shared.
- [x] Added repository regression **TC-178** and widget regression **TC-179**, traced as **TSK-469**.
- [ ] Run TC-178/TC-179 and verify status updates after browser/native share-sheet completion or cancellation. No tests, formatter, analyzer, web build or Android build were run; CI remains manual-only.

## Phase 3 — preserve backup export when status preference storage fails (2026-10-28)

- [x] Moved backup-prepared timestamp storage inside the same serialized repository operation that encodes the backup, preventing a queued edit from running between the snapshot and status write.
- [x] Added a fault-injection seam for a timestamp write that commits and then reports an error; backup generation treats this informational write as best-effort and rolls back to the previous value where possible.
- [x] Added repository regression **TC-180**, verifying export still returns valid JSON and prior timestamp data is restored after the injected late failure.
- [ ] Run TC-180 and validate behavior under actual browser quota/device storage failures. No tests, formatter, analyzer, web build or Android build were run; CI remains manual-only.

## Phase 3 — wait for delete rollback before backup generation (2026-10-28)

- [x] Added repository regression **TC-181** to pause an image deletion after its item record and attachment bytes have been removed, then request a backup while that delete is still in flight.
- [x] The regression injects a late delete failure and expects the queued backup to wait for repository rollback, then include the restored item metadata and exact original attachment bytes.
- [x] Added traceability task **TSK-471** and updated the test plan.
- [ ] Run TC-181 and verify delete/backup concurrency with browser and Android storage at the manual validation checkpoint. No tests, formatter, analyzer, web build or Android build were run; CI remains manual-only.

## Phase 3 — wait for interrupted restore rollback before backup generation (2026-10-28)

- [x] Added repository regression **TC-182** to stage an incoming image/attachment during restore, pause before collection commit, then request a backup while restore remains pending.
- [x] The regression injects a restore interruption and expects the queued backup to wait for rollback, then include only the original item/collection and no staged attachment payload.
- [x] Added traceability task **TSK-472** and updated the test plan.
- [ ] Run TC-182 and verify backup/restore concurrency and interruption recovery on browser and Android storage at the manual validation checkpoint. No tests, formatter, analyzer, web build or Android build were run; CI remains manual-only.

## Phase 3 — wait for save rollback before backup generation (2026-10-28)

- [x] Added repository regression **TC-183** to pause an attachment replacement after its record is written, then request a backup while the save remains pending.
- [x] The regression injects a late save failure and expects the queued backup to wait for rollback, then include the original item metadata and exact original attachment bytes.
- [x] Added traceability task **TSK-473** and updated the test plan.
- [ ] Run TC-183 and verify backup consistency after failed saves on browser and Android storage at the manual validation checkpoint. No tests, formatter, analyzer, web build or Android build were run; CI remains manual-only.

## Phase 3 — wait for collection rename before backup generation (2026-10-28)

- [x] Added repository regression **TC-184** to pause collection rename after persisted item assignments and collection preferences have been written but before visible notifiers refresh.
- [x] The regression requests a backup during that pending operation and verifies the queued export waits, then contains the renamed collection and the matching saved-item assignment.
- [x] Added traceability task **TSK-474** and updated the test plan.
- [ ] Run TC-184 and verify backup consistency during collection changes on browser and Android at the manual validation checkpoint. No tests, formatter, analyzer, web build or Android build were run; CI remains manual-only.

## Phase 2/3 — use effective text when provider path is oversized (2026-10-28)

- [x] Added repository service regression **TC-185** for a text share whose message is valid but whose unused provider path exceeds the normal text bound.
- [x] The regression checks deduplication bypasses fingerprint construction for oversized provider metadata while intake still constructs the note from the effective message.
- [x] Added traceability task **TSK-475** and updated the test plan.
- [ ] Run TC-185 and confirm provider-field behavior with browser-independent Android source apps at the manual checkpoint. No tests, formatter, analyzer, web build or Android build were run; CI remains manual-only.

## Phase 3 — attachment size lookup failure recovery (2026-10-28)

- [x] Added widget regression **TC-186** for a picked attachment whose `length()` call fails with an unexpected provider error.
- [x] The regression expects Quick Save to hide provider details, exit its busy state, preserve the draft, allow a second selection and save the original bytes of the successful retry.
- [x] Added traceability task **TSK-476** and updated the test plan.
- [ ] Run TC-186 and verify size metadata/read failures on actual Android and supported browser/desktop pickers at the manual checkpoint. No tests, formatter, analyzer, web build or Android build were run; CI remains manual-only.

## Phase 3 — recover from attachment byte-stream failures (2026-10-28)

- [x] Added Quick Save widget regression **TC-187** for a provider that reports file length successfully but throws while emitting the file's byte stream.
- [x] The regression checks that raw provider details stay hidden, the busy state clears, no item is created by the failed read, and a second valid selection can be saved with exact bytes.
- [x] Added traceability task **TSK-477** and updated the test plan.
- [ ] Run TC-187 and verify partial-stream/provider failure recovery on Android and supported browser/desktop platforms at the manual validation checkpoint. No tests, formatter, analyzer, web build or Android build were run; CI remains manual-only.

