# StashHive — Implementation Progress

**As of:** 2026-10-21  
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
