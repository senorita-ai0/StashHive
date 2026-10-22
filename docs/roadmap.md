# StashHive — Roadmap and Implementation Plan

**Status:** Implementation in progress — Phase 3 platform assurance; Phase 2 sharing/build validation remains pending. Blueprint approved on 2026-10-21; validation workflow is intentionally manual-only.

## Milestones

### M0 — Blueprint approval and feasibility spikes

| Task | Scope | Requirements | Status | Exit criteria |
|---|---|---|---|---|
| TSK-001 | Review/approve requirements, platform split, MVP exclusions | All | DONE | User approves `docs/BLUEPRINT_REVIEW.md` or requests a revision. |
| TSK-002 | Verify current local Flutter/Dart and Android toolchain | NFR-009 | NOT STARTED | Record versions and `flutter doctor` output; no SDK upgrade without reason. |
| TSK-003 | Compare storage candidates on Android + web | FR-012–015, NFR-003, NFR-007 | NOT STARTED | Create/read/update/delete, tags, migrations, 1k/10k metadata benchmark, browser restart, export/restore concept pass. |
| TSK-004 | Android share-intent spike for URL/text/image/file | FR-009 | IN PROGRESS | At least one source app successfully shares each supported MIME type; cancellation/error behaviors documented. |
| TSK-005 | OCR/PDF extraction feasibility spike | FR-016, NFR-005, NFR-008 | NOT STARTED | Compare offline options for language support, sample accuracy, binary-size increase, latency and memory. No library commitment until results. |
| TSK-006 | Backup format proof of concept | FR-012–013 | IN PROGRESS | Versioned manifest plus files restores on a clean test profile; corrupt archive rejected safely. |
| TSK-007 | Expand competitor scan from screenshot apps to mixed-content libraries and validate the proposed differentiator | RSK-008, product success definition | IN PROGRESS | Record direct competitors, repeated negative-review themes, evidence links, and user test questions; do not claim a gap based only on a short search. |

### M1 — Foundation and capture

| Task | Scope | Requirements | Status | Exit criteria |
|---|---|---|---|---|
| TSK-101 | Initialize Flutter project, analysis options, formatting and test structure | NFR-009 | IN PROGRESS | Android and web debug builds run; analysis/test commands documented and successful. |
| TSK-102 | Implement domain entities and storage repository behind an interface | FR-001–003, FR-010 | IN PROGRESS | CRUD and migration tests pass; restart persistence works. |
| TSK-103 | Build design-system tokens and responsive navigation | FR-004, FR-011, NFR-006 | IN PROGRESS | Library, Search, Collections, Settings navigation works at mobile and desktop widths. |
| TSK-104 | Manual save/edit flows for link and note | FR-002, FR-006–007 | IN PROGRESS | Validation, offline use, editing and search tests pass. |
| TSK-105 | Add image and document/file import on supported platforms | FR-001, FR-008 | IN PROGRESS | File MIME/size validation, storage, restart, deletion and error states tested. |

### M2 — Library and retrieval

| Task | Scope | Requirements | Status | Exit criteria |
|---|---|---|---|---|
| TSK-201 | Unified list, type filters, favorites, sort, empty/error/loading states | FR-004 | IN PROGRESS | UI/integration tests cover each filter and no-result state. |
| TSK-202 | Metadata search and Unicode test matrix | FR-005, NFR-005, NFR-007 | IN PROGRESS | Tests for English, Urdu-script user-entered text, Roman Urdu, emoji, accents and punctuation pass. |
| TSK-203 | Item details, tags, collections, favorites | FR-010–011 | IN PROGRESS | Collection/tag edits remain consistent after restart; deletion semantics tested. |
| TSK-204 | Android share intake integration | FR-009 | IN PROGRESS — source added; build/device validation pending | The supported share formats from TSK-004 work end-to-end and do not duplicate on repeated event delivery. |
| TSK-205 | Extracted text indexing if POC passes | FR-016 | BLOCKED | Starts only after TSK-005 passes and user approves any material increase in app size/scope. |

### M3 — Data portability and hardening

| Task | Scope | Requirements | Status | Exit criteria |
|---|---|---|---|---|
| TSK-301 | Implement versioned export archive | FR-012 | IN PROGRESS | Backup contains manifest, metadata, attachments and version; paths and sizes validated. |
| TSK-302 | Implement restore and conflict strategy | FR-013 | IN PROGRESS | Valid archive restored; corrupt/unknown-version archives rejected with no partial corruption. |
| TSK-303 | Platform-specific web persistence and data-loss messaging | FR-015 | NOT STARTED | Same browser profile reload retains test data; different browser does not imply sync; clearing-data warning is clear. |
| TSK-304 | Privacy, accessibility and security review | FR-018, NFR-002, NFR-006 | NOT STARTED | Permission list justified; no saved-content logs; keyboard/contrast/large-text checklist complete. |
| TSK-305 | Performance and recovery regression suite | NFR-003, NFR-007–009 | NOT STARTED | Benchmark report and known limits documented; key flows recover from interrupted operations. |

### M4 — Closed validation, monetization decision, release readiness

| Task | Scope | Requirements | Status | Exit criteria |
|---|---|---|---|---|
| TSK-401 | Opt-in user test and feedback review | Product success definition | NOT STARTED | Users complete save/search/retrieve/backup tasks; key confusion points fixed. |
| TSK-402 | Decide monetization after usage validation | Out of MVP | NOT STARTED | Separate approval for ads or premium; no SDK before its cost/privacy/store implications are reviewed. |
| TSK-403 | Store/domain/trademark/package ID and release checklist | Release gate | NOT STARTED | Public brand is checked; build/sign/store requirements are verified for target platform. |
| TSK-404 | Release candidate build and smoke tests | All Musts | NOT STARTED | Real Android device and web browser test results recorded; no hidden critical blockers. |


## Suggested development order (updated 2026-10-21)

1. **Phase 1 — Core local library:** source is implemented. Historical CI passed analyzer, tests and web build; the Android APK failed because the generated runner could not resolve FilePickerPlugin. StashHive now pins file_picker 12.3.0 as an unverified mitigation.
2. **Phase 2 — Capture and recovery:** validate Android URL/text/image/document share intake; add repository persistence, attachment, restore and manifest tests.
3. **Phase 3 — Platform assurance:** compare screens against the SVGs; validate browser persistence and real-device file/share flows; improve accessibility, backup recovery and performance.
4. **Later phases:** consider OCR only after an offline feasibility study, then run the full manual validation workflow at the owner's release checkpoint.

## Release gate

MVP must not be described as ready until create/edit/delete, link open, supported attachment import, metadata search, restart persistence, backup/restore, platform limitations, privacy, and target-device/browser smoke tests have evidence recorded in the traceability matrix.



## Phase 2 — capture from other Android apps (started 2026-10-21)

| Task | Scope | Status | Exit criteria |
|---|---|---|---|
| TSK-204 | Register supported Android share intents; receive incoming URL/text/image/document and prefill Quick Save | IN PROGRESS — sequential multi-item source added; device test pending | Share from browser/text app/files app; review each supported item one at a time; unsupported/oversized entries are skipped with feedback; confirm save/cancel flows. |
| TSK-306 | Repository persistence and attachment restore regression tests | IN PROGRESS — tests added, manual run pending | Saved data survives Hive reopen; attachment survives restore with an ID collision; collection deletion keeps its items. |
| TSK-307 | Idempotent Android manifest configurator and tests | IN PROGRESS — source added, Python test pending | Adds supported MIME filters once, sets singleTask, and fails clearly if MainActivity is missing. |
| TSK-308 | Manual-only validation workflow | DONE | Workflow only has workflow_dispatch; commits/pushes do not trigger builds. |
| TSK-309 | Resolve historical Android FilePickerPlugin registration/build failure | IN PROGRESS — file_picker 12.3.0 declared; manual Android build pending | The generated Android runner compiles and produces a debug APK with incoming-share filters registered. |

| TSK-310 | Strict backup decoding and failed-import regression coverage | IN PROGRESS — source/tests added, manual run pending | Invalid item shapes, malformed collections and unreferenced attachments are rejected; a malformed mixed batch writes no records; assigned collection references survive round-trip. |
| TSK-311 | Restore write-phase rollback | IN PROGRESS — rollback strengthened and fault-injection test added; manual run pending | An exception after staged item/attachment writes removes imported payloads and preserves pre-existing data and collection preferences; real device/storage interruption remains documented. |
| TSK-312 | Preserve attachments on failed item edits | IN PROGRESS — save rollback strengthened and fault-injection test added; manual run pending | If the item map write fails after replacement bytes are staged, the prior item and attachment are preserved; new staged bytes are removed when there were no prior bytes. |
| TSK-313 | Recover from item deletion failures and protect shared attachment references | IN PROGRESS — rollback/source tests added; manual run pending | A deletion failure attempts to restore the item and attachment; referenced attachments are not removed; fault-injection tests pass. |
| TSK-314 | Roll back save errors reported after storage writes | IN PROGRESS — item/attachment rollback and fault-injection test added; manual run pending | A failed save attempts to restore the previous saved-item map and attachment values even when a write may already have taken effect. |
| TSK-315 | Platform-aware backup storage messaging and single-flight restore UI | IN PROGRESS — source added; platform verification pending | Browser users see browser-profile/site-data warnings; Android users see app/device warnings; restore cannot be started twice and busy states are accessible. |
| TSK-316 | Match Library title wrapping to the approved responsive reference | IN PROGRESS — source adjusted; visual check pending | Long titles wrap to two lines on item cards without obscuring actions at narrow widths or large text scaling. |
| TSK-317 | Scale Library/Search result cards with system text settings | IN PROGRESS — shared layout helper and unit tests added; run pending | Card heights grow with system text scaling for two-line titles and metadata, remain bounded for invalid/extreme scales, and pass visual checks on web and Android. |
| TSK-318 | Expose saved-image and favorite state to assistive technology | IN PROGRESS — semantic labels and widget test authored; verification pending | Favorite markers and saved-image previews have meaningful semantics and pass TalkBack/web screen-reader review without duplicate announcements. |
| TSK-319 | Make the Library search teaser accessible as a navigation button | IN PROGRESS — semantics and widget test authored; verification pending | The search-shaped control is announced as a button with a clear name/hint, not as an editable text field, and responds to keyboard/pointer activation. |
| TSK-320 | Announce Search result-count changes to assistive technology | IN PROGRESS — live-region semantics and widget regression authored; run pending | Search result counts expose a single live status such as “1 result” or “0 results” as query/filter results change; screen-reader announcement behavior is manually verified. |
| TSK-321 | Give saved-item action menus item-specific accessible names | IN PROGRESS — contextual tooltip and command-activation regression authored; run pending | Every card's action menu identifies the item and View details/Add to favorites both invoke the expected action. |

The owner requested development first and builds at the final checkpoint. Do not dispatch GitHub Actions unless the owner explicitly asks for validation. A successful manual workflow will retain the web build and Android debug APK artifacts for 14 days.


## Phase 2 refinement — 2026-10-21

Share de-duplication happens at event intake using a short three-second window. This suppresses near-simultaneous initial-intent/stream duplicates while allowing a later deliberate re-share. The new regression test is authored but intentionally unrun; CI remains manual-only.


## Android toolchain follow-up — 2026-10-21

The previous manual-run candidate failed with a missing FilePickerPlugin symbol in generated Android registration. Updated file_picker from 11.0.3 to 12.3.0 based on upstream notes indicating the AGP 9 registration fix is in 12.x. Keep this task IN PROGRESS until a later manually requested Android build confirms the result; no workflow was dispatched for this change.


## Multi-item share handling — 2026-10-21

Share batches are now presented as sequential Quick Save drafts instead of silently preparing only the first item. Each draft shows its position in the batch. A skipped unsupported or unreadable item reports feedback and does not prevent later supported items from being offered. This is source-complete but still requires manual Dart tests and Android device verification; workflow_dispatch remains the only CI trigger.


## Backup integrity increment — 2026-10-21

TSK-310 adds strict shape/type checks ahead of model construction, validates collection and attachment metadata, rejects unattached payload blobs, and preserves item-assigned collection names in backup round-trips. Regression tests are authored but unrun. Storage interruption after the write phase begins remains a separate recovery test, not claimed as solved.


## Restore rollback increment — 2026-10-21

TSK-311 hardens restore cleanup after a failure during the write phase. Imported identifiers are selected against both item and attachment box keys, every staged entry is eligible for rollback, and cleanup attempts continue even if one delete fails. A test-only fault-injection hook covers failure just before collection preference commit. This is not claimed as crash-atomic storage behavior until manual tests have run.


## Attachment edit integrity — 2026-10-21

TSK-312 addresses a data-loss path in save(): replacement bytes previously overwrote the old attachment before the item record was committed, and a failed record write deleted that key. Save now snapshots the existing attachment and best-effort restores it on failure; a test seam covers the failure between attachment staging and record commit. CI remains manual-only; this regression has not been run.

### Item deletion integrity — 2026-10-21

TSK-313 adds best-effort rollback if item deletion fails after attachment bytes may have been removed. Delete also checks raw stored item maps before removing an attachment so unreadable records referencing the same key protect its payload. Regression tests are authored but remain unrun; this does not guarantee atomicity under process death or persistent storage failure.

### Save post-write failure integrity — 2026-10-21

TSK-314 marks item and attachment writes as attempted before awaiting the storage operation. When a save fails, it attempts to restore the prior saved-item map or remove a new record, in addition to restoring attachment bytes. An in-process fault-injection test covers a failure after the item record write; Dart tests and platform storage behavior are still unverified.

## Phase 3 — platform assurance started (2026-10-21)

TSK-315 begins source-level platform hardening. Backup & Privacy communicates browser-local storage correctly on web, uses platform-specific data-loss messaging, and disables duplicate restore activation before the picker opens. This does not verify browser quota handling, keyboard/screen-reader behavior, or actual Android/web flows; those remain manual validation tasks. Phase 2 sharing and build checks are still pending.

### Phase 3 responsive Library card refinement — 2026-10-21

TSK-316 adjusts saved-item titles to wrap onto two lines before truncating, following the SCR-001 required long-title state. The responsive result still needs visual inspection at narrow widths and with enlarged text; no screenshot comparison has been marked passed.

### Phase 3 — text scale-aware result layout (2026-10-21)

TSK-317 introduces `savedItemCardExtentForTextScale` and applies it consistently to Library and Search result grids. At the default scale, cards use a 120 logical-pixel extent; larger text scales increase the extent within a fixed upper bound. Helper tests are authored but unrun. Actual large-text and responsive visual inspection remains pending.

### Phase 3 — accessible saved-item labels (2026-10-21)

TSK-318 adds title-based semantic labels to image thumbnails and detail previews, plus an explicit favorite-state label in Library/Search cards. A widget regression test is authored. Assistive-technology checks remain pending and should confirm that labels are useful without being announced twice.

### Phase 3 — accessible Library search control (2026-10-21)

TSK-319 changes the decorative search field on the Library page into a clearly named semantic navigation button while retaining the existing visual style. Its child TextField is excluded from semantics because it is not editable; the actual Search tab contains the editable query field. The widget regression test is authored but has not been executed.


### Phase 3 — semantic activation regression — 2026-10-21

- The Library search accessibility widget test now performs the control's semantic tap action and verifies that the Search navigation callback is invoked, rather than checking only that a tap action exists.
- Semantics handles are registered for teardown so a failed assertion does not leave test semantics enabled. Test source is authored; execution remains pending. Keyboard, pointer and assistive-technology behavior still require validation.


### Phase 3 — live Search result status — 2026-10-22

- Search result counts now expose a live-region semantic label (for example, “1 result” and “0 results”) so assistive technology can detect updates while a query changes. The visible result-count styling is retained, and its child text is excluded from semantics to avoid duplicate announcements.
- A widget regression covers the matching and no-match states and checks the live-region flag. It is authored but unrun; actual announcement timing and verbosity still need screen-reader review.


### Phase 3 — contextual saved-item action labels — 2026-10-22

- Saved-item overflow menus now use an item-specific tooltip (“Actions for [title]”) rather than the same generic label on every card. This helps distinguish action menus when browsing a long library with assistive technology.
- A widget regression checks the contextual tooltip and that the menu exposes “Add to favorites” and “View details”. The test is authored but unrun; TalkBack and web screen-reader checks remain pending.


### Phase 3 — saved-item menu command regression — 2026-10-22

- Strengthened the TSK-321 widget test to seed an item, activate “View details” and verify the details callback, then activate “Add to favorites” and verify repository state changes. This checks command behavior, not only visible menu labels.
- Regression source is authored but intentionally unrun; CI stays manual-only. Keyboard focus order and screen-reader usability remain platform-validation items.


### Phase 2 — share-event deduplication edge coverage (2026-10-22)

- **TSK-322:** Added regression coverage for ordered multi-item share batches and the bounded recent-fingerprint cache. A reversed batch must be treated as a distinct event; an identical recent batch is suppressed; adding a different batch at capacity evicts the oldest fingerprint.
- Test source is committed but unrun. Android event delivery and cold-start/stream duplicate behavior remain pending device verification. Phase 2 remains open until the full validation gates pass.


### Phase 2 — bounded incoming-share progress (2026-10-22)

- **TSK-323:** `IncomingShare.withShareProgress` now clamps the displayed position to the normalized total as well as enforcing a minimum of one. Malformed progress values can no longer report a position beyond the batch size.
- Added regression cases for zero/negative-style lower-bound input, position greater than total, and an invalid total. Test source is committed but unrun; Phase 2 remains open pending full test and Android validation.


### Phase 2 — collision-safe share-event fingerprints (2026-10-22)

- **TSK-324:** Share events are serialized as canonical ordered JSON and represented in the cache by a SHA-256 digest. The cache stores fixed-size fingerprints rather than retaining full shared text/path payloads; canonical fields avoid delimiter ambiguity, and SHA-256 avoids relying on Dart's small integer object hashes.
- Added regression coverage for two distinct batches whose values could alias under a simple delimiter scheme. Source and test are committed but unrun; device delivery checks remain pending and Phase 2 is still open.


### Phase 3 — nonlinear text-scale layout factor (2026-10-22)

- **TSK-325:** Library and Search result-card extents now derive their layout scale from the system-scaled 14 logical-pixel body font instead of sampling at 1 pixel. This better reflects accessibility scaling when the platform uses nonlinear text scaling.
- Added unit coverage for normalizing scaled sizes and safe fallback values. Source and tests are committed but unrun; large-text visual inspection on Android and web remains pending.


### Phase 2 — multi-select MIME coverage (2026-10-22)

- **TSK-326:** Expanded the generated Android manifest configurator so SEND_MULTIPLE offers every MIME family supported by single-share intake, not only images. Added test assertions that generated action/MIME pairs are exact and that multi-select coverage mirrors single-share coverage.
- This enables supported homogeneous text, URL, and document batches to reach the existing sequential Quick Save flow. Python regression tests and Android chooser/device behavior are committed but unrun; Phase 2 remains open pending manual validation.


#### TSK-324 hardening — bounded fingerprint storage (2026-10-22)

- Added the `crypto` package and changed the deduplication cache key to a SHA-256 digest of canonical JSON. Only the 64-character digest remains in the short-lived cache rather than the serialized shared text/path.
- The dependency is declared as `crypto: ^3.0.7`; test/build resolution remains pending because CI is manual-only.


### Phase 2 — shared attachment backup/restore integrity (2026-10-22)

- **TSK-327:** Backup export now counts a shared attachment key only once toward the attachment budget, rather than counting the same byte payload for every saved-item reference. Export also rejects image/document records without a valid attachment key and rejects attachment keys on unsupported item types instead of emitting a backup that cannot be restored.
- Restore now maps each original attachment key to one collision-safe key and stages its bytes only once, preserving relationships between items that intentionally share a stored attachment. Per-item filename/MIME metadata takes precedence when present, with payload metadata used as a fallback.
- Added codec and repository regressions for shared references and invalid export references. Tests are authored but unrun; source-level rollback does not claim crash-atomic storage behavior.


### Phase 2 — distinguish share context when URLs match (2026-10-22)

- **TSK-328:** The canonical share fingerprint now includes the platform-provided message as well as media type, path and MIME type. Two intentional shares of the same URL with different accompanying text are no longer collapsed as duplicates, while identical initial-intent/stream deliveries remain deduplicated.
- Added a regression for same-path/different-message events. Test source is committed but unrun; confirm message parity from real Android source apps during device validation.


### Phase 3 — theme-aware muted-text contrast (2026-10-22)

- **TSK-329:** Replaced the single muted foreground color with theme-aware colors. Light theme muted text now uses `#646C82` (about 5.0:1 on the `#F8F9FD` canvas and 5.2:1 on white); dark theme uses `#AAB2C5` (about 8.4:1 on `#131724` and 7.1:1 on `#202638`). This addresses the previous muted color's 3.5:1 contrast on the light canvas.
- Added widget regressions that calculate contrast against the actual theme canvas and input surface. Test source is committed but unrun; full visual/assistive-technology review remains pending.


### Phase 2 — shared-link boundary punctuation (2026-10-22)

- **TSK-330:** URL extraction from shared text removes trailing punctuation and unmatched closing brackets/parentheses while preserving balanced parentheses commonly found in real URL paths. The bracket-counting pass is linear-time to avoid repeated scans on long shared messages.
- Added regressions for a wrapped URL and a legitimate URL ending in a balanced parenthesis. Test source is committed but unrun; validate against real Android share payloads during the manual checkpoint.


### Phase 2 — backup attachment integrity checksums (2026-10-22)

- **TSK-331:** Newly encoded backups now carry a SHA-256 checksum for each unique attachment payload. Restore validates the checksum after base64 decoding, detecting changed bytes even when the payload remains syntactically valid base64. Existing version-1 backups without the optional checksum remain importable.
- Added regressions for checksum output, modified-byte rejection and legacy version-1 compatibility. Tests are authored but unrun; backup recovery is not marked verified until manual validation.


### Phase 2 — precise shared-text limit messaging (2026-10-22)

- **TSK-332:** The intake guard is character-count based, so its error now says “1,000,000-character limit” rather than “1 MB,” which is misleading for non-ASCII and emoji content.
- The unit regression now checks the actual error copy. Test source is committed but unrun.


### Phase 2 — avoid turning single-word shares into URLs (2026-10-22)

- **TSK-333:** Scheme-less text is only inferred to be a web link when the parsed host looks domain-like (contains a dot) or is `localhost`. Plain text such as `remember` stays a note, while bare domains and domain-plus-port values continue to normalize to HTTPS links.
- Added regressions for a single word, a bare domain and a bare domain with an explicit port. Tests are authored but unrun; Android-source-app behavior remains part of manual share validation.


### Phase 2 — normalize event identity before share deduplication (2026-10-22)

- **TSK-334:** Share-event fingerprints now trim path/message whitespace and normalize MIME types to lowercase before canonical JSON serialization and SHA-256 hashing. This suppresses harmless representation differences between equivalent intake payloads while retaining meaningful message differences and ordered batch boundaries.
- Added a regression for path padding, MIME case and message whitespace. Test source is committed but unrun; real initial-intent/stream payload parity still needs Android verification.


### Phase 2 — mixed-MIME Android share batches (2026-10-22)

- **TSK-335:** Added a `SEND_MULTIPLE` `*/*` manifest filter because Android may use the wildcard MIME type for mixed file batches. The intake queue still validates each item individually and skips unsupported entries with feedback.
- Updated the manifest regression to require wildcard coverage as well as all supported single-share MIME families. Python regression source is committed but unrun; verify chooser visibility and per-file MIME resolution on a real Android device.


### Phase 3 — contrast-safe item-type badges (2026-10-22)

- **TSK-336:** Added a separate darker `readableTextAccent` for small item-type labels while preserving the original accents for icons and borders on other surfaces. Link, note, image and document labels now exceed 4.5:1 contrast against their pastel badge fills.
- Library, Quick Save and Item Details use the readable label accent. Added a regression across every `ItemKind`; tests are authored but unrun, and visual theme checks remain pending.


### Phase 3 — favorite-state icon contrast (2026-10-22)

- **TSK-337:** The saved-favorite star now uses a theme-aware foreground: a deeper amber on light surfaces and a brighter gold on dark surfaces. This improves contrast without forcing the gold into an unsuitable shade for both themes.
- Added contrast checks for the star color against theme surfaces, canvas and input fill. Regression source is committed but unrun; manual visual review remains pending.


### Phase 2 — standalone URL punctuation cleanup (2026-10-22)

- **TSK-338:** Standalone shared URLs now pass through the same punctuation cleanup as URLs extracted from longer text. A trailing sentence period no longer becomes part of the saved URL; balanced parentheses in URL paths remain supported.
- Added a standalone URL regression. Test source is committed but unrun; real chat/browser share payloads still need Android verification.


### Phase 2 — incoming URL and context size parity (2026-10-22)

- **TSK-339:** Incoming URL shares and URLs embedded in shared text now enforce the backup format's 4,096-character URL maximum. Typed URL shares also enforce the existing 1,000,000-character limit on accompanying message/context text, preventing drafts that would later be rejected by backup validation.
- Added boundary coverage for a 4,096-character URL, an over-limit URL, and oversized context attached to a URL share. Test source is committed but unrun.


### Phase 2 — shared attachment intake regression coverage (2026-10-22)

- **TSK-340:** Expanded share-intake regression coverage to exercise actual local file reads for a text document and an image, reject an unsupported `.exe` share, and reject a file larger than 15 MiB based on its length before reading its contents.
- Tests use isolated temporary directories and clean them up even when assertions fail. Source is committed but unrun; Android content URI/permission behavior remains a device-validation requirement.


### Phase 2 — attachment invariants during item edits (2026-10-22)

- **TSK-341:** `LibraryRepository.save` independently enforces that only image/document kinds may carry attachment references, that both kinds require a valid key, and that provided bytes respect the 15 MiB cap. After a successful edit it best-effort deletes a no-longer-referenced old payload, but keeps bytes if another readable or unreadable raw item still references them.
- Quick Save preserves an existing item's attachment key during metadata-only edits and does not reuse stale attachment metadata if an attachment-bearing kind is changed by a caller. The current edit screen keeps item kind fixed; changing kind through the UI is not part of this slice.
- Added repository regressions for kind/reference invariants, orphan cleanup and shared-reference preservation. Tests are authored but unrun; filesystem interruption behavior remains pending.


### Phase 2 — shared saved-item validation across save/export/restore (2026-10-22)

- **TSK-342:** Added a single saved-item validator used by repository saves and backup encoding/decoding. URL length, title/content/tags, collection metadata, attachment metadata and item-kind/attachment consistency are checked before data is committed or exported, so StashHive no longer intentionally emits backups its own decoder would reject for these field rules.
- Quick Save now gives a clear 4,096-character URL limit message, and the saved URL limit is defined once in the model and reused by incoming-share handling and backup validation.
- Added regressions for overlong saved URLs and attachment metadata that would fail restore. Tests are committed but unrun; validate the full save/export/restore path at the manual checkpoint.


### Phase 2 — Quick Save shared-attachment edit regression (2026-10-22)

- **TSK-343:** Quick Save now keeps an item's existing attachment key for metadata-only edits, including when the key belongs to another item that owns shared bytes. Choosing replacement bytes asks the repository for a collision-safe key so another item's shared payload is not overwritten.
- The Quick Save widget regression covers metadata-only edits. Direct repository tests in TC-048 cover removing attachment references, reclaiming orphaned bytes and preserving payloads still referenced by another item. All tests are committed but unrun.


### Phase 2 — shared MIME mapping for selected and shared files (2026-10-22)

- **TSK-344:** Centralized extension-to-MIME guessing in `lib/services/mime_types.dart`; Quick Save's file picker and OS share intake now use the same mapping. Added BMP, HEIC/HEIF and TIFF mappings that were previously missing or inconsistent.
- Added direct MIME-helper tests and a share-intake regression for TIFF content with generic MIME metadata. Tests are committed but unrun; actual platform file support still needs device verification.


### Phase 2 — Quick Save validation feedback (2026-10-22)

- **TSK-345:** Quick Save now normalizes URL scheme casing before persistence and validates the same tag count/length limits enforced by repository/backup validation. It shows actionable messages for URLs that exceed 4,096 characters and tags beyond 100 tags / 100 characters per tag.
- Added widget regressions for uppercase HTTPS input and both tag-boundary errors. Source and tests are committed but unrun.


### Phase 2 — size-first file-picker intake (2026-10-22)

- **TSK-346:** Quick Save uses file_picker 12.x's single-file `pickFile()` API, checks length first, then consumes `readAsByteStream()` through a hard-capped reader so inaccurate lengths cannot cause unbounded allocations. It rejects zero/unknown-size selections with a clear recoverable message and performs a second post-read size check.
- This reduces unnecessary allocation for oversized local/web selections. Source is committed but unrun; verify web picker behavior with lazy `readAsBytes()`, Android gallery/SAF reads, cancellation and cloud-backed files during the manual platform checkpoint.


### Phase 2/3 — guard external navigation for legacy saved URLs (2026-10-22)

- **TSK-347:** Added a shared `parseHttpUrl` boundary that accepts only HTTP/HTTPS URLs with a host and normalizes scheme casing. Quick Save, backup item validation and Item Details external navigation use it; a malformed legacy record can no longer send `javascript:`, `file:` or other non-web schemes to the platform launcher.
- Added unit coverage for uppercase schemes, invalid/hostless URLs, whitespace-bearing values and dangerous schemes. Test source is committed but unrun; end-to-end external-launch behavior remains part of manual verification.


### Phase 2 — reject empty/corrupt attachment payloads (2026-10-22)

- **TSK-348:** Repository saves now reject empty attachment bytes, non-byte integer values, and missing/empty/unreadable stored payloads. Backup encode and decode reject empty attachment payloads so an image/document cannot be marked as having a valid local attachment when no usable bytes exist.
- Added repository and backup-codec regression tests. Source and test cases are committed but unrun; behavior for interrupted storage writes still requires the manual validation checkpoint.


### Phase 2 — fail safely on damaged legacy attachment bytes (2026-10-22)

- **TSK-349:** `readAttachment` now returns no payload for empty, non-integer or out-of-byte-range stored values instead of silently filtering bad entries. Backup export validates stored bytes before conversion and surfaces a recoverable damage message instead of silently producing a different payload/checksum.
- Added a repository regression that corrupts a legacy stored attachment, verifies reads do not return a partially filtered file, and verifies backup export fails with a clear message. Test source is committed but unrun.


### Phase 2 — copy-on-write keys for shared attachment replacements (2026-10-22)

- **TSK-350:** Quick Save now asks the repository for a safe attachment key before writing replacement bytes. If the preferred item-ID key already stores an orphaned payload or is referenced by another raw record (even when that record's bytes are missing), it allocates an unused key rather than overwriting or healing data under another saved item's reference.
- Added repository tests for shared-key preservation, the normal unshared-key path, collisions with orphaned payloads, and missing-but-still-referenced legacy keys. Source/test are committed but unrun; validate replacement-file behavior on Android/web during the manual checkpoint.


### Phase 3 — selected item-kind semantics in Quick Save (2026-10-22)

- **TSK-351:** Quick Save's Link/Note/Image/Document options now expose button semantics and the currently selected option through the selected state, while keeping the visual tiles and pointer interactions intact.
- Added a widget regression that checks the selected state and activates another choice through the semantics action. Test source is committed but unrun; TalkBack and browser screen-reader confirmation remain pending.


### Phase 2/3 — legacy URL launch guard widget coverage (2026-10-22)

- **TSK-352:** Added a widget regression that injects a non-web URL into raw storage as if it were a legacy record, opens Item Details and verifies the safe rejection message appears instead of the external-launch failure message.
- Test source is committed but unrun; external app/browser launch behavior remains pending the manual checkpoint.


### Phase 2 — resolve conflicting MIME headers from recognized extensions (2026-10-22)

- **TSK-353:** Incoming share intake now prefers the inferred MIME type for recognized supported file extensions when the platform's MIME header conflicts. This keeps stored content type aligned with the filename-based classification and avoids saving a text document as a PNG (or vice versa).
- Added a file-based regression for a PNG labelled `text/plain` and a TXT file labelled `image/png`. Test source is committed but unrun; real Android share metadata remains a manual validation item.


### Phase 3 — responsive Quick Save item-kind selector (2026-10-22)

- **TSK-354:** The Link/Note/Image/Document selector now wraps into two columns on narrow layouts or when enlarged system text would crowd the labels; roomy desktop layouts retain four columns. Labels can occupy two lines instead of always truncating after one.
- Added a widget regression at 2× text scale to verify the second row exists, all four controls remain semantically available and no layout exception is reported. Source/test committed but unrun; device visual checks remain pending.


### Phase 2 — distinguish bare web addresses from explicit URI schemes (2026-10-22)

- **TSK-355:** Added shared `parseUserWebUrl` logic for URL fields and incoming shares. It supports ordinary bare domains and numeric host ports by applying HTTPS, but rejects explicit schemes such as `javascript:`, `file:`, `mailto:`, and malformed `http:example.com` instead of trying to reinterpret them as hosts.
- Quick Save's field validator and save handler, plus ShareIntake, now use the same parser; strict `parseHttpUrl` remains the separate boundary for persisted URLs and external navigation. Added unit/widget regressions; tests are committed but unrun.


### Phase 2/3 — reject credential-bearing saved URLs (2026-10-22)

- **TSK-356:** The strict HTTP/HTTPS parser now rejects URL user-info such as embedded usernames/passwords. This applies to Quick Save, shared URL intake, backup validation and external launch because they share the same parsing boundary.
- Added a unit regression for a credential-bearing URL. Test source is committed but unrun.


### Phase 2 — inline feedback for overlong URLs (2026-10-22)

- **TSK-357:** Quick Save's URL field now reports the 4,096-character URL limit during form validation, before the save attempt, while the save/repository validators remain as backstops.
- Added a widget regression confirming an over-limit value shows the inline error and writes no item. Test source is committed but unrun.


### Phase 2 — tag-field integrity across repository and backups (2026-10-22)

- **TSK-358:** Shared saved-item validation now rejects empty tags and tags with surrounding whitespace, aligning direct repository writes and backup encode/decode with Quick Save's normalized tag behavior.
- Added repository and backup-codec regressions. Tests are committed but unrun.


### Phase 2 — collision-safe ID allocation (2026-10-22)

- **TSK-359:** Quick Save now requests a repository-generated ID absent from both the item and attachment stores and not referenced by any raw item as an attachment key, including legacy references whose payload is missing. Replacement attachment keys reuse the same uniqueness check.
- Added repository coverage for generated ID uniqueness against existing record/payload keys. Test source is committed but unrun.


### Phase 2 — strict validation while reloading local records (2026-10-22)

- **TSK-360:** Repository reload validates raw field types and confirms each Hive key matches the record ID. It keeps parseable legacy records visible—even when a URL or attachment is invalid—so Item Details can show safe open/missing-file feedback; truly malformed shapes are skipped without preventing valid entries from loading.
- Added a repository regression that seeds an unknown item kind and a box-key/record-ID mismatch, then verifies the valid record still loads. Test source is committed but unrun.


### Phase 2 — visible warning for skipped malformed local records (2026-10-22)

- **TSK-361:** The repository now tracks the count of raw local records skipped during refresh. The Library shows a live-region warning with the count, explains that raw entries were not intentionally deleted, clarifies that new backups may omit unreadable records, and recommends using a previous backup for recovery.
- Added repository and Library widget regressions for the count and warning. Source/tests are committed but unrun; confirm recovery wording and behavior against real corrupted storage before release.


### Phase 2 — repository-level shared-payload write protection (2026-10-22)

- **TSK-362:** `LibraryRepository.save` now rejects an attachment-byte write when another raw saved-item record references the same attachment key. The guard protects shared data even if a caller bypasses Quick Save's copy-on-write key selection.
- Added a repository regression proving the attempted write is rejected, the record remains unchanged, and shared bytes remain intact. Test source is committed but unrun.


### Phase 2 — bound raw field sizes during recovery (2026-10-22)

- **TSK-363:** Local reload now applies explicit size bounds to item ID, title, content, URL, collection and attachment metadata before presenting a stored record. Parseable legacy semantic issues (for example a non-web URL or missing attachment) stay visible; raw values that exceed structural limits are skipped and included in the recovery warning count.
- Expanded the repository regression with an oversized legacy note payload. Test source is committed but unrun.


### Phase 3 — contrast-safe inactive Quick Save type labels (2026-10-22)

- **TSK-364:** Item-kind labels now use a darker, readable foreground on light surfaces; on dark surfaces, unselected labels use their light pastel foreground, while selected labels retain the readable dark shade on the selected pastel chip.
- Expanded the contrast regression across every item type and the selected/unselected light/dark surface combinations. Test source is committed but unrun; manual visual inspection remains pending.


### Phase 2 — bounded validation for stored attachment bytes (2026-10-22)

- **TSK-365:** Extracted stored attachment byte checks into `isValidAttachmentByteList`. It rejects empty, malformed, out-of-range and oversized payloads, checks the 15 MiB length cap before iterating the list, and is reused by repository reads/backup.
- Added unit coverage using a lazy oversized list to verify the size guard does not enumerate elements. Test source is committed but unrun.


### Phase 2 — missing attachment recovery feedback in Item Details (2026-10-22)

- **TSK-366:** Added widget regressions for parseable legacy image/document records whose referenced bytes are missing. Image details should show the missing-image state; document open/share should advise restoring a backup, without throwing or silently removing the record.
- Test source is committed but unrun; actual corrupted storage and user recovery behavior remain pending.


### Phase 3 — theme-aware Quick Save kind icon contrast (2026-10-22)

- **TSK-367:** The item-kind selector now uses the readable dark accent for selected icons, the normal accent on light unselected surfaces, and the light pastel accent for unselected icons in dark mode. This aligns icon foregrounds with the tile background for each state.
- Extended the per-kind contrast regression to include decorative icon contrast as well as label text. Test source is committed but unrun.


### Phase 2 — deduplicate by effective share content (2026-10-22)

- **TSK-368:** The share-event fingerprint now reflects the fields actually consumed for each media type: effective text for text shares, URL plus context for URL shares, and path/MIME for file/image/video shares. Meaningful URL context still distinguishes intentional shares, while irrelevant provider metadata no longer creates duplicates.
- Added regressions for text path/message variation and unused file-message metadata. Test source is committed but unrun; verify actual plugin payloads on Android.


### Phase 2 — consistent case-insensitive tag identity (2026-10-22)

- **TSK-369:** Model deserialization now removes duplicate tags case-insensitively while preserving the first spelling. Strict repository saves and backup exports reject case-insensitive duplicate tags, matching Quick Save's existing behavior.
- Added model, repository and backup regression source. Tests are committed but unrun.


### Phase 2 — validate shared filename and MIME bounds at intake (2026-10-22)

- **TSK-370:** Incoming file shares now reject filenames over 255 characters and MIME metadata over 128 characters before attempting file reads. Empty basenames get a safe attachment-name fallback after supported type classification.
- Added share-intake regressions for oversized filename and MIME values. Tests are committed but unrun; real source-app metadata remains part of Android validation.


### Phase 2 — reject orphaned attachment metadata (2026-10-22)

- **TSK-371:** Strict saved-item validation now requires filename/MIME metadata to have an attachment key. This prevents stale fields from surviving through direct repository saves or being included in a portable backup after an attachment reference was removed.
- Added repository and backup-codec regressions. Tests are committed but unrun.


### Phase 2 — enforce non-empty note content at the shared boundary (2026-10-22)

- **TSK-372:** The shared saved-item validator now rejects empty or whitespace-only note content, matching Quick Save's existing form rule. Invalid programmatic saves and backup exports can no longer introduce blank-note records.
- Added repository and backup-codec regressions. Tests are committed but unrun.


### Phase 2 — timestamp bounds for safe local recovery (2026-10-22)

- **TSK-373:** Raw local-record reload, repository saves and backup encode/decode now share the DateTime-supported timestamp bounds. Out-of-range legacy records are skipped and counted instead of reaching date formatting with unusable values.
- Added reload, save and backup-codec regression source. Tests are committed but unrun.


### Phase 2 — protect orphan payloads at repository save boundary (2026-10-22)

- **TSK-374:** Repository save now refuses to write new bytes to an attachment key that already contains a payload unless that key is already the item's own current attachment key. Shared-reference checks still prevent in-place changes to shared bytes. This protects orphaned/corrupt payloads even when callers bypass Quick Save's safe-key helper.
- Added a direct repository regression proving a rejected save leaves both the new record absent and the orphan bytes unchanged. Test source is committed but unrun.


### Phase 2 — keep collection count within the portable backup limit (2026-10-22)

- **TSK-375:** The backup codec exposes a single 500-collection maximum and repository collection creation now enforces it. The UI can no longer grow the collection preference list beyond the portable-backup format's declared limit.
- Added a repository regression that reloads a full collection list, rejects collection 501, and confirms the list still round-trips through the backup codec. Test source is committed but unrun.


### Phase 2 — preflight merged collection limit during restore (2026-10-22)

- **TSK-376:** Restore now calculates the merged collection list and rejects an import that would push the destination library beyond the shared 500-collection backup limit before writing any imported records or attachments.
- Added a repository regression with a 500-collection destination and one new incoming collection, asserting the restore fails before importing the item or changing the collection list. Test source is committed but unrun.


### Phase 2 — portable saved-item count preflight (2026-10-22)

- **TSK-377:** Added a shared item-count guard for repository mutations. New item saves and backup restore now reject a destination that would exceed the codec's 10,000-item portable limit; editing an existing visible item remains allowed at capacity.
- Added boundary coverage for the shared count validator. Source/tests are committed but unrun.


### Phase 2 — reserve dangling attachment references during restore (2026-10-22)

- **TSK-378:** Backup restore now reserves attachment keys referenced by raw local records, even when the referenced payload is missing. Imported image/document IDs and their mapped attachment keys cannot accidentally populate a broken legacy item's missing file.
- Added a repository regression that restores an image whose original ID matches a dangling legacy attachment reference and confirms both the imported payload and the broken legacy reference remain separate. Test source is committed but unrun.


### Phase 2 — keep direct lookup consistent with recovery filtering (2026-10-22)

- **TSK-379:** `findById` now validates raw record field types/size and confirms the requested Hive key matches the embedded ID before returning a model. Malformed or mismatched raw entries cannot bypass `_refreshItems` by being queried directly, while parseable legacy records with unsafe URLs/missing payloads remain available for recovery feedback.
- The existing malformed-record repository regression now covers this lookup boundary too. Tests are committed but unrun.


### Phase 2 — recoverable update feedback for invalid legacy records (2026-10-22)

- **TSK-380:** Favorite actions in the Library card menu and Item Details now catch repository validation failures for parseable but invalid legacy data and explain that the item needs repair (correct URL or reselect missing file) instead of surfacing an unhandled exception.
- Added a widget regression that attempts to favorite an unsafe legacy URL and confirms the item remains unchanged while repair guidance is shown. Test source is committed but unrun.


### Phase 2 — size-first backup restore picker (2026-10-22)

- **TSK-381:** Backup & Privacy now uses the pinned file_picker single-file API, checks length first, and consumes `readAsByteStream()` through the 145 MiB capped reader. Empty/unknown-size and oversized selections receive explicit feedback.
- This also removes the old `FilePickerResult.files` access left behind by the dependency API migration. Source is committed but unrun; web and Android provider behavior remains a manual check.


### Phase 2 — normalize and report legacy collection preferences (2026-10-22)

- **TSK-382:** Collection reload now trims names, de-duplicates them case-insensitively, rejects malformed/oversized entries, and caps the visible list at the 500-collection backup limit. It exposes a skipped-entry count and shares the Library's live-region recovery banner with malformed saved records.
- Added repository tests for duplicate/malformed entries and a 501st legacy collection, plus a widget regression for the warning. Source/tests are committed but unrun.


### Phase 2 — avoid redundant attachment-buffer copies (2026-10-22)

- **TSK-383:** Shared-file intake now retains the buffer returned by `XFile.readAsBytes()`; Quick Save passes its picked `Uint8List` directly to the repository; restore staging reuses decoded attachment buffers rather than copying each payload again. This lowers peak allocation pressure near the 15 MiB per-file / 100 MiB combined limits.
- Existing intake, repository and backup round-trip tests already assert byte-for-byte preservation; source is committed but those tests remain unrun.


### Phase 2 — restore reachability of item-assigned collections (2026-10-22)

- **TSK-384:** Collection reload now merges valid collection names assigned on visible saved items with the preference list, deduplicating case-insensitively and preserving the 500-name cap. Legacy collection strings are trimmed in model deserialization; whitespace-only assignments normalize to unassigned. Save/delete refresh both item and collection notifiers so navigation stays current.
- Added model and repository regressions for collection normalization, preference-less assignments and backup portability. Test source is committed but unrun.


### Phase 2 — enforce collection cap through item assignment (2026-10-22)

- **TSK-385:** Repository save now rejects an item whose collection assignment would introduce a new name after the collection list reaches 500, closing a bypass around the Add Collection limit.
- Added a regression that seeds 500 collections, attempts a save with a new assigned name, and confirms no item is written. Test source is committed but unrun.


### Phase 3 — narrow-width Library header with enlarged text (2026-10-22)

- **TSK-386:** The Library brand title now obeys the available row width and uses a single-line ellipsis, preventing the logo/title/filter controls from forcing a horizontal overflow at narrow widths with enlarged text.
- Added a widget regression for Library and Search at 320×568 with 2× text scaling. Test source is committed but unrun; visual review remains part of the manual accessibility checkpoint.


### Phase 2 — align forced-image share MIME metadata (2026-10-22)

- **TSK-387:** When the operating system delivers an image share intent with a contradictory non-image MIME header and an unrecognized extension, intake keeps the intent's image classification but normalizes the MIME metadata to an image MIME when known, otherwise `application/octet-stream`.
- Added a file-based regression for an extensionless image share labelled `text/plain`. Test source is committed but unrun; real provider MIME behavior remains a manual Android check.


### Phase 2 — roll back collection creation after late storage errors (2026-10-22)

- **TSK-388:** `addCollection` now snapshots the preference key and previous value, then best-effort restores it if the storage call fails after taking effect. The collection notifier is refreshed on rollback and the original failure is rethrown.
- Added fault-injection coverage for failure after the write, including the case where no previous collection preference key existed. Test source is committed but unrun.


### Phase 2 — decode/validate backups once before confirmation (2026-10-22)

- **TSK-389:** Backup & Privacy now performs full `BackupCodec.decode` validation before showing the merge confirmation and passes the already decoded result to `restoreDecodedBackup`. The raw JSON string and file-byte reference are released before the confirmation dialog, avoiding a second full parse of large base64 attachments after confirmation.
- Existing restore/rejection/rollback repository tests cover the decoded path through `restoreBackup`; source is committed but tests remain unrun. Manual memory profiling remains pending.


### Phase 2 — consistent UTF-8 backup size limit (2026-10-22)

- **TSK-390:** Export and decode now enforce the portable backup cap in UTF-8 bytes as well as the in-memory character guard. The restore picker uses the same `BackupCodec.maxBackupBytes` constant, preventing Unicode-heavy backups from passing export but being rejected by file-size preflight.
- Added UTF-8 byte-count regressions for ASCII, Urdu/Arabic-script text and supplementary Unicode characters. Test source is committed but unrun.


### Phase 2 — release parsed base64 copies during backup decoding (2026-10-22)

- **TSK-391:** After each backup attachment is base64-decoded and its length/checksum are validated, the codec removes the encoded field from the temporary parsed JSON map. The returned `DecodedBackup` retains only the validated byte buffers and metadata, reducing memory held by a large restore.
- Existing backup checksum, byte-integrity and restore regressions cover the affected behavior. Test source is committed but unrun; peak-memory profiling remains pending.


### Phase 2 — preflight local attachment filename metadata (2026-10-22)

- **TSK-392:** Quick Save now rejects blank or over-255-character picker filenames before calling file length/byte reads, with specific guidance to rename invalid files. This aligns local picker intake with the repository/backup attachment-name limit.
- The real picker path requires Android/web manual verification; no build or test was run.


### Phase 2 — fingerprint normalized MIME for recognized file shares (2026-10-22)

- **TSK-393:** Share-event fingerprints now infer MIME from the filename first, mirroring intake when the extension is recognized. A `.png` delivered with `text/plain` and the same `.png` delivered with `image/png` therefore share the same fingerprint instead of opening duplicate drafts.
- Added a regression for equivalent extension-first file MIME metadata. Test source is committed but unrun; initial-intent/stream parity on actual Android apps remains pending.


### Phase 2 — canonicalize cross-type share fingerprints (2026-10-22)

- **TSK-394:** Share deduplication now treats a standalone URL received as text and as a URL intent as the same normalized URL draft. It also treats generic-file and image intents for the same image as the same image draft, when extension-first MIME resolution agrees. URL context remains part of URL fingerprints, and unsupported video events remain a separate category.
- Added cross-type URL/image deduplication regressions. Tests are committed but unrun; initial-intent/stream event behavior still needs Android verification.


### Phase 2/3 — reuse validated byte buffers for previews and file sharing (2026-10-22)

- **TSK-395:** `LibraryRepository.readAttachment` now returns a validated `Uint8List`; Library thumbnails, Item Details previews and file sharing consume that buffer directly instead of wrapping it in a second `Uint8List.fromList` copy.
- Existing repository byte-integrity assertions remain applicable. Test source is committed but unrun; preview/rebuild memory behavior still needs device profiling.


### Phase 2 — remove the duplicate byte buffer during backup export (2026-10-22)

- **TSK-396:** Backup & Privacy now passes the byte list returned by `utf8.encode` directly to `XFile.fromData` instead of copying the entire backup into a second `Uint8List`. This reduces peak allocation pressure for exports near the 145 MiB cap.
- Existing export/restore round-trip tests cover content integrity; source is committed but tests and large-backup memory profiling remain pending.


### Phase 2 — prevent silent partial backup exports (2026-10-22)

- **TSK-397:** Backup & Privacy now surfaces the skipped-record warning itself and asks for explicit confirmation before exporting a backup when malformed local records will be omitted. Canceling the dialog exits without sharing/exporting the partial file.
- Added a widget regression covering the visible warning, confirmation text and safe cancellation. Test source is committed but unrun.


### Phase 2 — confirm collection normalization omissions before backup export (2026-10-22)

- **TSK-398:** Backup & Privacy now includes invalid, duplicate and over-limit legacy collection entries in both its recovery banner and pre-export confirmation. The dialog explains that the export uses normalized valid names and that the raw local preferences remain untouched; canceling prevents the share flow.
- Added a widget regression that seeds both an unreadable record and malformed collection preferences, checks both counts/messages, and cancels the export. Test source is committed but unrun.


### Phase 3 — contextual names for collection and item-detail menus (2026-10-22)

- **TSK-399:** Added explicit tooltips/accessible names to Collection row action menus and the Item Details overflow menu, matching the contextual labeling already used by saved-item cards and other icon buttons.
- Added widget regressions that locate each menu by its accessible tooltip and activate it to reveal its actions. Test source is committed but unrun; screen-reader and keyboard validation remain open.


### Phase 2/3 — canonical collection spelling on reload and save (2026-10-22)

- **TSK-400:** Repository reload canonicalizes item collection assignments to the visible collection's spelling when names match case-insensitively. Direct repository saves do the same before validation/persistence, so items assigned to `learning` remain visible inside the existing `Learning` collection.
- Added a repository regression covering both a legacy raw record and a new save, including the stored representation. Test source is committed but unrun.


### Phase 2 — canonicalize incoming collection casing during restore (2026-10-22)

- **TSK-401:** Restore now maps incoming item collection assignments through the merged destination collection-name map before writing records. A backup assignment such as `learning` is persisted as the destination's existing `Learning`, not merely normalized in memory afterward.
- Added a repository regression asserting both the live model and raw Hive record use the canonical spelling. Test source is committed but unrun.


### Phase 2 — block backup export until overflow collection assignments are repaired (2026-10-22)

- **TSK-405:** Repository backup preflight now counts saved items whose collection assignment is not represented in the portable collection list and provides a targeted repair error. Backup & Privacy checks this condition before its partial-export confirmation and tells users to edit affected items to select an available collection or No collection.
- Added repository and widget regressions for a 500-collection legacy destination containing an item assigned to an unrepresentable 501st name. Test source is committed but unrun.


### Phase 2 — preserve partial-backup omission metadata through restore (2026-10-22)

- **TSK-406:** Backup export now writes both unreadable-record and legacy collection-entry omission counts into optional version-1 metadata. Decode validates those values and defaults either to zero for older backups. Restore confirmation explains both missing records and normalized/omitted collection data.
- Added codec round-trip/backward-compatibility coverage and repository coverage proving `createBackup()` populates both counts. Tests are committed but unrun.


### Phase 3 — case-insensitive Collection Contents filter (2026-10-22)

- **TSK-407:** Collection Contents now matches item collection assignments case-insensitively, so a legacy/in-memory `learning` assignment still appears under the visible `Learning` collection.
- Added a widget regression with a differently cased assignment. Test source is committed but unrun.


### Phase 3 — accessible Quick Save attachment picker (2026-10-22)

- **TSK-408:** The Quick Save attachment tile is now one named semantic button. It announces the current filename (or “Choose an image/document”) and explains whether it selects a first file or a replacement, including the 15 MB cap.
- Added a semantics widget regression for its accessible label, tap action and hint. Test source is committed but unrun; TalkBack/browser screen-reader confirmation remains pending.


### Phase 2 — bound legacy timestamps during local recovery (2026-10-22)

- **TSK-386:** Local-record shape validation now checks created/updated timestamps against the supported date range before making the record available to date formatting and detail views. Records with unrepresentable timestamps are skipped and included in the recovery banner rather than risking a later date-conversion exception.
- Extended the existing malformed-record regression to assert the bad timestamp is excluded from direct lookup too. Test source is committed but unrun.


### Phase 2 — validate decoded objects at the restore mutation boundary (2026-10-22)

- **TSK-387:** `restoreDecodedBackup` now revalidates in-memory objects before writing. The guard checks item fields/unique IDs, required attachment payloads and metadata, byte caps, omission counts, and collection name constraints; restore preflight also merges collection names assigned on items before enforcing the 500-name limit.
- Added codec/repository regressions for missing payloads, invalid attachment metadata, duplicate IDs, item-only collection assignments and pre-write collection overflow. Test source is committed but unrun.


### Phase 2 — preserve case-only collection duplicates in legacy backup restore (2026-10-22)

- **TSK-388:** The decoded-object validator now allows case-only duplicate collection labels that older version-1 exports could contain. Restore still de-duplicates names case-insensitively while merging, so recoverable legacy item data is not rejected just because the old collection list used inconsistent casing.
- Added a regression that mutates an otherwise valid v1 export to include `Learning` and `learning`, decodes it and confirms the restore preflight accepts it for normalization. Test source is committed but unrun.


### Phase 2 — bounded streaming reads for OS-shared files (2026-10-22)

- **TSK-389:** Shared-file intake now reads via `XFile.openRead()` into a bounded byte reader. It cancels the stream as soon as cumulative bytes would exceed 15 MiB, so a stale or unavailable provider length cannot trigger an unbounded `readAsBytes()` allocation.
- Added stream-reader tests for exact-limit acceptance and early cancellation at the first over-limit chunk. Test source is committed but unrun; real Android content-provider behavior remains pending.


### Phase 2 — normalize legacy item metadata on materialization (2026-10-22)

- **TSK-390:** `SavedItem.fromMap` now trims legacy titles, URLs and attachment filenames, and normalizes attachment MIME metadata to lowercase. This matches the normalization already applied to tags and collections and prevents surrounding whitespace/case drift from being carried into later edits/exports; URL scheme safety remains enforced separately at save/open boundaries.
- Added a model regression for padded title/URL/filename and mixed-case MIME metadata. Test source is committed but unrun.


### Phase 2 — bound file-picker streams for attachments and backups (2026-10-22)

- **TSK-391:** Quick Save and Backup & Privacy now use `PlatformFile.readAsByteStream()` with the shared capped reader. The 15 MiB attachment limit and 145 MiB backup limit are enforced while chunks arrive; initial length checks remain as an early rejection path.
- This closes the same stale-length memory-risk for local picker inputs that was addressed for OS-shared files. Stream-reader boundary tests are committed but unrun; validate browser, Android SAF and cloud-provider implementations during the manual checkpoint.


### Phase 2 — one source of truth for attachment size limits (2026-10-22)

- **TSK-392:** Quick Save and share intake now reference `BackupCodec.maxAttachmentBytes` rather than repeating the 15 MiB literal. The bounded byte reader uses the same cap and backup export/restore validates against that value.
- This prevents intake from accepting payloads that the portable backup layer would reject after a future limit change. Source committed; validation remains manual-only.


### Phase 2 — preflight base64 sizes against remaining backup budget (2026-10-22)

- **TSK-393:** Backup decode now estimates the maximum encoded length for the remaining combined attachment budget before calling `base64Decode`. Payloads that cannot fit under the 100 MiB combined attachment limit are rejected before allocating their decoded buffer.
- Added helper boundary tests for base64 quanta and negative inputs. Test source is committed but unrun; full-size backup memory profiling remains pending.


### Phase 3 — graceful fallback for image formats the platform cannot decode (2026-10-22)

- **TSK-394:** The full-size image dialog now displays an accessible “Preview unavailable” message when Flutter cannot decode the stored bytes, while retaining the saved attachment for sharing. This prevents otherwise valid files in less-supported image formats from producing a broken preview surface.
- Added an Item Details widget regression using invalid/unsupported encoded bytes; test source is committed but unrun.
