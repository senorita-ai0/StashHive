# StashHive — Requirement Traceability Matrix

**Status:** Implementation in progress; Phase 2/3 source and regression tests exist, but execution and platform evidence remain pending. Do not mark a requirement DONE without supporting validation evidence.

| Requirement | Design / screen | Planned task | Test | Implementation status |
|---|---|---|---|---|
| FR-001 | SCR-001, SCR-004 | TSK-102, TSK-105 | TC-001 | IN PROGRESS — source added; build/test pending |
| FR-002 | SCR-002, SCR-004 | TSK-102, TSK-104 | TC-002 | IN PROGRESS — source added; build/test pending |
| FR-003 | SCR-004 | TSK-102, TSK-105 | TC-003 | IN PROGRESS — source added; build/test pending |
| FR-004 | SCR-001, SCR-003 | TSK-103, TSK-201 | TC-004 | IN PROGRESS — source added; build/test pending |
| FR-005 | SCR-001, SCR-003 | TSK-202 | TC-005 | IN PROGRESS — source added; build/test pending |
| FR-006 | SCR-002, SCR-004 | TSK-104 | TC-006 | IN PROGRESS — source added; build/test pending |
| FR-007 | SCR-002, SCR-004 | TSK-104 | TC-007 | IN PROGRESS — source added; build/test pending |
| FR-008 | SCR-002, SCR-004 | TSK-004, TSK-105 | TC-008 | IN PROGRESS — source added; real platform test pending |
| FR-009 | SCR-002, flow FL-002 | TSK-004, TSK-204 | TC-009 | IN PROGRESS — source added, build/device test pending |
| FR-010 | SCR-005 | TSK-203 | TC-010 | IN PROGRESS — source added; build/test pending |
| FR-011 | SCR-004 | TSK-203 | TC-011 | IN PROGRESS — source added; build/test pending |
| FR-012 | SCR-006 | TSK-006, TSK-301 | TC-012 | IN PROGRESS — codec/source added; platform export test pending |
| FR-013 | SCR-006 | TSK-006, TSK-302 | TC-013 | IN PROGRESS — codec/source added; restore tests pending |
| FR-014 | Global | TSK-102, TSK-303 | TC-007, TC-014 | NOT STARTED |
| FR-015 | SCR-006 | TSK-003, TSK-303 | TC-015 | NOT STARTED |
| FR-016 | SCR-003, SCR-004 | TSK-005, TSK-205 | TC-016 | BLOCKED pending POC |
| FR-017 | SCR-004 | TSK-203 | TC-017 | NOT STARTED |
| FR-018 | SCR-006 | TSK-304 | TC-018 | IN PROGRESS — local-only UI/source added; privacy checks pending |
| FR-019 | SCR-001, SCR-002 | Later if approved | TC-019 | NOT STARTED / Could |
| NFR-001 | Architecture / all core flows | TSK-003, TSK-304 | TC-014, TC-018 | NOT STARTED |
| NFR-002 | SCR-006 | TSK-304 | TC-018 | NOT STARTED |
| NFR-003 | SCR-006 | TSK-006, TSK-301–305 | TC-012–015 | NOT STARTED |
| NFR-004 | SCR-004 | TSK-203 | TC-006, TC-017 | NOT STARTED |
| NFR-005 | SCR-001, SCR-003 | TSK-202 | TC-005, TC-016 | NOT STARTED |
| NFR-006 | All screens | TSK-103, TSK-304 | UI/accessibility checklist | IN PROGRESS — text scaling, semantics and contrast source/tests added; execution and platform checks pending |
| NFR-007 | Search/list | TSK-003, TSK-305 | Performance benchmark | NOT STARTED |
| NFR-008 | Attachments / OCR | TSK-005, TSK-305 | Package-size benchmark | NOT STARTED |
| NFR-009 | Architecture | TSK-002, TSK-101 | Static checks/build | NOT STARTED |
| NFR-010 | Dependency register | TSK-003, TSK-403 | License review | NOT STARTED |

## Screen IDs

See `docs/design/screen-inventory.md`. The current mockup is a concept board for library, search results, and item details; it is not implemented UI and is not yet approved.


## Phase 1 note — 2026-10-21

FR-001–007, FR-010–011 and the source portion of FR-012–013 have initial implementations and unit tests; set each row to DONE only after CI/device evidence supports its acceptance criteria. Image/document import is source-only until platform tests pass. FR-009 now has Phase 2 source for supported Android shares but remains IN PROGRESS until device/build validation; FR-015 platform validation and FR-016 extraction remain blocked or not implemented as described in the implementation progress file.



## Phase 2 status — 2026-10-21

- **FR-009:** source added for supported Android shared URL/text/image/document content. Manifest configuration is scripted because the Android runner is generated. Device verification pending.
- **FR-001, FR-008, FR-012–013:** persistence and attachment/restore regression tests added. Results remain pending because CI is manual-only.


## Phase 2 update — 2026-10-21

- FR-009 includes Android share-intake source, manifest configuration and a three-second event de-duplication window; device/build validation remains pending.
- Regression tests for the new behavior are authored but not run, because the owner requested manual-only CI.

### TSK-315 — Platform-specific backup / restore interaction

- Implementation: `lib/main.dart`, `_BackupPrivacyPageState` and `_BackupCard`.
- Requirements: FR-012–015, FR-018, NFR-006.
- Behavior: browser-specific storage label and warning, duplicate restore guard from file selection through completion, live-region label on busy indicator.
- Verification: source reviewed and committed; actual web/Android behavior remains unverified until manual validation.

### TSK-316 — Library card long-title wrapping

- Implementation: `lib/main.dart`, `SavedItemTile`.
- Requirements: FR-004, NFR-006.
- Behavior: saved-item titles may occupy two lines before ellipsis, reducing premature loss of identifying text.
- Verification: source reviewed; narrow-width and large-text visual checks remain pending.

### TSK-317 — Text-scaling-aware result cards

- Implementation: `lib/ui/layout_metrics.dart`, consumed by `lib/main.dart` in Library and Search grids.
- Requirements: FR-004, FR-005, NFR-006.
- Test: `test/layout_metrics_test.dart` covers baseline, scaled, bounded and invalid text-scale values.
- Verification: authored but not executed; actual UI layout checks remain pending.

### TSK-318 — Saved-item semantic labels

- Implementation: `lib/main.dart`, `SavedItemTile`, `_ItemThumbnail`, and image detail preview.
- Requirements: FR-004, FR-011, NFR-006.
- Test: `test/accessibility_widgets_test.dart` checks favorite-state semantics.
- Verification: test source is added but unrun; actual TalkBack and web screen-reader testing remains pending.

### TSK-319 — Library search navigation semantics

- Implementation: `lib/main.dart`, `_LibraryPageState`.
- Requirements: FR-004–005, NFR-006.
- Test: `test/accessibility_widgets_test.dart` checks the semantic name and tap action.
- Verification: test source added, execution pending; keyboard and screen-reader checks remain manual.


### TSK-319 follow-up — 2026-10-21

- The Library search widget regression now verifies that semantic activation invokes the Search callback, not merely that the semantics node exposes a tap action. Semantics handles are disposed through test teardown. This is authored source only; execution and real keyboard/screen-reader checks remain pending.


### TSK-320 — Live Search result-count status — 2026-10-22

- Implementation: `lib/main.dart`, `SearchPage` result count.
- Requirements: FR-005, NFR-006.
- Behavior: result count is exposed as a live-region semantic label while preserving the visible count and suppressing duplicate child semantics.
- Test: `test/accessibility_widgets_test.dart` checks matching/no-match counts and the live-region flag.
- Verification: test source added but unrun; on-device and browser screen-reader announcement behavior remains unverified.


### TSK-321 — Contextual saved-item action labels — 2026-10-22

- Implementation: `lib/main.dart`, `SavedItemTile` overflow menu tooltip.
- Requirements: FR-004, FR-011, NFR-006.
- Behavior: each menu tooltip names the card title so several generic “Item actions” controls are easier to distinguish.
- Test: `test/accessibility_widgets_test.dart` verifies the contextual tooltip and visible menu choices.
- Verification: test source added but unrun; real screen-reader and keyboard checks remain pending.


### TSK-321 verification strengthening — 2026-10-22

- The widget regression now seeds an item, opens “View details” and checks its callback, then marks the item favorite and checks repository state. This covers actual action behavior in addition to tooltip/choice visibility.
- Test execution and platform accessibility verification remain pending.


### TSK-325 — Representative-font text scaling

- Implementation: `lib/ui/layout_metrics.dart` and Library/Search grid extents in `lib/main.dart`.
- Requirements: NFR-006 (accessibility and large-text layout).
- Test: TC-032; `test/layout_metrics_test.dart` covers factor normalization and fallback behavior.
- Verification: source and tests committed; test execution and Android/web enlarged-text visual inspection remain pending.


### TSK-326 — Multi-select share filter parity

- Implementation: `tool/configure_android_share_intents.py`.
- Requirement: FR-009 (incoming shared content).
- Test: TC-033 and `tool/test_configure_android_share_intents.py`.
- Verification: configurator and regression source committed; Python execution and Android chooser/device delivery remain pending.


### TSK-324 — Collision-resistant, bounded share fingerprints

- Implementation: `lib/services/share_intake.dart` using direct dependency `crypto` for SHA-256 of canonical ordered share data.
- Requirement: FR-009 (incoming shared content).
- Test: TC-031 in `test/share_intake_test.dart`, including batch-content boundary cases.
- Verification: source is committed; dependency resolution and test execution are pending the manual validation checkpoint.


### TSK-327 — Shared attachment backup/restore integrity

- Implementation: `lib/services/backup_codec.dart` and `LibraryRepository.restoreBackup`.
- Requirements: FR-012–013 (backup and restore), NFR-003 (storage efficiency and recovery).
- Tests: TC-034, `test/backup_codec_test.dart`, and `test/library_repository_test.dart`.
- Verification: regression source committed; execution and platform interruption checks remain pending.


### TSK-328 — Share message included in event fingerprint

- Implementation: `lib/services/share_intake.dart`, canonical SHA-256 fingerprint includes `SharedMediaFile.message`.
- Requirement: FR-009 (incoming shared content and user-supplied context).
- Test: TC-035 in `test/share_intake_test.dart`.
- Verification: source and regression committed; test and real Android delivery behavior remain unverified.


### TSK-329 — Theme-aware muted text contrast

- Implementation: `lib/main.dart`, `kMutedLight`, `kMutedDark` and `mutedTextColor`.
- Requirement: NFR-006 (accessible contrast).
- Test: TC-036 in `test/accessibility_widgets_test.dart` checks muted text against canvas and input surfaces with a 4.5:1 threshold.
- Verification: code and widget-test source committed; automated execution and full surface-by-surface manual review remain pending.


### TSK-330 — Shared URL trailing punctuation

- Implementation: `lib/services/share_intake.dart`, `_trimTrailingShareUrlPunctuation`.
- Requirement: FR-009 (shared URL/text intake).
- Test: TC-037 in `test/share_intake_test.dart`.
- Verification: source and test committed; unit execution and real Android source-app checks remain pending.


### TSK-331 — Attachment payload integrity checksums

- Implementation: `lib/services/backup_codec.dart`, SHA-256 metadata for exported attachment payloads and optional checksum verification on decode.
- Requirements: FR-012–013 (export/restore integrity).
- Test: TC-038 in `test/backup_codec_test.dart`.
- Compatibility: checksum remains optional when reading older version-1 backups; current exports always include it.
- Verification: implementation and regression source committed; tests remain pending manual validation.


### TSK-332 — Shared-text limit units

- Implementation: `lib/services/share_intake.dart`, character-count validation message.
- Requirement: FR-009 (incoming text shares).
- Test: `test/share_intake_test.dart`; asserts the 1,000,000-character error wording.
- Verification: source/test committed but not executed.


### TSK-333 — Plain text versus inferred bare URLs

- Implementation: `lib/services/share_intake.dart`, scheme-less host classification.
- Requirement: FR-009 (incoming URL/text shares).
- Test: TC-040 in `test/share_intake_test.dart`.
- Verification: source and tests committed; no unit or Android device execution claimed.


### TSK-334 — Normalize event identity before deduplication

- Implementation: `lib/services/share_intake.dart`, normalized path/MIME/message fields before SHA-256.
- Requirement: FR-009 (duplicate-free incoming-share handling).
- Test: TC-041 in `test/share_intake_test.dart`.
- Verification: source and test committed; test and Android device verification remain pending.


### TSK-335 — Mixed-MIME Android share target

- Implementation: `tool/configure_android_share_intents.py`, wildcard `SEND_MULTIPLE` filter.
- Requirement: FR-009 (multi-item incoming share).
- Test: TC-042 and `tool/test_configure_android_share_intents.py`.
- Verification: source/regression committed; Android chooser and content URI behavior remain unverified.


### TSK-336 — Item-type badge contrast

- Implementation: `lib/models/saved_item.dart` (`readableTextAccent`) and text labels in Library, Quick Save and Item Details.
- Requirement: NFR-006 (accessible contrast).
- Test: TC-043 in `test/accessibility_widgets_test.dart`.
- Verification: source and regression committed; unit execution and light/dark visual inspection remain pending.


### TSK-337 — Favorite icon contrast

- Implementation: `lib/main.dart`, `favoriteStarColor` used in Library and Item Details.
- Requirement: NFR-006 (non-text contrast and accessible state indication).
- Test: TC-044 in `test/accessibility_widgets_test.dart`.
- Verification: source and regression committed; test execution and manual theme review remain pending.


### TSK-338 — Standalone shared URL punctuation

- Implementation: `lib/services/share_intake.dart`, standalone URL path through `_trimTrailingShareUrlPunctuation`.
- Requirement: FR-009 (incoming URL/text shares).
- Test: TC-045 in `test/share_intake_test.dart`.
- Verification: source/test committed; execution and Android source-app checks remain pending.


### TSK-339 — Share-intake length limits

- Implementation: `lib/services/share_intake.dart`, URL maximum and typed-URL context validation.
- Requirement: FR-009, aligned with backup URL limits in FR-012–013.
- Test: TC-046 in `test/share_intake_test.dart`.
- Verification: source/test committed, execution pending.


### TSK-340 — Shared image/document intake regression suite

- Implementation under test: `lib/services/share_intake.dart`.
- Requirement: FR-008–009 (file import and incoming share intake).
- Test: TC-047 in `test/share_intake_test.dart`.
- Verification: tests are committed but unrun; real Android content URI permissions and persistence remain pending.


### TSK-341 — Attachment state consistency during edits

- Implementation: `lib/main.dart` Quick Save `_save`, `lib/data/library_repository.dart` `save`.
- Requirements: FR-001–003, FR-008, NFR-003 (attachments and safe cleanup).
- Test: TC-048 in `test/library_repository_test.dart`.
- Verification: implementation/test committed; unit execution and platform storage behavior remain pending.


### TSK-342 — Shared saved-item validation

- Implementation: `lib/services/backup_codec.dart` `validateSavedItem`, called by `LibraryRepository.save`, backup encode and decode; `lib/main.dart` URL input boundary.
- Requirements: FR-001–003, FR-012–013 and NFR-003 (valid save/export/restore data).
- Test: TC-049, `test/backup_codec_test.dart`, and `test/library_repository_test.dart`.
- Verification: implementation and regression source committed; execution remains pending manual validation.


### TSK-343 — Quick Save shared attachment consistency

- Implementation: `lib/main.dart`, Quick Save `_save` attachment key selection.
- Requirements: FR-001–003, FR-008 and NFR-003.
- Test: TC-050 in `test/quick_save_test.dart`.
- Verification: source and widget test committed; execution/platform checks remain pending.


### TSK-344 — Shared MIME type mapping

- Implementation: `lib/services/mime_types.dart`, called by Quick Save and `ShareIntake`.
- Requirements: FR-008–009 (local and incoming file intake).
- Test: TC-051 in `test/mime_types_test.dart` and `test/share_intake_test.dart`.
- Verification: source and tests committed; execution and platform-specific format support remain pending.


### TSK-345 — Quick Save field-limit feedback

- Implementation: `lib/main.dart`, URL normalization and tag validation.
- Requirements: FR-002, FR-005, FR-006 and FR-009 (saved URL/tag validity).
- Test: TC-052 in `test/quick_save_test.dart`.
- Verification: source and widget tests committed; execution remains pending.


### TSK-346 — Size-first file-picker intake

- Implementation: `lib/main.dart`, Quick Save `_pickAttachment`, using `FilePicker.pickFile()` and lazy `readAsBytes()`.
- Requirements: FR-008 and NFR-003 (safe attachment import and memory use).
- Test: TC-053 manual Android/web selection; automated share-intake size regression is in `test/share_intake_test.dart`.
- Verification: source committed; plugin behavior and memory usage remain unverified until the manual validation checkpoint.


### TSK-347 — Strict URL parsing before external navigation

- Implementation: `lib/services/web_url.dart`, used by Quick Save, `BackupCodec.validateSavedItem`, share parsing and Item Details.
- Requirements: FR-006, FR-017 and FR-018 (external link behavior and safety boundaries).
- Test: TC-054 in `test/web_url_test.dart`.
- Verification: source/test committed; test execution and real external-launch validation remain pending.


### TSK-348 — Empty attachment integrity

- Implementation: `LibraryRepository.save` and `BackupCodec.encode/decode`.
- Requirements: FR-001, FR-008, FR-012–013 and NFR-003.
- Test: TC-055 in `test/library_repository_test.dart` and `test/backup_codec_test.dart`.
- Verification: source/regression committed; test execution and storage-interruption recovery remain pending.


### TSK-349 — Damaged legacy attachment records

- Implementation: `LibraryRepository.readAttachment` and `createBackup`.
- Requirements: FR-011–013 and NFR-003 (attachment integrity/recovery).
- Test: TC-056 in `test/library_repository_test.dart`.
- Verification: source/test committed; unit execution and recovery workflow remain pending.


### TSK-350 — Copy-on-write attachment replacement keys

- Implementation: `LibraryRepository.attachmentKeyForReplacement` and Quick Save replacement save flow.
- Requirements: FR-008, FR-011–013, NFR-003 (preserve shared and recoverable payloads).
- Test: TC-057 in `test/library_repository_test.dart`.
- Verification: source/test committed; execution and on-platform replacement checks remain pending.


### TSK-351 — Quick Save item-kind selection semantics

- Implementation: `lib/main.dart`, `_buildKindPicker` and `_selectKind`.
- Requirement: NFR-006 (accessible controls and announced state).
- Test: TC-058 in `test/quick_save_test.dart`.
- Verification: source/test committed; execution and assistive-technology verification remain pending.


### TSK-352 — Legacy URL external-launch guard

- Implementation under test: `lib/main.dart`, Item Details `_openOrShare`, with `parseHttpUrl`.
- Requirements: FR-017–018 and NFR-006 (safe external actions and accessible feedback).
- Test: TC-059 in `test/external_navigation_test.dart`; parser unit tests are in `test/web_url_test.dart`.
- Verification: regression committed but unrun; platform launcher behavior remains pending.


### TSK-353 — MIME metadata consistency

- Implementation: `lib/services/share_intake.dart`, recognized-extension MIME resolution.
- Requirement: FR-008–009 (file intake).
- Test: TC-060 in `test/share_intake_test.dart`.
- Verification: source/test committed; execution and platform metadata behavior remain pending.


### TSK-354 — Responsive item-kind selector

- Implementation: `lib/main.dart`, Quick Save `_buildKindPicker`.
- Requirement: NFR-006 (responsive, enlarged-text accessible UI).
- Test: TC-061 in `test/quick_save_test.dart`.
- Verification: implementation/test committed; execution and Android/web visual inspection remain pending.


### TSK-355 — Strict URL entry normalization

- Implementation: `lib/services/web_url.dart`, `parseUserWebUrl`; used by Quick Save and `ShareIntake`.
- Requirements: FR-002, FR-009 and FR-017–018 (URL validity and safe external action).
- Tests: TC-062 in `test/web_url_test.dart`, `test/quick_save_test.dart`, and existing `test/share_intake_test.dart`.
- Verification: source/test committed; execution and platform link flows remain pending.


### TSK-356 — Reject embedded URL credentials

- Implementation: `lib/services/web_url.dart`, `parseHttpUrl`.
- Requirements: FR-002, FR-009, FR-017–018 (URL safety and external navigation).
- Test: TC-063 in `test/web_url_test.dart`.
- Verification: source/test committed but unrun.


### TSK-357 — Inline URL length validation

- Implementation: `lib/main.dart`, Quick Save URL `TextFormField.validator`.
- Requirements: FR-002 and FR-009 (valid web links and consistent size limits).
- Test: TC-064 in `test/quick_save_test.dart`.
- Verification: source/test committed; execution remains pending.


### TSK-358 — Saved-item tag integrity

- Implementation: `BackupCodec.validateSavedItem`, used by repository save and backup encode/decode.
- Requirements: FR-002, FR-005–006, FR-010 (consistent tags/search metadata).
- Test: TC-065 in `test/library_repository_test.dart` and `test/backup_codec_test.dart`.
- Verification: source/tests committed but unrun.


### TSK-359 — Collision-safe saved-item IDs

- Implementation: `LibraryRepository.createUniqueId`, used by Quick Save and attachment replacement-key allocation.
- Requirements: FR-001–003 and NFR-003 (prevent unintended overwrite of local records/payloads).
- Test: TC-066 in `test/library_repository_test.dart`.
- Verification: source/test committed but unrun.


### TSK-360 — Strict local record reload

- Implementation: `LibraryRepository._refreshItems` and `BackupCodec.validateSavedItemMap`.
- Requirements: FR-001–003, FR-012–013 and NFR-003 (recover from malformed local data).
- Test: TC-067 in `test/library_repository_test.dart`.
- Verification: source/test committed but unrun.


### TSK-361 — Visible recovery warning for skipped local records

- Implementation: `LibraryRepository.skippedRecordCount` / `_refreshItems`, and Library page warning in `lib/main.dart`.
- Requirements: FR-012–013 and NFR-003 (transparent recovery/data-loss handling).
- Test: TC-068 in `test/library_repository_test.dart` and `test/accessibility_widgets_test.dart`.
- Verification: source/test committed but unrun.


### TSK-362 — Repository-level shared-payload write guard

- Implementation: `LibraryRepository.save`, with `isAttachmentReferencedByOtherItem`.
- Requirements: FR-003, FR-008, FR-011–013 and NFR-003 (preserve shared attachment integrity).
- Test: TC-069 in `test/library_repository_test.dart`.
- Verification: source/test committed but unrun.


### TSK-363 — Bound raw record sizes during recovery

- Implementation: `BackupCodec.validateStoredRecordMap` used by `LibraryRepository._refreshItems`.
- Requirements: FR-001–003 and NFR-003 (robust loading of local records).
- Test: TC-070 in `test/library_repository_test.dart`.
- Verification: source/test committed but unrun.


### TSK-364 — Theme-aware Quick Save item-kind label contrast

- Implementation: `lib/main.dart`, `_buildKindPicker` label foreground selection.
- Requirement: NFR-006 (text contrast and theme support).
- Test: TC-071 in `test/accessibility_widgets_test.dart`.
- Verification: source/test committed but unrun; manual visual review remains pending.


### TSK-365 — Bounded stored attachment byte validation

- Implementation: `lib/services/attachment_bytes.dart`, used by `LibraryRepository.readAttachment`, `save` existing-key checks and `createBackup`.
- Requirements: FR-008, FR-011–013 and NFR-003 (bounded, safe attachment recovery).
- Test: TC-072 in `test/attachment_bytes_test.dart`.
- Verification: source/test committed but unrun.


### TSK-366 — Missing attachment recovery feedback

- Implementation under test: `lib/main.dart`, Item Details `_openOrShare` and image preview state.
- Requirements: FR-008, FR-011–013 and NFR-003 (recovery from missing local files).
- Test: TC-073 in `test/external_navigation_test.dart`.
- Verification: regression source committed but unrun.


### TSK-367 — Theme-aware item-kind icon contrast

- Implementation: `lib/main.dart`, Quick Save `_buildKindPicker` state-aware icon foreground.
- Requirement: NFR-006 (non-text contrast and visual state indication).
- Test: TC-074 in `test/accessibility_widgets_test.dart`.
- Verification: source/test committed but unrun.


### TSK-368 — Fingerprint effective share draft content

- Implementation: `ShareEventDeduplicator.shouldAccept` in `lib/services/share_intake.dart`.
- Requirement: FR-009 (avoid duplicate share drafts without collapsing intentional distinct context).
- Test: TC-075 in `test/share_intake_test.dart`.
- Verification: source/test committed but unrun.


### TSK-369 — Case-insensitive tag identity

- Implementation: `SavedItem.fromMap` normalization and `BackupCodec.validateSavedItem` shared by repository save/backup encode/decode.
- Requirements: FR-002, FR-005–006 and FR-010 (consistent tag metadata and retrieval).
- Test: TC-076 in `test/saved_item_test.dart`, `test/library_repository_test.dart`, and `test/backup_codec_test.dart`.
- Verification: source/tests committed but unrun.


### TSK-370 — Incoming attachment metadata bounds

- Implementation: `ShareIntake._fromFile` in `lib/services/share_intake.dart`.
- Requirements: FR-008–009 and NFR-003 (bounded file import and recoverable validation).
- Test: TC-077 in `test/share_intake_test.dart`.
- Verification: source/test committed but unrun.


### TSK-371 — Attachment metadata/key consistency

- Implementation: `BackupCodec.validateSavedItem`, shared by repository saves and backup encode/decode.
- Requirements: FR-001–003, FR-008 and FR-012–013 (consistent attachment metadata and portability).
- Test: TC-078 in `test/library_repository_test.dart` and `test/backup_codec_test.dart`.
- Verification: source/tests committed but unrun.


### TSK-372 — Non-empty note content

- Implementation: `BackupCodec.validateSavedItem`, used by repository saves and backup encode/decode.
- Requirements: FR-001–003, FR-010 and FR-012–013 (valid note capture and portable data).
- Test: TC-079 in `test/library_repository_test.dart` and `test/backup_codec_test.dart`.
- Verification: source/tests committed but unrun.


### TSK-373 — Validate saved timestamp range

- Implementation: `BackupCodec.validateStoredRecordMap` and `validateSavedItem`, used by local reload and save/backup paths.
- Requirements: FR-001–003, FR-012–013 and NFR-003 (robust local recovery and portable records).
- Test: TC-080 in `test/library_repository_test.dart` and `test/backup_codec_test.dart`.
- Verification: source/tests committed but unrun.


### TSK-374 — Guard existing orphan payloads on save

- Implementation: `LibraryRepository.save`, alongside the shared-key reference guard.
- Requirements: FR-008, FR-011–013 and NFR-003 (preserve existing/recoverable payloads).
- Test: TC-081 in `test/library_repository_test.dart`.
- Verification: source/test committed but unrun.


### TSK-375 — Collection count portability bound

- Implementation: `BackupCodec.maxCollections`, enforced by `LibraryRepository.addCollection`.
- Requirements: FR-010, FR-012–013 and NFR-003 (organizing collections and reliable backup portability).
- Test: TC-082 in `test/library_repository_test.dart`.
- Verification: source/test committed but unrun.


### TSK-376 — Preflight merged collection count during restore

- Implementation: `LibraryRepository.restoreBackup`, before staging/write phase.
- Requirements: FR-010, FR-012–013 and NFR-003 (collection organization and backup portability).
- Test: TC-083 in `test/library_repository_test.dart`.
- Verification: source/test committed but unrun.


### TSK-377 — Portable saved-item count preflight

- Implementation: `BackupCodec.validateItemCount`, used by `LibraryRepository.save` and `restoreBackup`.
- Requirements: FR-001–003, FR-012–013 and NFR-003 (portable, bounded library data).
- Test: TC-084 in `test/backup_codec_test.dart`.
- Verification: source/test committed but unrun.


### TSK-378 — Reserve dangling attachment keys during restore

- Implementation: `LibraryRepository.restoreBackup` reserves raw `attachmentKey` values as well as existing box keys before resolving ID collisions.
- Requirements: FR-008, FR-011–013 and NFR-003 (preserve attachment identity during recovery).
- Test: TC-085 in `test/library_repository_test.dart`.
- Verification: source/test committed but unrun.


### TSK-379 — Direct lookup respects stored-record validation

- Implementation: `LibraryRepository.findById`, reusing `BackupCodec.validateStoredRecordMap`.
- Requirements: FR-001–003 and NFR-003 (malformed record recovery consistency).
- Test: TC-086 in `test/library_repository_test.dart`.
- Verification: source/test committed but unrun.


### TSK-380 — Repair guidance for rejected legacy record updates

- Implementation: `lib/main.dart`, `SavedItemTile` favorite menu and `ItemDetailsPage._toggleFavorite`.
- Requirements: FR-003, FR-011–013 and NFR-003 (safe recovery actions).
- Test: TC-087 in `test/external_navigation_test.dart`.
- Verification: source/test committed but unrun.


### TSK-381 — Backup restore picker size guard

- Implementation: `lib/main.dart`, `BackupPrivacyPage._restore` using `FilePicker.pickFile()`.
- Requirements: FR-013 and NFR-003 (bounded restore and recoverable import errors).
- Test: TC-088 manual Android/web picker validation.
- Verification: source committed; provider behavior and restore integration remain unverified.


### TSK-382 — Legacy collection preference normalization

- Implementation: `LibraryRepository._refreshCollections` and `skippedCollectionCount`; Library recovery banner in `lib/main.dart`.
- Requirements: FR-010, FR-012–013 and NFR-003/NFR-006 (portable collections and recovery feedback).
- Tests: TC-089 in `test/library_repository_test.dart` and `test/accessibility_widgets_test.dart`.
- Verification: source/tests committed but unrun.


### TSK-383 — Reduce redundant attachment-buffer copies

- Implementation: `ShareIntake._fromFile`, Quick Save `_save`, and `LibraryRepository.restoreBackup`.
- Requirements: FR-008–009, FR-012–013 and NFR-003 (bounded import/restore memory and data integrity).
- Test: TC-090 references existing byte-integrity assertions in share-intake, repository and codec tests.
- Verification: source committed; byte regression execution and memory profiling remain pending.


### TSK-384 — Collection reachability from saved-item assignments

- Implementation: `LibraryRepository._refreshCollections`, save/delete refresh paths, and `SavedItem.fromMap` collection normalization.
- Requirements: FR-010, FR-012–013 and NFR-003 (consistent collection navigation and backup metadata).
- Tests: TC-091 in `test/library_repository_test.dart` and `test/saved_item_test.dart`.
- Verification: source/tests committed but unrun.


### TSK-385 — Enforce collection cap on item save

- Implementation: `LibraryRepository.save`, using the normalized collection notifier and `BackupCodec.maxCollections`.
- Requirements: FR-010, FR-012–013 and NFR-003 (collection portability consistency).
- Test: TC-092 in `test/library_repository_test.dart`.
- Verification: source/test committed but unrun.


### TSK-386 — Narrow-width Library header

- Implementation: `lib/main.dart`, Library brand row title constraint.
- Requirement: NFR-006 (responsive large-text layout).
- Test: TC-093 in `test/accessibility_widgets_test.dart`.
- Verification: source/test committed but unrun; actual device/browser visual inspection remains pending.


### TSK-387 — Forced-image MIME consistency

- Implementation: `ShareIntake._fromFile`, when handling `SharedMediaType.image`.
- Requirement: FR-008–009 (consistent incoming file classification and metadata).
- Test: TC-094 in `test/share_intake_test.dart`.
- Verification: source/test committed but unrun; device-level source metadata remains unverified.


### TSK-388 — Collection creation rollback

- Implementation: `LibraryRepository.addCollection`, with `addCollectionAfterWriteForTesting` fault-injection seam.
- Requirements: FR-010, FR-012–013 and NFR-003 (local persistence recovery).
- Test: TC-095 in `test/library_repository_test.dart`.
- Verification: source/test committed but unrun.


### TSK-389 — Single-pass backup restore validation

- Implementation: `BackupPrivacyPage._restore`, `LibraryRepository.restoreBackup` and `restoreDecodedBackup`.
- Requirements: FR-012–013 and NFR-003 (validate before mutation and limit peak memory).
- Test: TC-096 references existing cases in `test/backup_codec_test.dart` and `test/library_repository_test.dart`.
- Verification: source committed; test execution and memory profiling remain pending.


### TSK-390 — UTF-8 backup size parity

- Implementation: `BackupCodec.utf8ByteLength`, export/decode size checks and `BackupPrivacyPage._restore` using `maxBackupBytes`.
- Requirements: FR-012–013 and NFR-003 (portable backup and bounded restore memory).
- Test: TC-097 in `test/backup_codec_test.dart`.
- Verification: source/test committed but unrun.


### TSK-391 — Release parsed base64 data after decode

- Implementation: `BackupCodec.decode`, removing each successfully validated attachment's `base64` entry from the temporary JSON map.
- Requirements: FR-012–013 and NFR-003 (bounded restore memory and validated attachment integrity).
- Test: TC-098 references existing byte/checksum assertions in `test/backup_codec_test.dart` and `test/library_repository_test.dart`.
- Verification: source committed; tests and memory profile remain pending.


### TSK-392 — Picked attachment filename preflight

- Implementation: `QuickSavePage._pickAttachment` in `lib/main.dart`.
- Requirements: FR-008–009 and NFR-003 (bounded file intake and consistent metadata constraints).
- Test: TC-099 manual/mocked picker case.
- Verification: source committed; picker-specific behavior remains pending.


### TSK-393 — Effective MIME share fingerprint

- Implementation: `ShareEventDeduplicator._effectiveFileMime` in `lib/services/share_intake.dart`.
- Requirement: FR-009 (avoid duplicate incoming drafts when provider metadata differs without changing the effective draft).
- Test: TC-100 in `test/share_intake_test.dart`.
- Verification: source/test committed but unrun.


### TSK-394 — Canonical cross-type share fingerprints

- Implementation: `ShareEventDeduplicator` text/URL/file fingerprint helpers in `lib/services/share_intake.dart`.
- Requirement: FR-009 (suppress duplicate initial/stream deliveries when provider type labels differ but the effective draft is equivalent).
- Test: TC-101 in `test/share_intake_test.dart`.
- Verification: source/test committed but unrun.


### TSK-395 — Reuse validated attachment byte buffers

- Implementation: `LibraryRepository.readAttachment` and Library/Item Details/file-sharing consumers in `lib/main.dart`.
- Requirements: FR-008, FR-011–013 and NFR-003 (attachment integrity and bounded memory).
- Test: TC-102 references byte-integrity assertions in `test/library_repository_test.dart`.
- Verification: source committed; tests and memory profile remain pending.


### TSK-396 — Reuse UTF-8 encoded backup bytes

- Implementation: `BackupPrivacyPage._export` in `lib/main.dart`.
- Requirements: FR-012–013 and NFR-003 (backup integrity and bounded memory).
- Test: TC-103 references existing backup round-trip tests in `test/backup_codec_test.dart`.
- Verification: source committed; tests and profiling remain pending.


### TSK-397 — Confirm before exporting a partial readable library

- Implementation: `BackupPrivacyPage` recovery banner and `_export` confirmation in `lib/main.dart`.
- Requirements: FR-012–013 and NFR-003 (transparent recovery and backup completeness).
- Test: TC-104 in `test/accessibility_widgets_test.dart`.
- Verification: source/test committed but unrun.


### TSK-398 — Confirm collection normalization before partial backup export

- Implementation: `BackupPrivacyPage` warning banner and `_export` confirmation in `lib/main.dart`, observing both skipped counters.
- Requirements: FR-012–013 and NFR-003/NFR-006 (transparent backup completeness and accessible warnings).
- Test: TC-105 in `test/accessibility_widgets_test.dart`.
- Verification: source/test committed but unrun.


### TSK-399 — Contextual accessible names for secondary menus

- Implementation: `lib/main.dart`, Item Details overflow menu and Collection row action menu.
- Requirement: NFR-006 (accessible controls and keyboard/screen-reader usability).
- Test: TC-106 in `test/accessibility_widgets_test.dart`.
- Verification: source/test committed but unrun; assistive-technology check remains pending.


### TSK-400 — Canonical collection spelling across persistence and UI

- Implementation: `LibraryRepository._refreshCollections`, `_canonicalizeCollectionAssignment`, `findById` and `save`.
- Requirements: FR-010, FR-012–013 and NFR-003 (consistent collection navigation and backup metadata).
- Test: TC-107 in `test/library_repository_test.dart`.
- Verification: source/test committed but unrun.


### TSK-401 — Canonicalize collection spelling during restore

- Implementation: `LibraryRepository.restoreDecodedBackup`, using the merged collection-name map before staging imported records.
- Requirements: FR-010, FR-012–013 and NFR-003 (consistent portable collection assignments).
- Test: TC-108 in `test/library_repository_test.dart`.
- Verification: source/test committed but unrun.
