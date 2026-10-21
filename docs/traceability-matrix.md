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
