# StashHive — Requirement Traceability Matrix

**Status:** Design-level mapping; implementation and tests are not started. Update this file alongside every approved behavior change.

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
| NFR-006 | All screens | TSK-103, TSK-304 | UI/accessibility checklist | NOT STARTED |
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
