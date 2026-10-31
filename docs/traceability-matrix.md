# StashHive — Requirement Traceability Matrix

**Status:** Implementation in progress; Phase 2/3 source and regression tests exist, but execution and platform evidence remain pending. Do not mark a requirement DONE without supporting validation evidence.

| Requirement | Design / screen | Planned task | Test | Implementation status |
|---|---|---|---|---|
| FR-001 | SCR-001, SCR-004 | TSK-102, TSK-105, TSK-520, TSK-526, TSK-528 | TC-001, TC-233, TC-239, TC-241 | IN PROGRESS — supported saved-item types, bounded serialization, immutable copyWith snapshots and constructor-level tag snapshots are source-covered; build/test pending |
| FR-002 | SCR-002, SCR-004 | TSK-102, TSK-104, TSK-473, TSK-478, TSK-490, TSK-496, TSK-499, TSK-501, TSK-503, TSK-522, TSK-523, TSK-524, TSK-525, TSK-526, TSK-527, TSK-528 | TC-002, TC-183, TC-188, TC-201, TC-208, TC-211, TC-213, TC-215, TC-235, TC-236, TC-237, TC-238, TC-239, TC-240, TC-241 | IN PROGRESS — URL/tag input bounds, pre-queue input snapshots, published item lookup, read-only state access, immutable model copy and constructor snapshots, committed-revision lookup regression and timestamp parsing/serialization/access bounds are source-covered; build/test pending |
| FR-003 | SCR-004 | TSK-102, TSK-105, TSK-424, TSK-497 | TC-003, TC-132, TC-209 | IN PROGRESS — delete failure feedback and stable published lookup during delete rollback are source-covered; rollback/platform validation pending |
| FR-004 | SCR-001, SCR-003, SCR-004 | TSK-103, TSK-201, TSK-416, TSK-444, TSK-531 | TC-004, TC-121, TC-152, TC-244 | IN PROGRESS — browse/filter/sort source and shared premium page headers/empty state are integrated; widget execution and Android/web visual review pending |
| FR-005 | SCR-001, SCR-003, SCR-006 | TSK-202, TSK-414, TSK-427, TSK-479, TSK-510, TSK-521 | TC-005, TC-118, TC-135, TC-189, TC-222, TC-234 | IN PROGRESS — search normalizes once and bounds both oversized query input and stored searchable field dimensions; Unicode metadata search remains source-covered, execution/platform review pending |
| FR-006 | SCR-002, SCR-004 | TSK-104, TSK-510 | TC-006, TC-222 | IN PROGRESS — URL parsing rejects over-limit helper input before normalization; build/test pending |
| FR-007 | SCR-002, SCR-004 | TSK-104 | TC-007 | IN PROGRESS — source added; build/test pending |
| FR-008 | SCR-002, SCR-004 | TSK-004, TSK-105, TSK-417, TSK-476, TSK-477, TSK-491, TSK-493, TSK-519 , TSK-529, TSK-530| TC-008, TC-122, TC-186, TC-187, TC-202, TC-203, TC-205, TC-232 , TC-242, TC-243| IN PROGRESS — bounded attachment reads, retry recovery, mutation-consistent reads, thumbnail future reuse and navigation safety while picking are source-covered; platform validation pending Share de-duplication constructor bounds and atomic Android manifest replacement are now source-covered; execution/platform validation pending|
| FR-009 | SCR-002, flow FL-002 | TSK-004, TSK-204, TSK-462, TSK-465, TSK-466, TSK-467, TSK-475, TSK-481, TSK-484, TSK-485, TSK-486, TSK-512, TSK-513, TSK-518 | TC-009, TC-169, TC-170, TC-172, TC-173, TC-174, TC-185, TC-191, TC-194, TC-195, TC-196, TC-197, TC-224, TC-225, TC-231 | IN PROGRESS — source bounds batch/fingerprint/queue work, summary-hint processing and count-limits, sanitizes malformed file-URI failures, and retains manual/cold-start fallback when live stream setup fails; Android build/device test pending |
| FR-010 | SCR-005 | TSK-203, TSK-423, TSK-474, TSK-499, TSK-511 | TC-010, TC-131, TC-184, TC-211, TC-223 | IN PROGRESS — collection UI reports deletion failures, public state is read-only, and legacy preference recovery bounds scan work while preserving item assignments; rollback/test validation pending |
| FR-011 | SCR-004 | TSK-203, TSK-491, TSK-492, TSK-493, TSK-516, TSK-517 | TC-011, TC-202, TC-203, TC-204, TC-205, TC-229, TC-230 | IN PROGRESS — attachment reads wait for commit/rollback, Item Details handles file-share read failures, and image previews support accessible retry after transient read errors; execution/platform review pending |
| FR-012 | SCR-006 | TSK-006, TSK-301, TSK-413, TSK-415, TSK-463, TSK-469, TSK-471, TSK-472, TSK-473, TSK-474, TSK-488, TSK-505, TSK-507, TSK-508, TSK-509, TSK-514 | TC-012, TC-117, TC-119, TC-120, TC-171, TC-178, TC-179, TC-180, TC-181, TC-182, TC-183, TC-184, TC-199, TC-217, TC-219, TC-220, TC-221, TC-226, TC-227 | IN PROGRESS — bounded-size source, mutation-consistent snapshots, truthful backup preparation/share-outcome feedback, early count validation and raw metadata size checks before normalization are source-covered; execution and platform export pending |
| FR-013 | SCR-006 | TSK-006, TSK-302, TSK-413, TSK-415, TSK-472, TSK-480, TSK-482, TSK-483, TSK-487, TSK-489, TSK-498, TSK-500, TSK-502, TSK-503, TSK-504, TSK-505, TSK-506, TSK-507, TSK-508, TSK-509, TSK-514 | TC-013, TC-117, TC-119, TC-120, TC-182, TC-190, TC-192, TC-193, TC-198, TC-200, TC-210, TC-212, TC-214, TC-215, TC-216, TC-217, TC-218, TC-219, TC-220, TC-221, TC-226, TC-227 | IN PROGRESS — codec/source, restore rollback and snapshot isolation, staged-record lookup, bounded malformed metadata feedback, early tag/collection validation and pre-normalization size checks are source-covered; validation pending |
| FR-014 | Global | TSK-102, TSK-303 | TC-007, TC-014 | IN PROGRESS — local-first flows are implemented in source; offline/restart tests pending |
| FR-015 | SCR-006, SCR-001, SCR-004 | TSK-003, TSK-303, TSK-422, TSK-425 | TC-015, TC-130, TC-133 | IN PROGRESS — storage reminders and platform-specific attachment copy added; browser restart/platform review pending |
| FR-016 | SCR-003, SCR-004 | TSK-005, TSK-205, TSK-542 | TC-016, TC-262, tool/pdf_text_extraction_poc/test/pdf_text_probe_test.dart | BLOCKED — isolated selectable-text PDF probe source added but unrun; OCR, offline runtime and size/language feasibility still unproven |
| FR-017 | SCR-004 | TSK-203 | TC-017 | IN PROGRESS — URLs remain bookmarks without page scraping/capture; acceptance check pending |
| FR-018 | SCR-006, SCR-004 | TSK-304, TSK-428, TSK-429, TSK-444 | TC-018, TC-136, TC-137, TC-152 | IN PROGRESS — safe error copy and HTTP/HTTPS-only external launching are source-covered; initial Dart source scan found no direct diagnostic logging calls, while merged-manifest, plugin-permission and network review remain pending |
| FR-019 | SCR-001, SCR-002 | SH-001 / TSK-533 | TC-019, TC-246, duplicate_detector_test.dart, quick_save_test.dart | IN PROGRESS — link-only normalized duplicate review is source implemented; tests and platform verification pending |
| FR-022 | SCR-002, SCR-003 | SH-002 / TSK-534 | TC-247, TC-248, TC-249, search_filters_test.dart, search_filters_widget_test.dart | IN PROGRESS — local combined filters and saved preset storage/UI are source implemented; execution pending |
| FR-023 | SCR-004 | SH-010 / TSK-536 / TSK-543 | TC-256, TC-263, saved_item_test.dart, quick_save_test.dart, rediscovery_test.dart, rediscovery_widget_test.dart | IN PROGRESS — status/progress and local 14-day Rediscover selection are source-covered; regression execution and platform verification pending |
| FR-024 | SCR-004 | SH-006 / TSK-537, TSK-544–TSK-548 | TC-257, TC-264–TC-268, TC-280–TC-299, annotations_widget_test.dart, article_reader_* tests | IN PROGRESS — local annotations, temporary Reader, selectable quotes, bounded native fetch, conservative re-anchoring, widget filtering, balanced semantic containers, block layout and quote-aware malformed-tag/declaration handling are source implemented; tests and Android/web verification pending |
| FR-025 | SCR-002, SCR-007 | SH-008 / TSK-538 | TC-258, smart_tag_rules_test.dart, smart_tag_rules_widget_test.dart, quick_save_test.dart, library_repository_test.dart | IN PROGRESS — local phrase/tag rules, preference persistence, Settings management and review-before-add Quick Save chips are source implemented; tests/platform verification pending |
| FR-026 | SCR-004 | SH-009 / TSK-539 | TC-259, link_health_test.dart, accessibility_widgets_test.dart, library_repository_test.dart | IN PROGRESS — explicit Android-only network check with local result persistence and browser limitation messaging is source implemented; regression execution/platform verification pending |
| NFR-001 | Architecture / all core flows | TSK-003, TSK-304 | TC-014, TC-018 | IN PROGRESS — no backend/account integration in core source; offline and network inspection pending |
| NFR-002 | SCR-006, SCR-004 | TSK-304, TSK-428, TSK-429, TSK-444, TSK-500, TSK-517, TSK-518 | TC-018, TC-136, TC-137, TC-152, TC-212, TC-230, TC-231 | IN PROGRESS — startup, attachment preview and share-stream errors give safe feedback without exposing raw diagnostics; malformed backup version errors avoid echoing untrusted field content; source-level logging scan found no direct diagnostic calls, but platform permission/network review remains pending |
| NFR-003 | SCR-006, SCR-004 | TSK-006, TSK-301–305, TSK-413, TSK-415, TSK-417, TSK-426, TSK-444, TSK-482, TSK-483, TSK-487, TSK-488, TSK-489, TSK-490, TSK-491, TSK-493, TSK-496, TSK-497, TSK-498, TSK-499, TSK-500, TSK-501, TSK-502, TSK-503, TSK-504, TSK-517, TSK-518, TSK-519, TSK-520, TSK-521, TSK-522 , TSK-529, TSK-530| TC-012–015, TC-117, TC-120, TC-122, TC-134, TC-152, TC-192, TC-193, TC-198, TC-199, TC-200, TC-201, TC-202, TC-203, TC-205, TC-208–TC-216, TC-230–TC-235 , TC-242, TC-243| IN PROGRESS — bounded backups, model serialization and model search field processing, attachment entry counts, pre-queue owned inputs, attachment-read consistency, published lookup visibility, read-only state, bounded malformed-input errors, recoverable image/share failures and navigation guards during pending file selection are source-covered; execution/platform verification pending; share de-duplication arguments fail safely at runtime and Android manifest updates are atomic; execution/platform verification pending|
| NFR-004 | SCR-004, SCR-006 | TSK-203, TSK-425, TSK-427 | TC-006, TC-017, TC-133, TC-135 | IN PROGRESS — platform-specific local-storage/search copy added; end-to-end wording review pending |
| NFR-005 | SCR-001, SCR-003 | TSK-202, TSK-414 | TC-005, TC-016, TC-118 | IN PROGRESS — English/Urdu/Roman Urdu plus emoji/accent/punctuation source tests added; execution pending |
| NFR-006 | All screens | TSK-103, TSK-304, TSK-443, TSK-468, TSK-484, TSK-485, TSK-486, TSK-487, TSK-492, TSK-517, TSK-518, TSK-519, TSK-531 | UI/accessibility checklist, TC-151, TC-175, TC-176, TC-177, TC-194–TC-198, TC-204, TC-230–TC-232, TC-244 | IN PROGRESS — text scaling and busy/error semantics remain source-covered; shared premium components expose consistent headings, empty states and 44+ dp icon-chip sizing. Widget execution, keyboard/screen-reader review and Android/web visual checks remain pending |
| NFR-007 | Search/list | TSK-003, TSK-305, TSK-412, TSK-479, TSK-493 | TC-116, TC-189, TC-205 / Performance baseline | IN PROGRESS — non-gating harness, bounded-query source and thumbnail read reuse are added; measurements pending |
| NFR-008 | Attachments / OCR | TSK-005, TSK-305 | Package-size benchmark | NOT STARTED |
| NFR-009 | Architecture | TSK-002, TSK-101, TSK-532 | Static checks/build, TC-245 | IN PROGRESS — Flutter 3.47.2/JDK 27 and generated Android Gradle/Kotlin/SDK/JVM baseline are source-pinned; toolchain version capture, tests and platform builds remain pending |
| NFR-010 | Dependency register | TSK-003, TSK-403, TSK-464 | License/dependency review | IN PROGRESS — direct constraints and package license metadata recorded; transitive audit and lockfile resolution remain pending |

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


### TSK-405 — Repair gate for overflow collection assignments

- Implementation: `LibraryRepository.unrepresentedCollectionAssignmentCount` and `createBackup`; `BackupPrivacyPage._export` in `lib/main.dart`.
- Requirements: FR-010, FR-012–013 and NFR-003 (portable backups and transparent recovery).
- Test: TC-109 in `test/library_repository_test.dart` and `test/accessibility_widgets_test.dart`.
- Verification: source/tests committed but unrun.


### TSK-406 — Carry partial-backup omission counts through restore

- Implementation: `BackupCodec.encode/decode`, `LibraryRepository.createBackup`, and `BackupPrivacyPage._restore`.
- Requirements: FR-012–013 and NFR-003 (transparent backup completeness and recovery).
- Test: TC-110 in `test/backup_codec_test.dart` and `test/library_repository_test.dart`.
- Verification: source/tests committed but unrun; restore interaction remains unverified on device.


### TSK-407 — Case-insensitive Collection Contents lookup

- Implementation: `CollectionContentsPage` filter in `lib/main.dart`.
- Requirements: FR-010–011 and NFR-003 (consistent collection retrieval across legacy data).
- Test: TC-111 in `test/accessibility_widgets_test.dart`.
- Verification: source/test committed but unrun.


### TSK-408 — Accessible attachment picker control

- Implementation: `lib/main.dart`, Quick Save `_buildAttachmentPicker`.
- Requirement: NFR-006 (named, usable controls for assistive technology).
- Test: TC-112 in `test/accessibility_widgets_test.dart`.
- Verification: source/test committed but unrun; real assistive-technology check remains pending.


### TSK-430 — Legacy timestamp range validation

- Implementation: `BackupCodec.validateStoredRecordMap`, reused by `LibraryRepository._refreshItems` and `findById`.
- Requirements: FR-001–003 and NFR-003 (safe recovery from malformed local records).
- Test: TC-138 in `test/library_repository_test.dart`.
- Verification: source/test committed but unrun.


### TSK-431 — Validate decoded backup objects before restore writes

- Implementation: `BackupCodec.validateDecodedBackup` called by `LibraryRepository.restoreDecodedBackup`; item-assigned collections participate in merge/capacity preflight.
- Requirements: FR-010, FR-012–013 and NFR-003 (restore integrity and no partial writes from invalid inputs).
- Test: TC-139 in `test/backup_codec_test.dart` and `test/library_repository_test.dart`.
- Verification: source/tests committed but unrun.


### TSK-432 — Preserve legacy collection compatibility

- Implementation: `BackupCodec.validateDecodedBackup` accepts valid collection strings without requiring case-insensitive uniqueness; `LibraryRepository.restoreDecodedBackup` merges them case-insensitively.
- Requirements: FR-010, FR-012–013 (portable collection metadata and backward-compatible restore).
- Test: TC-140 in `test/backup_codec_test.dart`.
- Verification: source/test committed but unrun.


### TSK-433 — Bound streamed shared-file reads

- Implementation: `lib/services/bounded_bytes_reader.dart`, used by `ShareIntake._fromFile`.
- Requirements: FR-008–009 and NFR-003 (safe attachment import and bounded memory).
- Test: TC-141 in `test/attachment_bytes_test.dart`, alongside file intake boundaries in `test/share_intake_test.dart`.
- Verification: source/test committed but unrun; device/provider behavior remains pending.


### TSK-434 — Normalize legacy item metadata on load

- Implementation: `SavedItem.fromMap`.
- Requirements: FR-001–003, FR-008–009 and FR-012–013 (consistent metadata across load/edit/share/backup).
- Test: TC-142 in `test/saved_item_test.dart`.
- Verification: source/test committed but unrun.


### TSK-435 — Bound file-picker reads while streaming

- Implementation: `lib/main.dart`, Quick Save and `BackupPrivacyPage._restore`; common reader in `lib/services/bounded_bytes_reader.dart`.
- Requirements: FR-008, FR-013 and NFR-003 (bounded attachment/backup memory).
- Test: TC-143 and helper regressions in `test/attachment_bytes_test.dart`.
- Verification: source/test committed but unrun; Android/web provider memory behavior remains pending.


### TSK-436 — Centralized attachment size limit

- Implementation: `BackupCodec.maxAttachmentBytes` referenced by Quick Save and `ShareIntake`.
- Requirements: FR-008–009, FR-012–013 and NFR-003 (consistent bounded import/export).
- Test: TC-144 plus stream-boundary tests in `test/attachment_bytes_test.dart`.
- Verification: source committed; test execution remains pending.


### TSK-437 — Preflight combined attachment size before base64 allocation

- Implementation: `BackupCodec.maxBase64CharactersForDecodedBytes`, used by `BackupCodec.decode` before decoding each attachment.
- Requirements: FR-012–013 and NFR-003 (bounded backup import memory).
- Test: TC-145 in `test/backup_codec_test.dart`.
- Verification: source/test committed but unrun; memory profile pending.


### TSK-438 — Image preview decode failure handling

- Implementation: `lib/main.dart`, Item Details full-size `Image.memory.errorBuilder`.
- Requirements: FR-008–009 and NFR-003/NFR-006 (retain attachments and communicate preview limitations accessibly).
- Test: TC-146 in `test/external_navigation_test.dart`.
- Verification: source/test committed but unrun; real platform codec coverage remains pending.


### TSK-439 — Reduce attachment buffer copies during decode

- Implementation: `BackupCodec.decode`, retaining the typed result from `base64Decode`.
- Requirements: FR-012–013 and NFR-003 (bounded memory with data integrity).
- Test: TC-147 references existing round-trip/checksum assertions in `test/backup_codec_test.dart`.
- Verification: source committed; tests and memory profiling remain pending.


### TSK-409 — Case-insensitive collection row counts

- Implementation: `lib/main.dart`, `CollectionsPage` count calculation.
- Requirements: FR-010–011 and NFR-003 (consistent collection metadata and counts).
- Test: TC-113 in `test/accessibility_widgets_test.dart`.
- Verification: source/test committed but unrun.


### TSK-416 — Search result sorting parity

- Implementation: `lib/main.dart`, `_SearchPageState` filtering and sort control.
- Requirements: FR-004 and SCR-003 (consistent retrieval controls, result count and sorting).
- Test: TC-121 in `test/accessibility_widgets_test.dart`.
- Verification: source/test committed but unrun; responsive visual and screen-reader checks remain pending.


### TSK-410 — Partial backup of unexportable legacy items

- Implementation: `LibraryRepository._buildBackupSnapshot` / `unexportableRecordCount`, `BackupCodec` optional omission metadata, and `BackupPrivacyPage._export/_restore`.
- Requirements: FR-012–013 and NFR-003 (transparent backup completeness and local data preservation).
- Tests: TC-114 in `test/library_repository_test.dart`, `test/backup_codec_test.dart`, and `test/accessibility_widgets_test.dart`.
- Verification: source/tests committed but unrun.


### TSK-412 — Metadata-only performance baseline harness

- Implementation: `tool/benchmark_library_repository.dart`; run procedure in `docs/performance-benchmark.md`.
- Requirements: NFR-007 (measured baseline for realistic local-library sizes), with NFR-003 platform/recovery verification still tracked separately.
- Test/measurement: TC-116 in `docs/test-plan.md`; execute deliberately on a representative machine and record environment details with JSON output.
- Verification: harness is source only; no benchmark measurements have been run and no performance pass is claimed.


### TSK-411 — Partial export within the portable item cap

- Implementation: `LibraryRepository._buildBackupSnapshot` and `unrepresentedCollectionAssignmentCount`.
- Requirements: FR-012–013 and NFR-003 (portable bounded backups without local data deletion).
- Test: TC-115 in `test/library_repository_test.dart`.
- Verification: source/test committed but unrun.


### TSK-414 — Expanded Unicode search coverage

- Implementation: model-level `SavedItem.matchesQuery` behavior exercised by `test/saved_item_test.dart`.
- Requirements: FR-005 and NFR-005 (preserve and find user-entered text across English, Urdu-script, Roman Urdu, emoji, accents and punctuation).
- Test: TC-118 in `test/saved_item_test.dart`.
- Verification: regression source committed but unrun; no OCR or canonical Unicode normalization guarantee is implied.


### TSK-415 — Unique item IDs in exported backups

- Implementation: `BackupCodec.encode`, validation alongside the saved-item loop.
- Requirements: FR-001–003 and FR-012–013 (stable saved-item identity across portable backup/restore).
- Test: TC-119 in `test/backup_codec_test.dart`.
- Verification: source/test committed but unrun.


### TSK-413 — Preflight JSON output size before serialization

- Implementation: `BackupCodec.encode`, counting item JSON bytes and predicted attachment JSON/base64 bytes before final serialization.
- Requirements: FR-012–013 and NFR-003 (portable backup bounds and predictable memory use).
- Test: TC-117 in `test/backup_codec_test.dart`.
- Verification: source/test committed but unrun; memory profiling remains pending.


### TSK-417 — Repository-owned attachment input snapshots

- Implementation: `LibraryRepository.save` copies caller-provided attachment bytes after validation and before the first storage await.
- Requirements: FR-008 and NFR-003 (stable imported attachment data after save and recoverable local persistence).
- Test: TC-122 in `test/library_repository_test.dart`.
- Verification: source/test committed but unrun; actual Android/web picker and storage behavior remains pending.


### TSK-418 — Reject unreferenced attachment payloads

- Implementation: `BackupCodec.decode` performs a raw-key reference preflight before base64 allocation; `validateDecodedBackup` enforces the same invariant for in-memory inputs.
- Requirements: FR-012–013 and NFR-003 (bounded, portable backup restore).
- Test: TC-123 in `test/backup_codec_test.dart`.
- Verification: source/test committed but unrun.


### TSK-419 — Deterministic saved-item sorting

- Implementation: `SavedItemSort` and `compareSavedItemsForSort` in `lib/models/saved_item.dart`, used by Library and Search in `lib/main.dart`.
- Requirements: FR-004, FR-005 and NFR-005 (consistent predictable retrieval and sorting).
- Test: TC-124 in `test/saved_item_test.dart`.
- Verification: source/test committed but unrun.


### TSK-420 — StashHive product-brand alignment with legacy data compatibility

- Implementation: visible strings in `lib/main.dart`, the Android manifest configurator, `web/manifest.json`, `web/index.html`, README and current product/design docs. `BackupCodec` deliberately retains the version-1 `StashHive` app marker.
- Requirements: FR-012–013 and NFR-003 (existing local data and portable backups remain recoverable); visible branding consistency supports predictable navigation.
- Tests: TC-125 in `test/accessibility_widgets_test.dart`; TC-126 in `test/backup_codec_test.dart`. The generated manifest label is additionally covered by `tool/test_configure_android_share_intents.py`.
- Verification: source/test committed but unrun; Android and PWA install labels remain pending manual validation.


### TSK-421 — Attachment cleanup for unreadable legacy records

- Implementation: `LibraryRepository.delete` recovers a raw attachment key only when `findById` cannot decode the item; existing raw-record reference scanning still protects any shared payload.
- Requirements: FR-008, FR-012–013 and NFR-003 (attachment integrity, local-storage hygiene and recoverability from malformed records).
- Tests: TC-127, TC-128 and TC-129 in `test/library_repository_test.dart`.
- Verification: source/test committed but unrun. Manual recovery/platform validation remains pending.


### TSK-422 — First-launch local-storage safety reminder

- Implementation: `lib/main.dart`, `LibraryPage` and `lib/data/library_repository.dart`.
- Requirement: FR-015; the reminder uses platform-specific wording and does not imply cloud sync.
- Tests: repository preference persistence in `test/library_repository_test.dart`; reminder content/actions in `test/accessibility_widgets_test.dart`; manual acceptance TC-130.
- Verification: source and regression cases are authored; they remain unrun. Web profile persistence, Android restart behavior and responsive visual review remain pending.


### TSK-423 — Recoverable collection deletion errors

- Implementation: `lib/main.dart`, `_CollectionsPageState._deleteCollection`.
- Requirement: FR-010; a repository failure must not escape as an uncaught UI error.
- Regression: TC-131 in `test/accessibility_widgets_test.dart` injects a collection-mutation failure and checks user feedback plus retained collection/item assignment.
- Verification: source/test added but unrun; underlying storage interruption behavior remains subject to manual validation.


### TSK-424 — Recoverable item deletion errors

- Implementation: `lib/main.dart`, `_ItemDetailsPageState._delete`.
- Requirement: FR-003; when repository deletion fails, remain on Item Details and display a recoverable error rather than allowing an uncaught exception to escape.
- Regression: TC-132 in `test/accessibility_widgets_test.dart` injects an error after attachment removal and checks that the item and bytes are restored by the repository rollback path.
- Verification: test source authored but unrun; rollback remains best-effort under real storage interruption.


### TSK-425 — Platform-specific Item Details attachment location

- Implementation: `lib/main.dart`, Item Details attachment metadata.
- Requirement: FR-015/NFR-004; web describes data as stored in the current browser profile while Android describes device-local storage.
- Regression: `test/accessibility_widgets_test.dart` checks the native label; TC-133 explicitly checks both platforms.
- Verification: source is committed; widget test is unrun, and browser/native copy still needs visual confirmation.


### TSK-426 — Dark-mode preference rollback

- Implementation: `lib/data/library_repository.dart` and `_StashHiveAppState._setDarkMode` in `lib/main.dart`.
- Behavior: if a preference write fails after it may have committed, the repository attempts to restore the previous value; the app catches the failure and syncs its visible theme to the persisted preference.
- Tests: repository late-write rollback in `test/library_repository_test.dart` and switch-reversion coverage in `test/accessibility_widgets_test.dart`; manual case TC-134.
- Verification: source/tests are authored but unrun; platform storage behavior remains unverified.


### TSK-427 — Accurate search scope and platform wording

- Implementation: `lib/main.dart`, Settings → Search & saved content.
- Requirements: FR-005 and NFR-004; help text names fields actually indexed (including collection names), states local scope, and avoids implying OCR or cross-device search.
- Regression: TC-135 in `test/accessibility_widgets_test.dart` checks native copy and field disclosure; web phrasing remains part of manual platform review.
- Verification: source/test committed but unrun.


### TSK-428 — Safe user-facing operation error messages

- Implementation: `lib/main.dart`; unexpected errors in file selection, save, item/collection deletion, backup export and restore use actionable generic fallbacks.
- Behavior: preserves app-defined `FormatException` messages so size/validation guidance remains actionable, while avoiding display of raw unexpected storage/plugin exception details in normal-operation and startup screens.
- Regression evidence: TC-131 and TC-132 assert injected exception strings are not displayed; TC-136 and TC-137 record broader error-path review and startup screen coverage.
- Verification: source and regression cases are committed but unrun. This is not a claim of a complete privacy audit; platform-owned messages, logs, permissions and network behavior still need review.


### TSK-429 — Privacy-safe startup storage failure screen

- Implementation: `StartupFailureApp` and `main()` in `lib/main.dart`.
- Requirements: FR-018 and NFR-002. Startup recovery guidance distinguishes browser storage from native device storage and no longer renders the raw initialization exception into the UI.
- Regression: TC-137 in `test/accessibility_widgets_test.dart` checks recovery copy and confirms the screen contains no selectable raw diagnostics.
- Verification: test source added but unrun; startup failure simulation and full privacy review remain pending.



### TSK-440 — Search hint matches indexed metadata

- Implementation: `_SearchPageState` in `lib/main.dart`; the Search field hint now lists collections alongside titles, URLs, notes and tags.
- Requirements: FR-005 and NFR-004 (retrieval clarity and accurate disclosure of searchable fields).
- Regression: TC-148 in `test/accessibility_widgets_test.dart`.
- Verification: source and regression are committed but unrun; web/Android wording and layout review remains pending.

### TSK-441 — Actionable empty Search state for type filters

- Implementation: `EmptySearchState` and `_SearchPageState` in `lib/main.dart`; the empty state now distinguishes an unmatched type filter from a library with no saved items and provides an appropriate reset action.
- Requirements: FR-004–005 and NFR-006 (understandable no-result state and accessible recovery).
- Regression: TC-149 in `test/accessibility_widgets_test.dart`; covers both an unmatched filter alone and a combined query-plus-filter reset.
- Verification: source/test committed but unrun; narrow-width, large-text, keyboard and screen-reader review remains pending.

### TSK-442 — Actionable favorite-update storage errors

- Implementation: `SavedItemTile` in `lib/main.dart`; unexpected failures from `LibraryRepository.toggleFavorite` now use the shared safe-error helper, with storage-specific fallback guidance. App-defined validation messages remain available.
- Requirements: FR-004 and FR-018, NFR-002–003 (understandable actions and privacy-conscious failure feedback).
- Regression: TC-150 in `test/accessibility_widgets_test.dart` injects a late write failure and asserts the favorite state is rolled back and raw exception detail is hidden.
- Verification: source/test committed but unrun; real platform persistence/rollback still needs validation.


### TSK-443 — User-adjustable text size that respects platform accessibility settings

- **Requirement:** NFR-006 / SCR-007 (accessible text sizing and Settings completeness).
- **Source:** Settings now exposes System default, Large and Extra large. The preference is saved locally and applies an additional multiplier on top of the platform's TextScaler, so it never replaces or lowers the device/browser setting.
- **Regression:** TC-151 covers the Settings interaction, applied scale, preference persistence and rollback after a late storage failure.
- **Status:** Source and regression cases are committed but unrun; narrow viewport, Android and web behavior remain pending manual validation.


### TSK-444 — Consistent favorite-update failure feedback in Item Details

- **Requirement:** FR-004 / FR-018 and NFR-002–003 (reliable item actions, safe operation feedback and recoverable local persistence).
- **Implementation:** the Item Details favorite action now uses the shared operation-error helper, matching the Library tile. Unexpected storage failures show local-storage/retry guidance instead of unrelated URL/file repair advice.
- **Regression:** TC-152 injects a late favorite-write failure and confirms the actionable message, privacy-safe error text and non-favorite rollback state.
- **Verification:** source and regression are committed but unrun; browser/device persistence behavior remains pending.

### TSK-445 — Extra-large text preference persistence and reset

- **Requirement:** NFR-006 / SCR-007 (accessible text sizing with an explicit return to system defaults).
- **Implementation:** Existing Settings text-size preference; this increment extends regression coverage for selecting Extra large, recreating app state from the same repository, and resetting to System default.
- **Test:** TC-153 in `test/accessibility_widgets_test.dart` and `docs/test-plan.md`.
- **Verification:** Regression source committed but unrun; manual web/Android text-scaling review remains pending.


### TSK-446 — Attachment-safe cleanup after failed backup restore

- **Requirement:** FR-013 and NFR-003; backup restore must reject corrupt input safely and rollback must not knowingly remove attachment bytes while a surviving saved-item record still references them.
- **Implementation:** `LibraryRepository.restoreDecodedBackup` now attempts all staged item deletions before reclaiming distinct attachment keys, skips payloads still referenced by raw records, and refreshes visible notifiers after best-effort rollback.
- **Regression:** TC-154 in `test/library_repository_test.dart` injects both a restore interruption and a staged-item rollback deletion failure, then checks that the remaining record still has its original bytes and collection preferences are restored.
- **Verification:** Source regression authored but unrun. Real storage interruption, browser persistence, and Android persistence still require the manual validation checkpoint.

### TSK-447 — Early acknowledgement of launch-time shares

- **Requirement:** FR-009 (reliable incoming Android share intake); a fetched launch-time share should not remain pending merely because the user is still reviewing its Quick Save draft.
- **Implementation:** `consumeInitialSharedMedia` in `lib/services/share_intake.dart` acknowledges the plugin's initial callback before awaiting batch review. If acknowledgement fails, the already-read share is still enqueued.
- **Regression:** `test/share_intake_test.dart` verifies reset happens before an intentionally paused review queue and that reset failure does not discard the media.
- **Verification:** Source regression authored but unrun. Restart/replay behavior and Android plugin timing require device validation.

### TSK-448 — Preserve shared content when changing Quick Save type

- **Requirement:** FR-003 and FR-008–009; editing the kind of a draft must not silently discard user-entered content that remains valid as notes across supported item types.
- **Implementation:** `_QuickSavePageState._selectKind` in `lib/main.dart` clears the type-specific selected attachment, but retains the shared notes/content controller.
- **Regression:** TC-156 in `test/quick_save_test.dart` enters note content, switches to Link and back to Note, and verifies the text remains without saving an item.
- **Verification:** Source regression authored but unrun; keyboard/screen-reader and platform interaction review remain pending.

### TSK-449 — Preserve attachment when current Quick Save kind is reselected

- **Requirement:** FR-008–009 and NFR-003; reviewing or confirming the selected type must not silently discard a file already selected or supplied by an Android share.
- **Implementation:** The Quick Save kind-selection handler now returns without mutating draft state when the chosen kind is already active. A real type change still clears type-specific attachment bytes and metadata.
- **Regression:** TC-157 in test/quick_save_test.dart opens Quick Save with a prefilled image share, taps Image again, saves and checks that persisted attachment bytes are unchanged.
- **Verification:** Regression source authored but unrun; real Android share integration and save behavior remain pending.

### TSK-451 — Roll back collection mutations after late preference failures

- **Requirement:** FR-010 and NFR-003; renaming/deleting a collection must keep item assignments consistent if a local preference write reports failure after it has committed.
- **Implementation:** `LibraryRepository._commitCollectionMutation` retains its rollback path and now exposes a fault-injection seam directly after the collection preference write to exercise late-failure recovery.
- **Regression:** TC-158 in `test/library_repository_test.dart` simulates the post-commit failure during rename and checks both item maps, visible items/collections and the persisted collection preference.
- **Verification:** Source regression authored but unrun; browser/Android storage interruption behavior remains pending.

### TSK-452 — Serialize repository mutations to avoid lost updates

- **Requirement:** FR-002–003, FR-010, FR-013 and NFR-003; simultaneous local operations must not derive updates from stale notifier snapshots and overwrite one another's item or collection changes.
- **Implementation:** `LibraryRepository` uses a per-instance asynchronous mutation queue around item save/delete, collection add/rename/delete, and decoded backup restore. The queue releases after success or failure so one failed operation does not block later mutations.
- **Regression:** TC-159 in `test/library_repository_test.dart` pauses the first collection creation after its write, requests a second, and checks neither operation overtakes the other and both names persist.
- **Verification:** Source and test are committed but unrun; real browser/Android persistence remains pending.

### TSK-453 — Release the mutation queue after failed operations

- **Requirement:** FR-002–003, FR-010 and NFR-003; a failed local mutation must not block subsequent operations or overwrite their committed state during recovery.
- **Implementation:** The mutation queue resolves its release signal in a `finally` path; collection creation attempts to roll back a late preference-write failure before the next queued mutation can proceed.
- **Regression:** TC-160 in `test/library_repository_test.dart` pauses the first collection add, injects a post-write failure, and checks the next queued add succeeds with only its own collection persisted.
- **Verification:** Regression source is committed but unrun. Browser/Android persistence and rollback-write failure behavior remain pending.

### TSK-454 — Serialize favorite reads and updates

- **Requirement:** FR-004 and NFR-003; repeated item actions must apply to the latest persisted state instead of overwriting a preceding action calculated from a stale read.
- **Implementation:** `LibraryRepository.toggleFavorite` now enters the repository mutation queue before reading the item and calls the internal save path within that same queued operation.
- **Regression:** TC-161 calls `toggleFavorite` twice without awaiting either call and checks the final notifier and raw stored favorite value match the starting state.
- **Verification:** Regression source is committed but unrun; interaction behavior and persistence require validation at the manual checkpoint.

### TSK-455 — Serialize dark-mode preference rollback

- **Requirement:** NFR-003; a late preference-write failure must not roll back a newer user's choice for the same key.
- **Implementation:** `LibraryRepository.setDarkMode` now serializes its read/write/rollback sequence through the repository mutation queue.
- **Regression:** TC-162 queues the opposite choice while the first operation is paused after writing, injects a late failure, and verifies the newer value remains persisted.
- **Verification:** Regression source is committed but unrun; persistence and storage-interruption behavior remain pending.

### TSK-456 — Serialize text-size preference rollback

- **Requirement:** NFR-003 and NFR-006; text-size changes must persist predictably, remain accessible, and not be overwritten by rollback from an earlier failed choice.
- **Implementation:** `LibraryRepository.setTextScaleMultiplier` now serializes its preference read/write/rollback sequence with other repository mutations.
- **Regression:** TC-163 queues a second supported multiplier during a late failure and verifies the getter and stored preference retain the newer value.
- **Verification:** Regression source is committed but unrun; browser/Android persistence and accessibility review remain pending.


### TSK-457 — Discard stale attachment-picker results after a draft type change

- **Requirement:** FR-008–009 and NFR-003; attachment metadata and bytes must match the item type the user ultimately saves, and changing an unsaved draft must not let a pending asynchronous action restore stale data.
- **Implementation:** Quick Save captures the requested item kind and a revision number when opening the picker. A real type change increments the revision, and the picker request is checked after each asynchronous boundary before it may read or update the draft. Duplicate picker requests are ignored while one request is pending.
- **Regression:** TC-164 in `test/quick_save_test.dart` delays the image picker result, changes the draft to Document, then confirms the outdated result is discarded before file I/O and cannot be saved as a document.
- **Verification:** Widget regression source is committed but unrun; browser/Android picker interaction remains pending.


### TSK-458 — Invalidate old picker requests even when the draft returns to its original type

- **Requirement:** FR-008–009 and NFR-003; asynchronous attachment results must belong to the same draft selection that initiated the request, not merely match the currently selected type by coincidence.
- **Implementation:** Quick Save uses an attachment-selection revision in addition to the requested item kind, so switching Image → Document → Image invalidates the original in-flight request.
- **Regression:** TC-165 in `test/quick_save_test.dart` resolves an old Image picker after switching away and back, then checks that the result is discarded before file I/O.
- **Verification:** Widget regression source is committed but unrun; real platform picker behavior is pending.


### TSK-459 — Prevent draft edits while a save is pending

- **Requirement:** FR-003 and NFR-003/NFR-006; user edits must not be silently discarded after the save snapshot is submitted, and busy state must be understandable and operable with assistive technology.
- **Implementation:** Quick Save disables editable fields, the item-kind selector, collection selector, attachment picker, route buttons, and system back while saving. `PopScope` permits the app's own successful-save pop after the save has completed. Save is guarded against reentry, and the primary action reports when file selection or persistence is in progress.
- **Regression:** TC-166 in `test/quick_save_test.dart` pauses repository save after the item record write, checks fields/type navigation and system-back handling are blocked while saving, and confirms the persisted draft matches the submitted values.
- **Verification:** Widget regression source is committed but unrun; slow storage and screen-reader behavior require manual validation.


### TSK-460 — Preserve Quick Save draft and re-enable retry after failed persistence

- **Requirement:** FR-003 and NFR-003/NFR-006; a failed local save must not silently discard user input, trap the form in a busy state, or prevent a retry.
- **Implementation:** Quick Save keeps the form values when repository save fails, releases its saving state, restores interactive controls and reports safe recovery guidance. The save-pending route guard returns to its normal state when the failure handler unlocks the form.
- **Regression:** TC-167 in `test/quick_save_test.dart` pauses a write, injects a late failure, checks the item rolls back and URL/note remain editable, then retries and confirms the draft saves.
- **Verification:** Widget regression source is committed but unrun; real browser/Android storage failure and retry behavior remain pending.

### TSK-461 — Show attachment selection progress and recover from picker errors

- **Requirement:** FR-008 and NFR-006; file selection should communicate busy state, provide safe and actionable failure feedback, and allow recovery without discarding the draft.
- **Implementation:** Quick Save changes the attachment area's label and hint while file selection/reading is pending, shows an inline progress indicator instead of the idle upload icon, and marks the busy picker semantics as a live region so assistive technology can announce the change.
- **Regression:** TC-168 in `test/quick_save_test.dart` pauses the picker, injects an unexpected provider error, checks that the busy UI clears and raw details remain hidden, then retries with a valid image and verifies exact persisted bytes.
- **Verification:** Widget regression source is committed but unrun; real picker and byte-stream failure behavior remains pending on Android and supported browsers/desktop platforms.

### TSK-462 — Bound Android share intake and validate before string copies

- **Requirements:** FR-008/FR-009 and NFR-002/NFR-003; external shares must be processed within predictable bounds, invalid payloads must receive normal validation feedback, and supported content must not be rejected because an unused provider field is empty.
- **Implementation:** One incoming share batch is limited to the first 100 entries, with a user-facing warning for the remainder. Duplicate-fingerprint work now performs a length-only first pass with limits for batch count, raw text/path/message/MIME fields and aggregate characters before trimming or normalizing; over-limit input bypasses fingerprint serialization so the normal intake path can give actionable validation feedback. Text shares now consume a non-empty message even if the provider path is empty, video shares exit as unsupported before path parsing, and URL/path/MIME lengths are checked before expensive string transformations.
- **Regression:** TC-169 covers batch truncation/order and large text bypass; TC-170 covers message-only text shares.
- **Verification:** Regression source is committed but unrun. Validate actual provider field conventions, warnings, multi-select order and error behavior on a real Android device at the manual checkpoint.

### TSK-463 — Serialize backup export with pending mutations

- **Requirements:** FR-012/FR-013 and NFR-003; exported metadata, attachment payloads and collection preferences must represent a consistent repository state.
- **Implementation:** `LibraryRepository.createBackup()` now takes a position in the same asynchronous queue as item save/delete, collection mutations, and restore. Export waits for an in-flight write and snapshots metadata and attachments after it has either completed or rolled back.
- **Regression:** TC-171 pauses an attachment replacement after the item write, requests a backup, then verifies the export does not finish early and decodes with matching edited metadata and replacement bytes.
- **Verification:** Regression source is committed but unrun. Real web/Android storage consistency and concurrent backup scenarios remain pending the manual validation checkpoint.

### TSK-465 — Guard share enqueue against host disposal

- **Requirements:** FR-009 / NFR-003; asynchronous share intake must not enqueue work into a disposed navigation host or leave awaited batch completions unresolved.
- **Implementation:** `_enqueueShareBatch` now exits when `HomeShell` is no longer mounted, covering a stream event already in flight during cancellation. The currently active batch completer is tracked and released during disposal along with waiting batches.
- **Manual regression:** TC-172 exercises share-stream delivery racing with app-shell disposal, including an already-active batch's completion.
- **Verification:** Source guard is committed; Android plugin cancellation, lifecycle and restart behavior remain pending physical-device validation.

### TSK-466 — Bound the waiting queue for share batches

- **Requirements:** FR-009 / NFR-003; incoming share events must not accumulate unbounded pending work while the user reviews existing content.
- **Implementation:** The active share batch is tracked separately; the waiting queue admits at most `maxPendingIncomingShareBatches` (8) batches. Further unique events are declined with explicit feedback that the new share was not queued and must be shared again after current batches finish. Capacity is checked before recording a de-duplication fingerprint so a declined event can be retried after capacity returns.
- **Regression:** TC-173 checks queue admission at the exact capacity boundary and documents the required queue-full/FIFO/lifecycle device checks.
- **Verification:** The queue-limit unit regression is committed but unrun; real stream ordering and capacity-recovery UX remain pending Android validation.

### TSK-467 — Keep incoming-share fingerprinting resilient to unusual file URIs

- **Requirements:** FR-009 / NFR-002–003; provider metadata must not throw from a background stream callback before a safe item-level intake error can be shown.
- **Implementation:** MIME inference now treats URI-to-local-path conversion as best-effort during duplicate fingerprinting and falls back to the bounded raw path if the current platform cannot convert a provider's file URI.
- **Regression:** TC-174 supplies a file URI with a non-local authority and asserts the event can be fingerprinted without throwing.
- **Verification:** Regression source is committed but unrun. Confirm real file provider URI forms and fallback behavior on Android during the manual validation checkpoint.

### TSK-468 — Prevent stale preference errors from reverting newer UI choices

- **Requirements:** NFR-003/NFR-006; optimistic preference controls must remain consistent with the latest queued user choice even when an older local-storage write fails late.
- **Implementation:** `_StashHiveAppState` now increments a request revision for dark mode and text size. A failure handler restores the persisted value only if its request is still the most recent request for that control.
- **Regression:** TC-175 queues two newer theme choices behind a paused failing write; TC-176 chooses Extra large while an earlier text-size write is pending and failing; TC-177 verifies the visible dropdown returns to the persisted option after a failed selection. Both verify the newest value stays selected and persisted.
- **Verification:** Widget regression source is committed but unrun. Storage latency and accessible state changes need manual browser/Android review.

### TSK-469 — Track the last generated backup without implying successful delivery

- **Requirements:** FR-012–015 and NFR-004; backup status must help the user understand recency without making a false claim that a file was permanently saved somewhere.
- **Implementation:** The repository stores `lastBackupPreparedAtMs` in local preferences after backup JSON generation succeeds, before releasing the same serialized mutation operation that produced the snapshot. This prevents a queued edit from running between snapshot generation and timestamp storage. The Backup & privacy screen displays the local date/time and explicitly says it records file generation, not whether a destination saved the file. Failure to store this optional timestamp does not block sharing the prepared JSON; if a late write fails after committing, best-effort rollback restores the previous status.
- **Regression:** TC-178 covers timestamp validation and repository reopen; TC-179 covers the empty state, formatted timestamp and truthful wording.
- **Verification:** Source regression coverage is committed but unrun. Confirm status updates after native/web share-sheet return or cancellation at the manual validation checkpoint.

### TSK-471 — Keep backup exports consistent after delete rollback

- **Requirements:** FR-003, FR-012 and NFR-003; an export must not read a half-completed deletion or treat a temporarily removed attachment as a permanently unexportable item.
- **Implementation:** Backup creation shares the repository mutation queue with deletes and their rollback handlers. A queued export captures the repository after the delete either commits or restores its previous item record and attachment bytes.
- **Regression:** TC-181 pauses deletion after record/attachment removal, requests a backup, then injects a late delete failure and verifies the resulting backup contains the restored item's metadata and exact attachment bytes.
- **Verification:** Repository regression source is committed but unrun. Verify concurrent delete/backup behavior against browser and Android storage at the manual validation checkpoint.

### TSK-472 — Keep backup exports out of interrupted restore states

- **Requirements:** FR-012–013 and NFR-003; a backup must reflect a stable repository snapshot, not partially staged restore records/attachments.
- **Implementation:** Restore and backup use the same repository mutation queue. A queued backup waits until restore commits or its failure path has removed staged records/attachments and restored the prior collection preferences.
- **Regression:** TC-182 pauses a restore after incoming image data is staged, requests a backup, then injects an interruption and verifies that the resulting backup contains only the original item/collection and no staged attachment.
- **Verification:** Regression source is committed but unrun. Exercise backup during interrupted restore on web and Android at the manual validation checkpoint.

### TSK-473 — Keep backup exports consistent after save rollback

- **Requirements:** FR-002, FR-012 and NFR-003; a failed save must restore the previous item/attachment pair before a queued export takes its snapshot.
- **Implementation:** `LibraryRepository.createBackup()` shares the mutation queue with save and rollback. A queued export waits for the save to either commit or restore the prior metadata and attachment payload.
- **Regression:** TC-183 pauses an attachment replacement after item write, requests a backup, then injects a late save failure and verifies the export contains the original title and exact original bytes.
- **Verification:** Repository regression source is committed but unrun. Verify concurrent backup/failed-save behavior on web and Android at the manual checkpoint.

### TSK-474 — Keep backup snapshots aligned with collection renames

- **Requirements:** FR-010, FR-012 and NFR-003; the exported collection list and each saved item's collection assignment must reflect the same committed repository state.
- **Implementation:** Backup generation runs behind the shared mutation queue. A backup requested during collection rename waits until item records, collection preferences, and visible notifiers agree.
- **Regression:** TC-184 pauses rename after underlying writes but before notifier refresh, queues backup creation, and verifies the result contains the new collection and matching saved-item assignment.
- **Verification:** Regression source is committed but unrun. Verify backup/export behavior during collection updates on browser and Android at the manual checkpoint.

### TSK-475 — Preserve effective text when an unused provider path is oversized

- **Requirements:** FR-009 and NFR-003; provider fields that do not contribute to the effective draft must not cause unnecessary rejection, while fingerprint work stays bounded.
- **Implementation:** Text intake validates and consumes a non-empty message directly. It does not require or normalize the unused path before constructing a note; oversized provider fields bypass fingerprint serialization and continue to the normal intake path.
- **Regression:** TC-185 supplies a valid note message with an over-limit unused path and checks that the message becomes the note draft.
- **Verification:** Regression source is committed but unrun. Confirm the exact behavior against real Android share-provider variants at the manual checkpoint.

### TSK-476 — Recover from attachment size metadata failures

- **Requirements:** FR-008 and NFR-003/NFR-006; selecting a file must fail safely if provider metadata cannot be read, and the user must be able to retry without losing the draft.
- **Implementation:** Quick Save already guards size lookup and bounded reading with a recoverable error path; the new regression explicitly covers an exception from `PlatformFile.length()`, checks raw provider details are hidden and confirms a second selection can be saved.
- **Regression:** TC-186 injects a file-size lookup failure followed by a successful image selection and verifies the exact stored bytes.
- **Verification:** Widget regression source is committed but unrun. Confirm platform file-provider exceptions and retry behavior on Android and supported browsers/desktop at the manual checkpoint.

### TSK-477 — Recover from attachment byte-stream read failures

- **Requirements:** FR-008 and NFR-003/NFR-006; a provider can fail during byte reading even after the picker and size lookup succeed, and the user must retain a recoverable form state.
- **Implementation:** Quick Save's existing bounded stream reader is wrapped by the same safe picker error path as size lookup. The failure clears busy state without exposing provider details and permits a fresh selection.
- **Regression:** TC-187 provides a PlatformFile whose length succeeds but whose byte stream throws, then retries with a valid image and verifies exact stored bytes.
- **Verification:** Widget regression source is committed but unrun. Confirm partial-stream/provider failure behavior on Android and supported browser/desktop platforms at the manual validation checkpoint.

### TSK-478 — Bound pasted URL and tag input before parsing

- **Requirements:** FR-002 and NFR-003; large pasted values should fail early and predictably rather than trigger unnecessary normalization or temporary list allocation.
- **Implementation:** Quick Save checks a raw URL's character count before trimming or parsing. The comma-separated tag field has a 12,000-character limit validated inline and defensively before tag splitting; existing limits of 100 tags and 100 characters per tag still apply.
- **Regression:** TC-188 covers oversized tag text and the existing URL-length test verifies the documented 4,096-character error.
- **Verification:** Regression source is committed but unrun. Review large-paste behavior and ordinary URL/tag editing on web and Android during the manual checkpoint.

### TSK-479 — Normalize search once and bound oversized queries

- **Requirements:** FR-005 and NFR-007; search should remain responsive as the saved library grows and avoid repeated normalization of the same query for every item.
- **Implementation:** SavedItem exposes a matcher for already trimmed/lower-case queries while preserving the existing convenience method. SearchPage normalizes once per search, skips scanning the item list if the query exceeds 4,096 characters, and displays an inline limit message.
- **Regression:** TC-189 checks oversized initial queries return no results with clear feedback; the SavedItem unit regression covers the reusable normalized-query matcher.
- **Verification:** Widget/model regression sources are committed but unrun. Measure search performance at 100/1,000/10,000 items and verify Unicode, paste behavior and accessibility on web/Android at the manual checkpoint.

### TSK-480 — Recover from backup picker metadata errors

- **Requirements:** FR-013 and NFR-003/NFR-006; unreadable file metadata during restore must not leave the backup screen stuck in a busy state or expose private provider diagnostics.
- **Implementation:** The backup restore picker can be injected for regression coverage; the production path keeps its existing safe error handling and resets the choosing-backup state in `finally` after a length lookup failure.
- **Regression:** TC-190 injects a `PlatformFile.length()` failure, verifies generic guidance and no data changes, then provides a valid backup and confirms that merge succeeds.
- **Verification:** Widget regression source is committed but unrun. Verify actual provider metadata errors and retry behavior on web and Android during the manual validation checkpoint.

### TSK-481 — Ignore oversized whitespace in unused share message fields

- **Requirements:** FR-009 and NFR-003; providers may populate both path and message, but only one may be the effective draft content. An oversized unused field must not reject valid user content or require an unnecessary large trim/copy.
- **Implementation:** Text-share intake checks whether the message contains non-whitespace before applying the message length rejection. An oversized whitespace-only message is treated as empty and intake falls back to the bounded path field.
- **Regression:** TC-191 supplies a short valid path and an oversized whitespace-only message and expects an editable note draft from the path.
- **Verification:** Regression source is committed but unrun. Confirm whitespace/provider-field behavior on physical Android devices at the manual validation checkpoint.

### TSK-482 — Recover from backup byte-stream read failures

- **Requirements:** FR-013 and NFR-003/NFR-006; a failure while streaming a selected backup must not mutate the library, expose provider diagnostics, or trap the restore controls in a busy state.
- **Implementation:** The restore UI's existing bounded stream reader and safe catch/finally path now have an explicit widget regression for a provider that reports length successfully but errors during byte reading.
- **Regression:** TC-192 confirms generic retry guidance, no raw exception leak, unchanged library state, unlocked controls, and successful import after a second valid selection.
- **Verification:** Regression source is committed but unrun. Verify real browser/Android picker stream errors and retry behavior at the manual validation checkpoint.

### TSK-483 — Block navigation during an active restore commit

- **Requirements:** FR-013 and NFR-003/NFR-006; once a user confirms restore and staged writes begin, leaving the screen should not make a running data operation appear canceled or remove its completion feedback.
- **Implementation:** Backup & privacy wraps its route in `PopScope<bool>` with `canPop: !_restoring`; the app-bar Back action is also disabled during the commit. Navigation remains available again when restore finishes or fails.
- **Regression:** TC-193 pauses restore before the collection commit, attempts both app-bar and system back, verifies the page remains in its restoring state, then releases the operation and checks successful completion.
- **Verification:** Widget regression source is committed but unrun. Validate system-back gestures and slow-storage behavior on Android and web at the manual validation checkpoint.

### TSK-484 — Show share truncation feedback after review completes

- **Requirements:** FR-009 and NFR-006; feedback about an oversized multi-item share must remain visible and useful instead of appearing beneath a Quick Save route that immediately covers it.
- **Implementation:** A queued share batch now retains its `skippedCount`. Omitted counts are accumulated across truncated batches and the warning is shown only after all already-queued batches finish their sequential reviews, when the host returns to the home screen rather than opening another Quick Save route.
- **Manual regression:** TC-194 shares more than 100 items, confirms the first 100 are reviewed sequentially, and checks the omitted-count warning appears after the last supported/unsupported entry has been handled.
- **Verification:** Source change is committed; TC-194 remains a manual UX case. Confirm source-app batch behavior on a physical Android device at the validation checkpoint.

### TSK-485 — Aggregate share review feedback after the queue drains

- **Requirements:** FR-009 and NFR-006; users need understandable feedback for unsupported, invalid and omitted items, and messages must not be obscured by immediately opening the next review route.
- **Implementation:** HomeShell records counts for unsupported, invalid/unreadable and over-limit entries. It retains at most three distinct, app-defined safe validation hints and presents a single combined message only after all currently queued share batches finish.
- **Manual regression:** TC-195 queues multiple share batches containing unsupported/invalid entries plus an over-limit batch, checks sequential review proceeds first, then verifies one combined summary appears on the Library screen with appropriate counts and no raw provider details.
- **Verification:** Source change is committed; TC-195 is a manual UX case. Confirm counts, timing and readability on a physical Android device at the validation checkpoint.

### TSK-486 — Bound and test the aggregate share feedback message

- **Requirements:** FR-009 and NFR-006; review feedback should accurately communicate omitted/error counts without flooding the UI or exposing raw provider diagnostics.
- **Implementation:** A pure share-service summary builder formats unsupported, invalid/unreadable and omitted counts, de-duplicates hints and caps details at three distinct app-defined messages. It returns no message if there is nothing to report; HomeShell invokes it only after the waiting queue drains and keeps the combined summary visible for eight seconds.
- **Regression:** TC-196 checks combined counts and hint limits; TC-197 ensures a successful share batch does not get an empty-state warning. TC-195 remains the manual end-to-end timing/accessibility case.
- **Verification:** Service test source is committed but unrun. Verify end-to-end summary timing and screen-reader behavior on Android at the manual validation checkpoint.

### TSK-487 — Release restore navigation guard after commit failure

- **Requirements:** FR-013 and NFR-003/NFR-006; route protection during a restore must prevent dismissal while writes are in progress without trapping the user after rollback/error.
- **Implementation:** `PopScope<bool>` guards only while `_restoring` is true; the existing `finally` path clears `_restoring` after success or failure. The new regression explicitly checks that error recovery restores navigation.
- **Regression:** TC-198 interrupts restore before collection commit, confirms the library remains intact and diagnostic details stay hidden, then invokes system back and verifies the page can close.
- **Verification:** Widget regression source is committed but unrun. Check rollback and navigation state on web/Android at the manual validation checkpoint.

### TSK-488 — Make backup share-outcome feedback status-specific

- **Requirements:** FR-012 and NFR-003; backup export must distinguish the JSON being prepared from the platform reporting a completed share action, a dismissed sheet or an indeterminate result.
- **Implementation:** `backupShareResultMessage` maps the three `ShareResultStatus` values to separate, truthful guidance. `success` still asks the user to verify the destination; `dismissed` directs them to retry if they did not save the file; `unavailable` says the outcome is uncertain and tells them to check the destination/Downloads.
- **Regression:** TC-199 asserts the message for each outcome and guards against a false delivery claim.
- **Verification:** Regression source is committed but unrun. Verify real browser/Android share outcomes and file arrival during the manual checkpoint.

### TSK-489 — Snapshot caller-owned decoded backup inputs before restore awaits

- **Requirements:** FR-013 and NFR-003; validating a restore must protect the in-flight import from later changes to publicly constructible input objects.
- **Implementation:** The repository validates incoming DecodedBackup, then copies item tag lists and collections into unmodifiable lists, and copies attachment metadata/maps and byte arrays before the first asynchronous boundary. The restore stages and writes only from this owned snapshot.
- **Regression:** TC-200 pauses after the snapshot is validated, mutates/clears the original input lists and map, replaces source bytes, then checks the import matches the original validated state.
- **Verification:** Regression source is committed but unrun. Confirm peak memory and restore consistency on web/Android at the manual checkpoint.

### TSK-490 — Snapshot mutable saved-item metadata before repository save

- **Requirements:** FR-002 and NFR-003; the metadata persisted by a save must match the validated values submitted at the start of that repository operation.
- **Implementation:** LibraryRepository.save() now clones and freezes the item tags list before validation or asynchronous storage operations. Caller mutations to the source list cannot change item metadata while a save is paused or in progress.
- **Regression:** TC-201 mutates a caller-owned tag list while save is paused immediately before its record write, then checks the repository notifier and raw stored map both retain the original tags.
- **Verification:** Regression source is committed but unrun. Verify save metadata snapshot behavior alongside attachment snapshot and rollback cases at the manual checkpoint.

### TSK-491 — Prevent attachment reads from observing an in-flight replacement

- **Requirements:** FR-008 and NFR-003; item metadata and its attachment payload must be observed as a consistent saved state during concurrent edits.
- **Implementation:** The repository operation queue now serializes attachment reads with saves, deletes, restores and backup snapshot creation. A preview/share read cannot observe replacement bytes before their item commit or while rollback is restoring old bytes.
- **Regression:** TC-202 pauses a replacement after payload write and proves the read waits for commit. TC-203 injects a replacement failure and proves the read waits for rollback and returns the original bytes.
- **Verification:** Repository regression source is committed but unrun. Validate slow-storage preview/share behavior and failure recovery on web and Android during the manual checkpoint.

### TSK-492 — Show an explicit loading state for pending Item Details attachment reads

- **Requirements:** FR-011 and NFR-006; a slow or queued attachment read must not be described as a missing file before the read completes, and progress should be announced accessibly.
- **Implementation:** Item Details and its image dialog show a live loading state while the attachment future is pending. Only a completed read with no bytes shows the missing-file guidance; read errors receive preview-unavailable feedback.
- **Regression:** TC-204 pauses an attachment replacement before metadata commit, opens Item Details, and confirms both the page and image dialog show loading instead of missing-file messaging.
- **Verification:** Widget regression source is committed but unrun. Validate slow-storage and screen-reader behavior on web/Android at the manual checkpoint.

### TSK-493 — Reuse image thumbnail read futures across library rebuilds

- **Requirements:** FR-008, FR-011 and NFR-003/NFR-007; a local image thumbnail should not schedule repeated repository reads on unrelated UI rebuilds.
- **Implementation:** The thumbnail is now stateful and holds its attachment future. It refreshes the future when the repository or saved-item identity/revision changes, while harmless parent rebuilds retain the same future. A repository test seam counts read starts in widget coverage.
- **Regression:** TC-205 mounts a library image, triggers an unrelated parent rebuild, and confirms the same item revision performs one attachment read rather than queuing another.
- **Verification:** Widget regression source is committed but unrun. Check thumbnail refresh after edits/replacements and capture the repository performance baseline at the manual checkpoint.

### TSK-494 — Coalesce overlapping reads without crossing repository writes

- **Requirements:** FR-008/FR-011 and NFR-003/NFR-007; repeated consumers should not issue duplicate reads for the same attachment, while every read requested after a queued mutation must observe the post-mutation state.
- **Implementation:** `LibraryRepository` tracks an in-flight attachment-read future by key and queue sequence. Same-key requests share it only if no later repository operation has been queued; a read requested after an intervening save/delete/restore gets its own queue position and cannot observe stale bytes.
- **Regression:** TC-206 pauses a read, coalesces a second request, queues an attachment replacement, then verifies a later read returns replacement bytes while both earlier callers receive the original snapshot.
- **Verification:** Regression source is committed but unrun. Validate shared-key image previews and replacement refresh on web/Android at the manual validation checkpoint.

### TSK-495 — Release coalesced attachment reads after failure

- **Requirements:** FR-008/FR-011 and NFR-003; a failed attachment read must not leave a cached rejected future that prevents a later retry.
- **Implementation:** The in-flight read registry removes its entry in a finally path, only when the completing operation still owns the current entry for that key. Failed reads therefore release their entry without accidentally removing a newer read queued after a write.
- **Regression:** TC-207 injects one read failure, retries the same key, and verifies the second read returns the original stored bytes.
- **Verification:** Regression source is committed but unrun. Verify recovery with real storage/plugin errors on web and Android at the manual validation checkpoint.

### TSK-496 — Keep synchronous lookup on the last published item snapshot

- **Requirements:** FR-002/FR-003 and NFR-003; callers must not observe item metadata staged during a save before the associated attachment writes and transaction outcome are finalized.
- **Implementation:** Repository refresh publishes an O(1) visible-item index and the immutable items notifier from the same snapshot. The index is updated before notifier listeners are called. `findById` reads this published index instead of decoding the raw Hive map, so a save paused after its raw item write cannot expose an uncommitted item version to synchronous callers.
- **Regression:** TC-208 pauses an attachment replacement after the item record write, verifies raw storage has the pending title while `items.value` and `findById` retain the old published title, then releases the save and checks the new title and bytes.
- **Verification:** Regression source is committed but unrun. Exercise lookup consistency during delayed save/delete/restore and rollback on web and Android at the manual validation checkpoint.

### TSK-497 — Preserve the published lookup snapshot during delete rollback

- **Requirements:** FR-003 and NFR-003; synchronous item lookup must not report an item missing while a delete is still pending and may roll back.
- **Implementation:** The item index used by `findById` is published together with the repository's immutable item list. The raw Hive record may be removed while a delete is paused, but the index retains the prior published item until commit or rollback refreshes the public snapshot.
- **Regression:** TC-209 pauses delete after removing the raw item and attachment, confirms `findById` still returns the published item, then injects failure and verifies rollback restores the item and bytes.
- **Verification:** Regression source is committed but unrun. Verify slow deletion/rollback and lookup behavior on web and Android during the manual checkpoint.

### TSK-498 — Keep staged restore records out of the published lookup

- **Requirements:** FR-013 and NFR-003; incoming records must not be visible to application callers until restore has completed its staged writes and committed the merged collection state.
- **Implementation:** `findById` reads from the same published item index as the `items` notifier. Raw item records written during the restore staging phase remain hidden until the repository refresh publishes the committed snapshot.
- **Regression:** TC-210 pauses restore after its raw item write, verifies lookup cannot see the staged record and existing items remain visible, then releases commit and checks the incoming item becomes visible.
- **Verification:** Regression source is committed but unrun. Verify normal and interrupted restore visibility/rollback on web and Android during the manual checkpoint.

### TSK-499 — Expose repository state through read-only listenables

- **Requirements:** FR-002/FR-010 and NFR-003; UI consumers need reactive repository state without getting a public setter that can replace repository snapshots without persisted writes.
- **Implementation:** Item, collection and recovery-counter notifier instances are private. The repository exposes stable read-only `ValueListenable` wrappers that forward values/listeners without returning the mutable notifier objects; internal mutations publish through the private notifiers. The public item/collection snapshots remain unmodifiable.
- **Regression:** TC-211 binds the public accessors as `ValueListenable`, checks notifications after repository save/collection changes, and confirms published item/collection lists reject direct edits.
- **Verification:** Regression source is committed but unrun. Confirm widgets continue to update through the read-only listenables at the manual validation checkpoint.

### TSK-500 — Keep malformed backup version errors bounded

- **Requirements:** FR-013, NFR-002 and NFR-003; malformed backup fields must be rejected safely without echoing untrusted data or allocating an unbounded error message.
- **Implementation:** The decoder now requires `formatVersion` to be an integer before building an unsupported-version message. Non-integer values receive a fixed, concise validation message; unknown integer versions remain explicit.
- **Regression:** TC-212 supplies a 100,000-character string as the version field and asserts a fixed invalid-version message rather than an error that repeats the untrusted field.
- **Verification:** Codec regression source is committed but unrun. Confirm malformed/large backup handling and user-facing feedback at the manual validation checkpoint.

### TSK-501 — Snapshot mutable save inputs before queueing

- **Requirements:** FR-002 and NFR-003; a repository save must persist the values supplied when the operation is requested, even if it waits behind another storage operation.
- **Implementation:** The public `save()` boundary now enforces cheap input bounds and owns a defensive snapshot of tags and attachment bytes before enqueueing the operation. The queued mutation consumes that snapshot rather than reading caller-owned collections after waiting.
- **Regression:** TC-213 pauses an earlier save, enqueues an image save with mutable tags/bytes, mutates the original inputs, then confirms persisted metadata and attachment bytes match the submitted snapshot.
- **Verification:** Regression source is committed but unrun. Verify queue-time snapshot behavior with delayed web/Android storage at the manual validation checkpoint.

### TSK-502 — Snapshot decoded restore inputs before queueing

- **Requirements:** FR-013 and NFR-003; public restore input can contain mutable lists, maps and byte arrays, and must be captured when the request is submitted rather than after waiting behind earlier repository operations.
- **Implementation:** `restoreDecodedBackup()` now validates the public input and creates owned item/tag, collection, attachment-map and byte-buffer snapshots before taking a place in the shared operation queue. The queued restore only consumes the owned snapshot.
- **Regression:** TC-214 pauses a prior save, queues a restore with mutable caller-owned data, mutates/clears every original input collection while restore waits, and confirms imported metadata and attachment bytes match the original submitted snapshot.
- **Verification:** Regression source is committed but unrun. Review restore peak memory and verify queued restore consistency on web and Android at the manual validation checkpoint.

### TSK-503 — Reject oversized tag lists before serialization

- **Requirements:** FR-002, FR-013 and NFR-003; shared item validation must reject oversized caller-provided tag lists before creating a copied representation.
- **Implementation:** `BackupCodec.validateSavedItem` now checks tag count and individual tag lengths before calling `toMap()`, preventing an oversized caller-owned list from being copied merely to learn that it exceeds the supported limit. The public save boundary also performs its cheap tag-size check before full validation.
- **Regression:** TC-215 supplies a list with a declared size above the maximum whose element access throws through item validation, backup encoding and decoded-backup validation; each path must return the normal limit `FormatException` before traversing/copying the list.
- **Verification:** Regression source is committed but unrun. Check oversized item validation through direct save, backup encode and restore preflight at the manual validation checkpoint.

### TSK-504 — Bound the attachment-entry count in backups

- **Requirements:** FR-013 and NFR-003; a portable backup cannot reference more unique attachment keys than it contains saved items, and malformed maps should be rejected before an unbounded key traversal.
- **Implementation:** Both JSON decode and direct `DecodedBackup` validation reject attachment maps whose entry count exceeds the saved-item count before walking attachment keys or examining individual payload metadata. Valid backups already require each attachment entry to be referenced by an item, and each item permits at most one attachment key.
- **Regression:** TC-216 supplies attachment maps with more entries than item records through both JSON decode and direct in-memory validation, and asserts the fixed count-invariant error.
- **Verification:** Codec regression source is committed but unrun. Verify large and malformed backup handling during the manual validation checkpoint.

### TSK-505 — Bound collection count before backup export normalization

- **Requirements:** FR-012/FR-013 and NFR-003; direct backup encoding must apply the same portable collection-entry cap as decoding and must reject malformed oversized inputs before traversing or duplicating them.
- **Implementation:** Backup encoding now checks the raw collection-list length against the 500-entry cap before walking items. Collection normalization iterates declared names and item assignments separately rather than allocating a combined spread list first.
- **Regression:** TC-217 supplies a custom list whose reported length exceeds the limit and whose item access throws; the encoder must return the fixed count error by reading length only.
- **Verification:** Regression source is committed but unrun. Check direct encoder limit parity, legacy normalization and restore compatibility at the manual validation checkpoint.

### TSK-506 — Bound saved-item type fields before parsing

- **Requirements:** FR-013, NFR-002 and NFR-003; untrusted backup/local-record fields must be validated within known bounds and must not be echoed into exceptions.
- **Implementation:** The strict backup raw-map validator now caps all item string fields and checks that `kind` is one of the known item types before `SavedItem.fromMap` trims or canonicalizes data. Local-record recovery also bounds `kind` length. `ItemKind.fromWire` rejects non-string, oversized and unknown values with a fixed message rather than interpolating the supplied value.
- **Regression:** TC-218 covers oversized/unknown item kinds in backup decoding, direct model parsing and local-record recovery while a valid neighboring item remains visible.
- **Verification:** Regression source is committed but unrun. Verify malformed imports and legacy-store recovery alongside the complete backup/restore test matrix at the manual validation checkpoint.

### TSK-507 — Bound optional backup export timestamp metadata

- **Requirements:** FR-012/FR-013 and NFR-002/NFR-003; informational backup metadata should not create unbounded retained strings or unsafe direct in-memory restore inputs.
- **Implementation:** JSON backup decoding keeps an `exportedAt` string only if it is at most 64 characters; missing, malformed or oversized optional metadata becomes empty without invalidating otherwise valid items. Directly constructed `DecodedBackup` instances with an overlong timestamp are rejected during restore validation with a fixed error.
- **Regression:** TC-219 covers both normalization during JSON decode and rejection of oversized direct in-memory restore input.
- **Verification:** Regression source is committed but unrun. Confirm old v1 backups without the field and normal ISO timestamp exports remain compatible at the manual validation checkpoint.

### TSK-508 — Check raw metadata lengths before normalization

- **Requirements:** FR-012/FR-013 and NFR-003; backup/local preference normalization must reject oversized strings before trimming or copying untrusted content.
- **Implementation:** Backup decoding, direct decoded-backup validation and backup collection normalization now check collection lengths before trimming. Strict item-map validation checks tag lengths before whitespace normalization. JSON attachment entries and directly constructed attachment metadata validate key/name/MIME lengths before trimming. Repository collection recovery and collection add/rename apply the same early size checks.
- **Regression:** TC-220 covers oversized tags/collection names in backups, direct decoded inputs, backup encoding and local preference recovery.
- **Verification:** Regression source is committed but unrun. Validate resource bounds and legacy-data recovery at the manual validation checkpoint.

### TSK-509 — Preflight model fields before normalization

- **Requirements:** FR-002/FR-013 and NFR-003; direct model-factory callers must not cause oversized strings/tag lists to be trimmed or copied before the documented size limits are applied.
- **Implementation:** `SavedItem.fromMap` now checks raw string field lengths and tag count/tag lengths before normalizing fields or copying tags. This complements the strict backup and repository raw-record guards while retaining current normalization of valid-size legacy values.
- **Regression:** TC-221 supplies oversized title/tag fields directly to the model factory and expects fixed validation errors; ordinary model round-trip and in-limit tag normalization remain part of the existing suite.
- **Verification:** Regression source is committed but unrun. Confirm direct factory behavior and legacy import compatibility at the manual validation checkpoint.

### TSK-510 — Bound direct URL and search helper input

- **Requirements:** FR-005/FR-006 and NFR-003; helpers callable outside the visible form should enforce the same size limits before trimming or lowercasing raw input.
- **Implementation:** `parseUserWebUrl` and `parseHttpUrl` now reject URL strings longer than the portable 4,096-character limit before trimming. `SavedItem.matchesQuery` and `SavedItem.matchesNormalizedQuery` reject over-limit queries before normalization or scanning saved fields; the existing UI still supplies its explanatory validation state.
- **Regression:** TC-222 covers oversized direct URL helper calls and model search queries, and confirms ordinary URL/search behavior is unchanged.
- **Verification:** Regression source is committed but unrun. Validate direct helper, form and Search UI behavior at the manual checkpoint.

### TSK-511 — Bound legacy collection preference recovery scans

- **Requirements:** FR-010, FR-015 and NFR-003; malformed local metadata must not force an unbounded scan during app initialization, and recovery must preserve valid saved-item assignments.
- **Implementation:** Repository collection recovery now inspects at most 10,000 raw preference entries in one pass. Once the 500 portable collection slots are occupied, it counts the remaining raw entries as skipped without traversing them. Entries beyond the scan cap are also counted; the original preference list is not rewritten during recovery.
- **Regression:** TC-223 supplies 10,001 repeated entries, confirms the skipped count, preserves a valid collection assignment from a saved item, and verifies the raw preference list remains intact.
- **Verification:** Regression source is committed but unrun. Validate the bound, recovery banner and stored-data behavior on web/Android at the manual validation checkpoint.

### TSK-512 — Sanitize invalid provider file-URI errors

- **Requirements:** FR-009 and NFR-002/NFR-003; external share provider paths must fail safely without exposing raw URI or platform exception details in review feedback.
- **Implementation:** File-share intake now catches URI-to-local-path conversion failures and emits fixed recovery guidance before filename/MIME/byte processing continues. The share queue can record the short app-owned hint in its bounded summary instead of collecting a provider-specific exception message.
- **Regression:** TC-224 supplies a file URI with a non-local authority and expects the fixed safe error message. TC-174 separately covers fingerprinting behavior for unusual file URIs.
- **Verification:** Regression source is committed but unrun. Confirm valid local file URIs, actual Android provider paths and batch-continuation behavior at the manual validation checkpoint.

### TSK-513 — Bound share-review summary hint processing

- **Requirements:** FR-009 and NFR-002/NFR-003; after a malformed or unsupported batch, recovery feedback should stay concise and should not normalize arbitrarily large or unbounded collections of hint text.
- **Implementation:** `buildShareReviewSummary` now inspects at most `maxShareReviewHintCandidates` (16) hints, rejects any hint longer than `maxShareReviewHintCharacters` (160) before trimming it, and still displays at most three distinct safe hints.
- **Regression:** TC-225 covers skipping a large whitespace-only hint before trim and limiting how many entries are pulled from an iterable.
- **Verification:** Regression source is committed but unrun. Confirm summary text and accessibility on Android at the manual validation checkpoint.

### TSK-514 — Prevent overlapping backup export and restore actions

- **Requirements:** FR-012/FR-013 and NFR-003; users should not start competing file picker/share-sheet flows, and backup/restore should clearly indicate which operation is active.
- **Implementation:** Backup & privacy prevents export from starting while backup selection/restore is active and prevents restore from starting while export is active. The opposite action is disabled with an activity label exposed as a live region, and both handlers enforce the same guard.
- **Regression:** TC-226 pauses backup preparation and verifies the Restore button is disabled with a live-region status; TC-227 pauses the backup file picker and verifies export is disabled/announced until picker cancellation; the existing restore-commit regression checks Create backup is disabled.
- **Verification:** Widget test source is committed but unrun. Verify operation transitions and real Android/web picker/share-sheet handoff at the manual validation checkpoint.

### TSK-515 — Release the backup JSON string before share-sheet await

- **Requirements:** FR-012 and NFR-003/NFR-007; exporting a portable backup should avoid retaining avoidable full-size serialized representations while waiting for a user-controlled platform share flow.
- **Implementation:** After encoding the backup JSON into UTF-8 bytes, Backup & privacy clears its local reference to the JSON string before awaiting SharePlus. The byte payload remains the data passed to the share sheet.
- **Regression/manual check:** TC-228 verifies UTF-8 backup payload integrity and asks for a peak-memory review while the share sheet remains open.
- **Verification:** Source change is committed but no platform export or memory profile has run. Validate representative large backups on web and Android at the manual checkpoint.

### TSK-516 — Handle Item Details attachment-read failures

- **Requirements:** FR-011 and NFR-002/NFR-003; opening or sharing a saved attachment must not expose internal storage errors or leave an uncaught async exception.
- **Implementation:** Item Details now catches failures from the repository attachment read, shows safe local-storage/retry guidance, and checks that the route is still mounted before continuing to the system share sheet.
- **Regression:** TC-229 injects an unexpected repository read error while opening a saved document, checks safe feedback/no raw diagnostic leak, and verifies the original record and bytes remain intact.
- **Verification:** Widget regression source is committed but unrun. Verify actual browser/Android storage-read errors and share recovery at the manual validation checkpoint.

### TSK-517 — Retry transient image-preview read failures

- **Requirements:** FR-011 and NFR-002/NFR-003; image preview should recover from transient local-storage failures without forcing the user to leave Item Details or losing the saved attachment.
- **Implementation:** The image-preview dialog now provides a **Retry preview** action when the repository read fails. It starts a fresh repository read and updates both the dialog's FutureBuilder and the page's cached future so reopening the preview uses the latest attempt.
- **Regression:** TC-230 injects a one-time attachment-read failure, checks safe feedback and hidden diagnostics, retries, and confirms the new read succeeds without a framework exception.
- **Verification:** Widget regression source is committed but unrun. Verify real read-error recovery and assistive-technology feedback on web/Android during the manual validation checkpoint.

### TSK-518 — Recover when native share-stream setup fails

- **Requirements:** FR-009 and NFR-002/NFR-003; platform share integration must fail safely without preventing ordinary manual capture or exposing plugin/channel diagnostics.
- **Implementation:** The native share-intake startup handler catches synchronous exceptions while requesting or subscribing to the live event stream and shows manual-capture guidance. The independent launch-time intent read is still attempted afterward, so cold-start shares can be salvaged when only stream initialization fails.
- **Regression:** TC-231 injects a stream setup exception, confirms the independent initial-share read still runs, checks recovery copy and hidden raw diagnostics, and confirms Library navigation is still available.
- **Verification:** Widget regression source is committed but unrun. Verify real plugin/channel failure behavior and normal share delivery on Android at the manual validation checkpoint.

### TSK-519 — Keep Quick Save navigation consistent while a picker is pending

- **Requirements:** FR-008 and NFR-003/NFR-006; cancel/back navigation must not discard a draft or leave an in-flight file-picker request attached to a dismissed form.
- **Implementation:** Quick Save's PopScope, app-bar Back button and Cancel action now block route navigation while either a save or attachment selection is pending. Type changes remain available during picker wait so an outdated picker result can still be invalidated by the existing revision guard. When the picker completes or is canceled, normal navigation resumes.
- **Regression:** TC-232 pauses the picker, checks Back/Cancel and system back are blocked, resolves the picker as canceled, and verifies navigation becomes available again.
- **Verification:** Widget regression source is committed but unrun. Confirm native picker cancellation/system-back behavior on Android and supported browser/desktop platforms during the manual validation checkpoint.

### TSK-520 — Preflight public SavedItem serialization

- **Requirements:** FR-001 and NFR-003; direct model helpers should enforce the same storage-size bounds before allocating copied serialization structures.
- **Implementation:** SavedItem.toMap() now checks raw title/content/URL/collection/attachment metadata dimensions plus tag count/length before copying tags into the returned map.
- **Regression:** TC-233 calls toMap() directly with an oversized title, an oversized tag and more than 100 tags, then confirms ordinary serialization still works.
- **Verification:** Regression source is committed but unrun. Validate model serialization alongside direct parsing and backup/repository validation at the manual checkpoint.

### TSK-521 — Bound direct SavedItem search-field processing

- **Requirements:** FR-005 and NFR-003/NFR-007; a public model search helper must not allocate lower-case copies of manually constructed oversized item fields.
- **Implementation:** SavedItem.matchesNormalizedQuery() now rejects overlong titles, content, URLs, collection names, tag values and excessive tag counts before building the searchable-field list or lowercasing stored values.
- **Regression:** TC-234 calls both search entry points with oversized direct model instances and confirms valid ordinary search remains intact.
- **Verification:** Regression source is committed but unrun. Validate alongside TC-221/TC-222/TC-233 and the search performance baseline at the manual checkpoint.

### TSK-522 — Validate timestamps in direct SavedItem parsing

- **Requirements:** FR-002 and NFR-003; parsed model timestamps must remain inside the supported DateTime range so property access cannot fail later from an out-of-range instant.
- **Implementation:** The date bounds now live alongside the SavedItem model and are reused by BackupCodec. SavedItem.fromMap() rejects integer timestamps outside the shared range before constructing the model, while existing in-range parsing behavior remains unchanged.
- **Regression:** TC-235 covers out-of-range createdAt/updatedAt values and an ordinary valid parse.
- **Verification:** Regression source is committed but unrun. Validate timestamp bounds in direct parsing, raw-record recovery, backup decode and save paths at the manual checkpoint.

### TSK-523 — Validate timestamps in direct SavedItem serialization

- **Requirements:** FR-002 and NFR-003; direct model serialization must preserve the same timestamp invariants enforced by parsing, repository writes and backup validation.
- **Implementation:** `SavedItem.toMap()` now rejects created/updated millisecond timestamps outside the shared supported DateTime range before returning a serialized map. It uses the same fixed error message as direct model parsing.
- **Regression:** TC-236 directly serializes invalid created/updated timestamps and confirms in-range values remain serializable.
- **Verification:** Model regression source is committed but unrun. Validate direct serialization, parsing, backup encode/decode and repository save together at the manual checkpoint.

### TSK-524 — Guard direct SavedItem date getters

- **Requirements:** FR-002 and NFR-003; invalid dates should fail consistently at public model boundaries rather than surfacing implementation-specific date-construction errors.
- **Implementation:** `SavedItem.createdAt` and `updatedAt` now route through a shared timestamp-range guard before constructing a local `DateTime`, using the same fixed `FormatException` as model parsing and serialization.
- **Regression:** TC-237 accesses the date getters on directly constructed models whose created/updated timestamps exceed the supported bounds, and retains an in-range control.
- **Verification:** Regression source is committed but unrun. Validate the model and repository timestamp paths together at the manual checkpoint.

| SH-003 | SCR-001 | TSK-534 / TSK-540 | TC-247, TC-260, bulk_actions_widget_test.dart, selected_items_export_test.dart | SOURCE + WIDGET REGRESSION SOURCE IMPLEMENTED — selected-only Markdown share path has success and safe-failure coverage; execution pending |

| SH-004 | SCR-001, SCR-002 | TSK-535 / TSK-541 | TC-253, TC-254, TC-261, bookmark_html_importer_test.dart, bookmark_import_widget_test.dart, library_csv_export_test.dart, selected_items_export_test.dart | SOURCE + UNIT/WIDGET REGRESSION SOURCE IMPLEMENTED — import preview/confirm/cancel covered by widget source; tests and platform verification pending |


### TSK-540 — Verify selected-only Markdown export flow

- **Requirement:** SH-003 bulk export; FR-018 and NFR-002/NFR-003.
- **Source:** Renamed the Library action to **Export selected** and introduced a test-only share callback so the payload and failure path can be tested without invoking a platform share sheet. Production continues to use the existing SharePlus flow.
- **Regression:** TC-260; `test/bulk_actions_widget_test.dart` verifies selecting/deselecting items, Markdown filename/MIME/content, excludes deselected records, and safe handling of share failure.
- **Scope:** Metadata and user-entered text only; attachment bytes are not embedded. The existing versioned JSON backup remains the full-recovery export.
- **Status:** Source and widget-test source committed to `main`; no formatter, analyzer, tests, builds, CI run, or device/browser check has been performed. CI remains manual-only.


### TSK-541 — Add preview-first browser bookmark import widget coverage

- **Requirements:** SH-004, FR-008, FR-010, NFR-002/NFR-003.
- **Source:** Added a test-only bookmark file picker seam while leaving production on the native file picker. Corrected singular/plural text in import preview and summary counts.
- **Regression:** TC-261 in `docs/test-plan.md`; `test/bookmark_import_widget_test.dart` confirms duplicate/invalid preview details, folder preservation, import-on-confirm, and no library or collection writes when the user cancels.
- **Status:** Source and regression test source are committed to `main`; formatting, analyzer, tests, builds and real-device/browser verification have not run. CI remains manual-only.


### TSK-542 — Scaffold isolated selectable-text PDF probe (SH-005)

- **Requirements:** FR-016; NFR-005, NFR-008 and local-first privacy constraints.
- **Source:** Added `tool/pdf_text_extraction_poc`, a separate Flutter package targeting `pdfrx 2.10.1`, with bounded in-memory PDF text extraction, a manual phrase-recall screen, and synthetic text-bearing/textless/malformed-input test source. Production `pubspec.yaml` is unchanged.
- **Regression:** TC-262 and `tool/pdf_text_extraction_poc/test/pdf_text_probe_test.dart`.
- **Status:** Source and test source are committed. Package resolution, tests, Android/Web builds, offline behavior, size and memory measurements remain pending. FR-016 remains BLOCKED; no OCR capability is implemented or claimed.


### TSK-543 — Add a local Rediscover filter for older unfinished items (SH-010)

- **Requirement:** FR-023, plus NFR-001/NFR-003.
- **Rule:** Include items created at least 14 days ago that are not marked Completed. Sort by creation time oldest first; edits to notes/progress do not make an old item appear newly saved.
- **Source:** Added `lib/services/rediscovery.dart`, the Library **Rediscover** choice chip, explanatory rule text, and oldest-first sorting. The normal Library remains unchanged; clearing the filter returns to the usual view.
- **Regression:** TC-263; `test/rediscovery_test.dart` covers the cutoff, completion exclusion, edit-time independence and ordering; `test/rediscovery_widget_test.dart` covers the visible filter.
- **Privacy/scope:** Local-only; no reminder, background task, permission, sync or external-site activity monitoring was added.
- **Status:** Source and regression source committed to `main`; tests, formatter, analyzer, builds and platform checks remain pending. CI remains manual-only.
## SH-006 reader-mode traceability addition — 2026-10-29

| Feature slice | Design / requirements | Planned tests | Implementation status |
|---|---|---|---|
| User-initiated temporary article reader | SCR-004; FR-006, FR-011, FR-024; NFR-002, NFR-005, NFR-008 | TC-264–TC-268 | Design gate documented in `docs/research/article-reader-feasibility.md`; source NOT STARTED; tests planned and unrun |
| Selection-based quote/highlight anchoring | SCR-004; FR-024; NFR-006 | Add tests after Android/web rendering feasibility is established | NOT STARTED; no reliable cross-platform selection behavior claimed |

## SH-006 implementation mapping — 2026-10-29

| Requirement / behavior | Source | Regression evidence | Status |
|---|---|---|---|
| Explicit user-initiated reader access | lib/main.dart, lib/screens/article_reader_page.dart | TC-264 planned; not run | Source implemented, verify pending |
| URL restrictions, standard ports and native destination checks | lib/services/article_reader.dart, lib/services/article_reader_io.dart | test/article_reader_test.dart; TC-265 partial source, not run | Source implemented, verify pending |
| Bounded content and safe plain-text rendering | lib/services/article_reader_io.dart, lib/screens/article_reader_page.dart | sanitizer tests authored; TC-266 planned | Source implemented, verify pending |
| No fetched-content persistence / honest browser limitation | reader service and screen | TC-267–TC-268; test/article_reader_repository_test.dart | Source assertions cover JSON backup, CSV and selected-Markdown full-body exclusion; not run, platform verification pending |
| Selection-based quote capture with bounded context and UTF-16 offsets | lib/screens/article_reader_page.dart, lib/main.dart, lib/models/saved_item.dart | test/saved_item_test.dart covers round-trip/legacy/invalid metadata; not run | Source implemented, platform verification pending |

## SH-006 deterministic transport mapping — 2026-10-29

| Behavior | Implementation / seam | Regression source | State |
|---|---|---|---|
| DNS/private address policy | lib/services/article_reader_io.dart; articleReaderDnsResolverForTesting | test/article_reader_test.dart: reserved IPv4 matrix plus private and mixed DNS answers | Authored, not run |
| HTTP status/redirect/MIME policy | ArticleReaderTransportResponse; articleReaderTransportForTesting | synthetic redirect, error status and unsupported MIME cases | Authored, not run |
| Response/display caps and deadline | native response reader and single absolute deadline | synthetic oversize/display-cap and DNS/transport timeout cases | Authored, not run |
| Text-only extraction | shared sanitizeArticleMarkup and response parser | synthetic semantic article, hostile and malformed-unclosed markup, and Unicode cases | Authored, not run |
| Unchanged item and no persisted article body | Item Details/repository boundary | test/article_reader_repository_test.dart covers no implicit fetch, unchanged fields after open, selected-quote-only persistence, and backup exclusion of full article body; text exports/platform checks pending | Partial test source, not run |

## SH-006 visible feedback traceability — 2026-10-29

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Highlight success confirmed on visible Reader route | lib/screens/article_reader_page.dart | test/article_reader_repository_test.dart | Authored, not run |
| Failed highlight save stays recoverable and keeps the selection for retry | lib/screens/article_reader_page.dart | test/article_reader_page_test.dart | Authored, not run |


## SH-006 text-encoding refinement — 2026-10-29

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Decode explicit Windows-1252 / cp1252 without misrendering euro/punctuation bytes and keep Latin-1 distinct | lib/services/article_reader_io.dart (_decodeText) | TC-269; synthetic quoted charset response in test/article_reader_test.dart | Source + test authored; not run |


## SH-006 export-boundary regression update — 2026-10-29

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Preserve selected quote annotation but never add the complete temporary article body to backup, CSV or selected Markdown | Existing repository/export codecs | test/article_reader_repository_test.dart; TC-267 | Source assertions authored; not run; platform/share checks pending |


## SH-006 accessibility source update — 2026-10-29

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Expose Reader loading/save progress and article/error headings to assistive technology | lib/screens/article_reader_page.dart | TC-268; test/article_reader_page_test.dart | Source plus loading-label and delayed save-progress assertions authored; not run; platform accessibility verification pending |


## SH-006 entity-decoding traceability update — 2026-10-29

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Decode common text entities once while preventing recursive unescaping | `sanitizeArticleMarkup` in lib/services/article_reader.dart | TC-266; named/case-insensitive, hex numeric and escaped-ampersand assertions in test/article_reader_test.dart | Source and test authored; not run; platform rendering pending |
| Expose save-progress semantics while a highlight callback is pending | lib/screens/article_reader_page.dart | TC-268; delayed-save case in test/article_reader_page_test.dart | Source and widget test authored; not run; screen-reader checks pending |


## SH-006 semantic extraction traceability update — 2026-10-29

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Strip active blocks/comments before semantic article extraction so fake markup cannot shadow the real article | `sanitizeArticleMarkup` in lib/services/article_reader.dart | TC-266; `ignores fake article containers inside scripts and comments` in test/article_reader_test.dart | Source and test authored; not run; browser/native behavior pending |


## SH-006 sanitizer integrity follow-up — 2026-10-29

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Keep one coherent reader URL/sanitizer/loader definition; strip active/comment/navigation markup before semantic extraction and normalize non-printing controls | lib/services/article_reader.dart | TC-266; `test/article_reader_test.dart` fake-container and control-character cases | Source integrity reviewed by re-fetch; regression source authored but not run; platform checks pending |


## SH-006 document-title extraction traceability — 2026-10-29

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Exclude title-shaped text inside scripts/comments when extracting document title | `_extractTitle` in `lib/services/article_reader_io.dart` | TC-266; `extracts a real title instead of title-looking script or comment text` in `test/article_reader_test.dart` | Source and test authored; not run; native/browser verification pending |


## SH-006 UTF-8 BOM decoding traceability — 2026-10-29

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Remove the leading UTF-8 BOM before displaying native Reader text | `_decodeText` in `lib/services/article_reader_io.dart` | TC-270; `strips a leading UTF-8 BOM from reader text` in `test/article_reader_test.dart` | Source and regression authored and re-fetched; not executed; platform checks pending |


## SH-006 Unicode-safe Reader truncation traceability — 2026-10-29

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Enforce article/title length caps without splitting a UTF-16 surrogate pair | `_truncateAtUnicodeBoundary` in `lib/services/article_reader_io.dart` | TC-271; `does not split a supplementary Unicode character at the text cap` in `test/article_reader_test.dart` | Source and regression authored and re-fetched; not executed; platform checks pending |


## SH-006 title Unicode boundary traceability — TC-272 — 2026-10-29

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Cap extracted title text without splitting a UTF-16 surrogate pair | `_truncateAtUnicodeBoundary` called from `_extractTitle` in `lib/services/article_reader_io.dart` | TC-272; `does not split a supplementary Unicode character at the title cap` in `test/article_reader_test.dart` | Source and regression authored and re-fetched; not executed; platform checks pending |


## SH-006 HTML meta charset traceability — TC-273/TC-274 — 2026-10-29

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| When HTTP charset is absent, detect a bounded early direct HTML meta charset | _charsetFromHtmlMeta in lib/services/article_reader_io.dart | TC-273; uses an early HTML meta charset when the response omits charset | Source/test authored and re-fetched; not run; platform verification pending |
| When HTTP charset is absent, detect a bounded early legacy http-equiv/content charset | _charsetFromHtmlMeta in lib/services/article_reader_io.dart | TC-274; reads legacy charset from an early http-equiv meta tag | Source/test authored and re-fetched; not run; platform verification pending |


## SH-006 embedded charset filtering traceability — TC-275 — 2026-10-29

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Ignore meta-like charset hints in comments and script/style/noscript blocks during bounded HTML prescan | _charsetFromHtmlMeta in lib/services/article_reader_io.dart | TC-275; ignores charset-looking tags inside scripts and comments | Source and regression committed together; not executed; native/web validation pending |


## SH-006 HTTP charset precedence traceability — TC-276 — 2026-10-30

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Prefer an explicit HTTP Content-Type charset over a conflicting HTML meta charset | `_parseResponse` in `lib/services/article_reader_io.dart` | TC-276; `prefers the HTTP charset over an HTML meta charset` in `test/article_reader_test.dart` | Existing precedence source is covered by a new regression; not executed; native/web validation pending |


## SH-006 bounded charset prescan limit traceability — TC-277 — 2026-10-30

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Ignore HTML meta charset declarations located after the first 1,024 response bytes | `_charsetFromHtmlMeta` in `lib/services/article_reader_io.dart` | TC-277; `ignores HTML meta charset declarations beyond the 1024-byte prescan` in `test/article_reader_test.dart` | Existing byte bound is covered by a new regression; not executed; native/web validation pending |


## SH-006 meta charset attribute parsing — TC-278/TC-279 — 2026-10-30

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Ignore charset-like text inside unrelated meta name/content attributes | \`_charsetFromHtmlMeta\` and \`_parseMetaAttributes\` in \`lib/services/article_reader_io.dart\` | TC-278; \`ignores charset-like text in unrelated meta attributes\` in \`test/article_reader_test.dart\` | Parser source and regression committed; not executed; native/web validation pending |
| Continue to a real direct charset attribute after unrelated metadata | \`_charsetFromHtmlMeta\` and \`_parseMetaAttributes\` in \`lib/services/article_reader_io.dart\` | TC-279; \`continues scanning after unrelated meta content to find a real charset\` in \`test/article_reader_test.dart\` | Parser source and regression committed; not executed; native/web validation pending |


## SH-006 Unicode-safe Reader selection capture — TC-280–TC-282 — 2026-10-30

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Expand selection endpoints that fall between UTF-16 surrogate code units so saved quote and offsets include a complete Unicode character | \`captureArticleReaderSelection\` in \`lib/services/article_reader.dart\`; used by \`lib/screens/article_reader_page.dart\` | TC-280; \`expands selection edges that split a supplementary Unicode character\` in \`test/article_reader_test.dart\` | Source and regression committed; not executed; Reader/platform verification pending |
| Keep bounded before/after context excerpts on Unicode character boundaries | \`captureArticleReaderSelection\` in \`lib/services/article_reader.dart\` | TC-281; \`keeps context window edges outside supplementary Unicode characters\` in \`test/article_reader_test.dart\` | Source and regression committed; not executed; Reader/platform verification pending |
| Reject collapsed and out-of-range selection offsets before producing an annotation payload | \`captureArticleReaderSelection\` in \`lib/services/article_reader.dart\` | TC-282; \`rejects collapsed or out-of-range Reader selections\` in \`test/article_reader_test.dart\` | Source and regression committed; not executed; Reader/platform verification pending |


## SH-006 conservative annotation re-anchoring — TC-283–TC-287 — 2026-10-30

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Ignore saved offsets and find a unique exact quote in freshly fetched text | \`findSavedAnnotationAnchor\` in \`lib/services/annotation_reanchoring.dart\` | TC-283; \`finds one exact quote without trusting its old offset\` in \`test/annotation_reanchoring_test.dart\` | Source and regression committed; not run |
| Disambiguate repeated quote occurrences only when one has a uniquely stronger contiguous before/after context score | \`findSavedAnnotationAnchor\` in \`lib/services/annotation_reanchoring.dart\` | TC-284; \`uses saved surrounding context to distinguish repeated quotes\` in \`test/annotation_reanchoring_test.dart\` | Source and regression committed; not run |
| Leave tied, weak-context and missing quote results without a recommended position | \`findSavedAnnotationAnchor\`; \`ArticleReaderPage._anchorStatusCard\` | TC-285; ambiguous/missing service and Reader UI cases | Source and widget/unit regression committed; not run |
| Update offset/context only after an explicit user action, preserving annotation identity, quote, note and creation time | \`ArticleReaderPage._updateSavedAnchor\`; \`ItemDetailsPage._updateReaderAnnotationAnchor\` in \`lib/main.dart\` | TC-286; Reader page and repository re-anchor widget tests | Source and integration regression committed; not run |
| Reject unsupported quote/context/article sizes and bound returned candidates | \`findSavedAnnotationAnchor\` in \`lib/services/annotation_reanchoring.dart\` | TC-287; invalid/oversized/overlapping input cases | Source and unit regression committed; not run |


### TC-286 verification detail — preview is non-mutating

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Opening a locate-quote Reader preview leaves the complete saved item map unchanged until the user confirms Update saved position | \`ItemDetailsPage._openArticleReader\`; repository remains unchanged unless \`_updateReaderAnnotationAnchor\` is called | \`locating a quote does not change saved annotation metadata before confirmation\` in \`test/article_reader_repository_test.dart\` | Test source committed; not run |


### SH-006 stale annotation update protection — TC-288 — 2026-10-30

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Reject a position update when the current annotation quote no longer matches the quote originally opened in Reader, even if its annotation ID is unchanged | \`ItemDetailsPage._updateReaderAnnotationAnchor\` in \`lib/main.dart\`; expected quote supplied by \`ArticleReaderPage\` | TC-288; \`does not apply a stale re-anchor after the saved quote changes\` in \`test/article_reader_repository_test.dart\` | Source and repository regression committed; not run |


### SH-006 re-anchored backup/export compatibility — TC-289 — 2026-10-30

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Re-anchored offsets/context survive the versioned JSON backup round trip, while saved annotation quote/note are included in CSV/Markdown and the fetched page body remains transient | \`SavedAnnotation.toMap/fromMap\`; \`BackupCodec\`; \`buildLibraryCsv\`; \`buildSelectedItemsMarkdown\`; temporary Reader state remains separate from \`SavedItem.content\` | TC-289; \`explicitly re-anchors a saved quote without changing its text or note\` in \`test/article_reader_repository_test.dart\` | Source regression committed; not run |


### SH-006 stale anchor snapshot protection — TC-290 — 2026-10-30

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Reject a re-anchor update if the same annotation ID and quote now carry different saved offsets/context from the snapshot opened in Reader | \`ItemDetailsPage._updateReaderAnnotationAnchor\` compares the current record with the complete expected \`SavedAnnotation\` quote/offset/context snapshot | TC-290; \`does not apply a stale re-anchor after the saved position changes\` in \`test/article_reader_repository_test.dart\` | Source and repository regression committed; not run |


### SH-006 Reader interactive-widget filtering — TC-291/TC-292 — 2026-10-30

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Remove closed form, button, select, textarea and dialog blocks before semantic article extraction while preserving article headings and paragraphs | `sanitizeArticleMarkup` in `lib/services/article_reader.dart` | TC-291; `removes closed forms and interactive widgets but preserves article text` in `test/article_reader_test.dart` | Source and regression committed; not run |
| Remove the remainder of an unclosed form or interactive widget so malformed page tails are not shown as article text | `sanitizeArticleMarkup` in `lib/services/article_reader.dart` | TC-292; `does not leak the tail of an unclosed form or interactive widget` in `test/article_reader_test.dart` | Source and regression committed; not run |


### SH-006 balanced semantic-container extraction — TC-293/TC-294 — 2026-10-30

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Extract all content inside the first complete outer article despite nested article tags; ignore tag-like strings contained inside quoted attributes | `_extractFirstBalancedElementContents` called from `sanitizeArticleMarkup` in `lib/services/article_reader.dart` | TC-293; `keeps the complete outer article when article elements are nested` in `test/article_reader_test.dart` | Source and regression committed; not run |
| Use balanced nesting for main fallback so a nested main closing tag does not truncate the outer main content | `_extractFirstBalancedElementContents` called from `sanitizeArticleMarkup` in `lib/services/article_reader.dart` | TC-294; `keeps the complete main container when main elements are nested` in `test/article_reader_test.dart` | Source and regression committed; not run |


### SH-006 block-structure preservation — TC-295 — 2026-10-30

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Convert structural block boundaries (including blockquotes, figures, lists, table sections/rows/cells and headings) to plain-text line separators while keeping inline elements compact | `sanitizeArticleMarkup` in `lib/services/article_reader.dart` | TC-295; `preserves block boundaries for quotes, figures, lists and table cells` in `test/article_reader_test.dart` | Source and regression committed; not run |


### SH-006 quote-aware HTML tag stripping — TC-296 — 2026-10-31

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Strip an entire complete HTML tag token while respecting quoted attribute values containing `>`; map structural elements to line breaks and inline elements to spaces | `_stripHtmlTagsPreservingBlockBoundaries` in `lib/services/article_reader.dart` | TC-296; `does not leak quoted attribute text while stripping block and inline tags` in `test/article_reader_test.dart` | Source and regression committed; not run |


### SH-006 malformed quoted-tag tail handling — TC-297/TC-298 — 2026-10-31

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Preserve readable content before an unfinished tag, then discard the malformed remainder when a double-quoted attribute does not close | `_stripHtmlTagsPreservingBlockBoundaries` in `lib/services/article_reader.dart` | TC-297; `drops the tail after an unterminated double-quoted tag attribute` in `test/article_reader_test.dart` | Source and regression committed; not run |
| Apply the same safe fallback to an unclosed single-quoted attribute containing `>` | `_stripHtmlTagsPreservingBlockBoundaries` in `lib/services/article_reader.dart` | TC-298; `drops the tail after an unterminated single-quoted tag attribute` in `test/article_reader_test.dart` | Source and regression committed; not run |


### SH-006 malformed tag/declaration handling — TC-297–TC-299 — 2026-10-31

| Behavior | Source | Regression source | Status |
|---|---|---|---|
| Preserve readable content before an unfinished tag, then discard the malformed remainder when a double-quoted attribute does not close | `_stripHtmlTagsPreservingBlockBoundaries` in `lib/services/article_reader.dart` | TC-297; `drops the tail after an unterminated double-quoted tag attribute` in `test/article_reader_test.dart` | Source and regression committed; not run |
| Apply the same safe fallback to an unclosed single-quoted attribute containing `>` | `_stripHtmlTagsPreservingBlockBoundaries` in `lib/services/article_reader.dart` | TC-298; `drops the tail after an unterminated single-quoted tag attribute` in `test/article_reader_test.dart` | Source and regression committed; not run |
| Remove DOCTYPE/declaration and processing-instruction tokens from whole-document plain-text fallback | `_stripHtmlTagsPreservingBlockBoundaries` in `lib/services/article_reader.dart` | TC-299; `does not expose document declarations when no semantic container exists` in `test/article_reader_test.dart` | Source and regression committed; not run |


| TSK-549 / TC-300 | SH-006, NFR-002 | Reader active-content filtering honors quoted attribute delimiters before and after semantic extraction. | `test/article_reader_test.dart` — TC-300 | Source committed; execution pending manual validation. |
