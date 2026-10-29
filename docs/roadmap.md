# StashHive — Roadmap and Implementation Plan

**Status:** Premium UI refresh and shared Flutter/Android source configuration are committed; Phase 2/3 platform assurance and release validation remain pending. Blueprint approved on 2026-10-21; validation workflow is intentionally manual-only.

## Milestones

### M0 — Blueprint approval and feasibility spikes

| Task | Scope | Requirements | Status | Exit criteria |
|---|---|---|---|---|
| TSK-001 | Review/approve requirements, platform split, MVP exclusions | All | DONE | User approves `docs/BLUEPRINT_REVIEW.md` or requests a revision. |
| TSK-002 | Verify current local Flutter/Dart and Android toolchain | NFR-009 | IN PROGRESS — the manual workflow pins Flutter/JDK and the generated runner configurator pins AGP/Gradle/Kotlin/SDK/JVM targets; actual toolchain/build confirmation remains pending | Record exact versions and `flutter doctor` output at the manual checkpoint; do not claim compatibility until the Android build succeeds. |
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
| TSK-303 | Platform-specific web persistence and data-loss messaging | FR-015 | IN PROGRESS — platform-specific data-loss copy and first-launch reminder added; browser restart/quota verification pending | Same browser profile reload retains test data; different browser does not imply sync; clearing-data warning is clear. |
| TSK-304 | Privacy, accessibility and security review | FR-018, NFR-002, NFR-006 | IN PROGRESS — source-level review recorded; platform/permission checks pending | No saved-content logging calls found in reviewed Dart sources; safe URL-launch validation and bounded import paths are source-covered. Still inspect merged Android permissions/network behavior and complete real-device/browser accessibility checks. |
| TSK-305 | Performance and recovery regression suite | NFR-003, NFR-007–009 | IN PROGRESS — baseline harness added; measurements and recovery verification pending | Capture 100/1,000/10,000-item baseline and verify recovery flows at the manual checkpoint. |

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

- **TSK-430:** Local-record shape validation now checks created/updated timestamps against the supported date range before making the record available to date formatting and detail views. Records with unrepresentable timestamps are skipped and included in the recovery banner rather than risking a later date-conversion exception.
- Extended the existing malformed-record regression to assert the bad timestamp is excluded from direct lookup too. Test source is committed but unrun.


### Phase 2 — validate decoded objects at the restore mutation boundary (2026-10-22)

- **TSK-431:** `restoreDecodedBackup` now revalidates in-memory objects before writing. The guard checks item fields/unique IDs, required attachment payloads and metadata, byte caps, omission counts, and collection name constraints; restore preflight also merges collection names assigned on items before enforcing the 500-name limit.
- Added codec/repository regressions for missing payloads, invalid attachment metadata, duplicate IDs, item-only collection assignments and pre-write collection overflow. Test source is committed but unrun.


### Phase 2 — preserve case-only collection duplicates in legacy backup restore (2026-10-22)

- **TSK-432:** The decoded-object validator now allows case-only duplicate collection labels that older version-1 exports could contain. Restore still de-duplicates names case-insensitively while merging, so recoverable legacy item data is not rejected just because the old collection list used inconsistent casing.
- Added a regression that mutates an otherwise valid v1 export to include `Learning` and `learning`, decodes it and confirms the restore preflight accepts it for normalization. Test source is committed but unrun.


### Phase 2 — bounded streaming reads for OS-shared files (2026-10-22)

- **TSK-433:** Shared-file intake now reads via `XFile.openRead()` into a bounded byte reader. It cancels the stream as soon as cumulative bytes would exceed 15 MiB, so a stale or unavailable provider length cannot trigger an unbounded `readAsBytes()` allocation.
- Added stream-reader tests for exact-limit acceptance and early cancellation at the first over-limit chunk. Test source is committed but unrun; real Android content-provider behavior remains pending.


### Phase 2 — normalize legacy item metadata on materialization (2026-10-22)

- **TSK-434:** `SavedItem.fromMap` now trims legacy titles, URLs and attachment filenames, and normalizes attachment MIME metadata to lowercase. This matches the normalization already applied to tags and collections and prevents surrounding whitespace/case drift from being carried into later edits/exports; URL scheme safety remains enforced separately at save/open boundaries.
- Added a model regression for padded title/URL/filename and mixed-case MIME metadata. Test source is committed but unrun.


### Phase 2 — bound file-picker streams for attachments and backups (2026-10-22)

- **TSK-435:** Quick Save and Backup & Privacy now use `PlatformFile.readAsByteStream()` with the shared capped reader. The 15 MiB attachment limit and 145 MiB backup limit are enforced while chunks arrive; initial length checks remain as an early rejection path.
- This closes the same stale-length memory-risk for local picker inputs that was addressed for OS-shared files. Stream-reader boundary tests are committed but unrun; validate browser, Android SAF and cloud-provider implementations during the manual checkpoint.


### Phase 2 — one source of truth for attachment size limits (2026-10-22)

- **TSK-436:** Quick Save and share intake now reference `BackupCodec.maxAttachmentBytes` rather than repeating the 15 MiB literal. The bounded byte reader uses the same cap and backup export/restore validates against that value.
- This prevents intake from accepting payloads that the portable backup layer would reject after a future limit change. Source committed; validation remains manual-only.


### Phase 2 — preflight base64 sizes against remaining backup budget (2026-10-22)

- **TSK-437:** Backup decode now estimates the maximum encoded length for the remaining combined attachment budget before calling `base64Decode`. Payloads that cannot fit under the 100 MiB combined attachment limit are rejected before allocating their decoded buffer.
- Added helper boundary tests for base64 quanta and negative inputs. Test source is committed but unrun; full-size backup memory profiling remains pending.


### Phase 3 — graceful fallback for image formats the platform cannot decode (2026-10-22)

- **TSK-438:** The full-size image dialog now displays an accessible “Preview unavailable” message when Flutter cannot decode the stored bytes, while retaining the saved attachment for sharing. This prevents otherwise valid files in less-supported image formats from producing a broken preview surface.
- Added an Item Details widget regression using invalid/unsupported encoded bytes; test source is committed but unrun.


### Phase 2 — avoid a redundant copy after base64 decoding (2026-10-22)

- **TSK-439:** Backup decode now retains the typed byte buffer returned by `base64Decode()` directly instead of immediately copying it through `Uint8List.fromList`. This reduces peak memory for attachment-heavy backups while preserving existing checksum and byte-limit validation.
- Existing codec regressions cover byte-for-byte round trips and checksum verification; they remain authored but unrun.


### Phase 3 — case-insensitive collection row counts (2026-10-22)

- **TSK-409:** Collection rows now count saved-item assignments case-insensitively, matching the existing Collection Contents filter. A legacy item assigned to `learning` is counted under the visible `Learning` collection rather than incorrectly showing zero.
- Added a widget regression for the displayed item count. Test source is committed but unrun.


### Phase 3 — Search result sorting parity (2026-10-22)

- **TSK-416:** Search Results now has the sort control specified by SCR-003 and mirrors Library's three options: Recently saved (most recently updated first), Oldest first (creation timestamp ascending), and Title A–Z (case-insensitive). The result count and sort control use a wrapping layout so they can separate cleanly at narrow widths or enlarged text.
- Added widget regression source for all three ordering modes. Source/test are committed but unrun; visual comparison, large-text checks and screen-reader review remain pending. CI stays manual-only.


### Phase 2 — confirm and preserve omissions for unexportable legacy items (2026-10-22)

- **TSK-410:** Backup planning now separates structurally unreadable records from visible legacy items that cannot be safely exported. Invalid URLs, empty legacy notes, missing/damaged attachments and attachments that exceed the combined 100 MiB budget are omitted from the portable snapshot only after an explicit partial-export confirmation.
- The version-1 backup metadata includes an optional `omittedUnexportableRecordCount`; old backups default it to zero. Restore confirmation explains those items cannot be recovered from that file, and the original local records remain in place.
- Added codec metadata round-trip/validation tests, repository partial-export tests and a widget regression for the confirmation/cancel path. Tests are committed but unrun.


### Phase 3 — metadata performance baseline harness (2026-10-22)

- **TSK-412:** Added `tool/benchmark_library_repository.dart` and `docs/performance-benchmark.md` to establish a repeatable, non-gating baseline for metadata-only libraries of 100, 1,000 and 10,000 items. The harness reports repository open/validation, repeated search and favorite filtering, one existing-item edit, and metadata backup encoding.
- **Status:** Harness and run instructions are committed; no measurements have been taken. TSK-305 remains IN PROGRESS until the output is recorded and recovery/platform verification is completed. No arbitrary latency threshold or CI timing gate is introduced.


### Phase 2 — partial export for legacy libraries over the item cap (2026-10-22)

- **TSK-411:** The backup snapshot now keeps at most 10,000 exportable saved items and records the rest as unexportable omissions. This avoids making every backup fail when an older local store exceeds today's portable item cap; the local records remain unchanged.
- The collection-overflow repair gate now checks the records actually selected for export, so a record already omitted for item/attachment limits doesn't block the partial backup unnecessarily.
- Added repository coverage with 10,001 legacy items, asserting the backup contains 10,000 and the additional local item remains in the library. Test source is committed but unrun.


### Phase 3 — expanded Unicode search coverage (2026-10-22)

- **TSK-414:** Expanded the saved-item model search regression matrix to explicitly cover case-insensitive accented words, emoji, hash/punctuation tokens and bracketed text, alongside the existing English, Urdu-script and Roman Urdu coverage. This is intended to protect stored user-entered text; it does not promise OCR or accent-folding across different Unicode normalization forms.
- Added **TC-118** in `test/saved_item_test.dart`. Regression source is committed but unrun; NFR-005 remains IN PROGRESS until the manual test checkpoint and target-platform search review.


### Phase 2 — reject duplicate IDs during backup export (2026-10-22)

- **TSK-415:** The backup encoder now checks item-ID uniqueness before writing JSON, matching the decoder's rule. A direct encoder caller can no longer create a backup with duplicate IDs that StashHive will later reject during restore.
- Added a codec regression using two different records with the same ID. Test source is committed but unrun.


### Phase 2 — preflight backup JSON size before full serialization (2026-10-22)

- **TSK-413:** The encoder now measures per-item JSON and attachment-entry/base64 sizes against the 145 MiB portable cap before constructing the full backup JSON or allocating each base64 string. This catches large aggregate note metadata early instead of allocating an oversized JSON string and only then rejecting it.
- Added **TC-117**, a boundary regression with shared large source text across enough valid records that escaped JSON exceeds the cap without requiring a huge input fixture, plus **TC-120** for UTF-8/escaped attachment metadata and output-size parity. Test sources are committed but unrun; peak-memory profiling remains pending.


### Phase 2 — repository-owned attachment byte snapshots (2026-10-22)

- **TSK-417:** `LibraryRepository.save` now copies incoming bytes once after validation and before the first storage await. Quick Save can avoid a pre-call copy, while the repository still owns a stable snapshot that callers cannot mutate after passing it in.
- Added **TC-122**, which mutates the original buffer during the save pre-commit hook and verifies that stored attachment bytes remain unchanged. Test source is committed but unrun.


### Phase 2 — reject unreferenced attachment payloads before decode (2026-10-22)

- **TSK-418:** Backup decode now checks attachment keys against the validated items before base64 decoding payloads. In-memory restore preflight enforces the same invariant, so unused attachment bytes cannot consume the 100 MiB allowance or memory without being associated with any item.
- Added regressions for invalid-base64 orphan payloads (proving reference rejection precedes decoding) and direct `DecodedBackup` construction. Test source is committed but unrun.


### Phase 3 — deterministic tie-breaking for Library and Search sort modes (2026-10-22)

- **TSK-419:** Centralized the three sort modes in `compareSavedItemsForSort`. Equal timestamps now fall back to the other timestamp, then case-insensitive/exact title and persisted item ID; equal case-insensitive titles no longer depend on the input list's incidental ordering.
- Library and Search now share the same comparator, and a model regression covers ties for Recently saved, Oldest first and Title A–Z. Test source is committed but unrun.


### Phase 3 — StashHive product-brand alignment (2026-10-22)

- **TSK-420:** Aligned visible Flutter labels, generated Android launcher labels, web install metadata, README and current product/design documentation with StashHive.
- Internal package/Hive box identifiers and the version-1 `StashHive` backup marker remain unchanged so existing local data and version-1 exports stay compatible.
- Added **TC-125** for the Library wordmark and **TC-126** for a version-1 backup marker round trip. Test source is committed but unrun; CI/build remains manual-only.


### Phase 2 — attachment cleanup for unreadable records (2026-10-22)

- **TSK-421:** Deleting an unreadable legacy record now recovers its raw attachment reference so unreferenced bytes can be cleaned up instead of stranded in local storage.
- Cleanup still scans remaining raw records first, including unreadable legacy records, so bytes shared with any other item are preserved.
- Added **TC-127** and **TC-128** for orphan cleanup and shared-payload retention. Regression source is committed but unrun; no tests/build/CI triggered.
- Added **TC-129** for rollback if an error is reported after attachment removal. The case remains source-authored and unrun.


### TSK-422 — First-launch local-storage safety reminder — 2026-10-22

- **Requirement:** FR-015 (browser-local storage honesty and data-loss awareness).
- **Source:** A first-launch Library reminder now distinguishes browser-profile storage from Android app/device storage. It explains that clearing local data may erase the library and that StashHive does not sync; users can dismiss it or open Backup & privacy directly.
- **Persistence:** Dismissal is saved in the existing `stashhive_preferences_v1` box so it is scoped to the current app/browser store and does not require a backend.
- **Tests:** TC-130 plus repository/widget regression source added. Status is **IN PROGRESS** until source checks are run and the first-launch/restart paths are manually reviewed on web and Android. No test/build/CI was run for this change.


### TSK-423 — Recoverable collection deletion errors — 2026-10-22

- **Requirement:** FR-010 (collection relationship consistency and understandable failure behavior).
- **Source:** Collection deletion now catches repository/storage exceptions and displays a SnackBar; the app does not intentionally crash out of the delete handler.
- **Regression:** TC-131 uses the existing collection-mutation fault seam to verify feedback and that the collection plus item assignment remain after rollback.
- **Status:** Source/test authored, unrun. Platform-level persistence interruption testing remains pending.


### TSK-424 — Recoverable item deletion errors — 2026-10-22

- **Requirement:** FR-003 (safe deletion with clear user feedback).
- **Source:** Item Details catches a repository/storage failure during deletion, reports the error and leaves the details route open rather than attempting navigation away on a failed delete.
- **Regression:** TC-132 injects a failure after attachment removal and confirms the saved item and attachment bytes are restored by repository rollback.
- **Status:** Source/test authored, unrun. Tests and actual storage-interruption validation remain pending.


### TSK-425 — Platform-specific Item Details attachment location — 2026-10-22

- **Requirements:** FR-015 and NFR-004 (honest platform/storage messaging).
- **Source:** Item Details reports browser-profile storage on web and device-local storage on Android rather than using the native phrase on every platform.
- **Regression/manual check:** Widget source checks the native label; TC-133 requires checking both web and Android.
- **Status:** Source committed; automated and manual verification pending.


### TSK-426 — Dark-mode preference write recovery — 2026-10-22

- **Requirement:** NFR-003 (local preference persistence and recoverability).
- **Source:** The repository stages and best-effort rolls back the prior dark-mode preference if a write reports failure; the app catches that failure and synchronizes the visible theme back to the repository's persisted value.
- **Regression:** TC-134 covers both repository rollback and UI switch reversion with an injected late-write error.
- **Status:** Source/test authored, unrun; actual device/browser preference persistence remains pending.


### TSK-427 — Accurate search scope and platform wording — 2026-10-22

- **Requirements:** FR-005 and NFR-004 (search transparency and truthful platform copy).
- **Source:** Settings now includes collection names in the searchable-field explanation and identifies browser scope on web versus device scope on native builds. OCR and cross-device search remain explicitly unavailable.
- **Regression/manual check:** TC-135 checks native copy and the indexed-field list; web label and end-to-end claims need a manual check.
- **Status:** Source committed; regression test unrun and platform wording review pending.


### TSK-428 — Safe user-facing operation error messages — 2026-10-22

- **Requirements:** FR-018 and NFR-002 (privacy-conscious error handling).
- **Source:** File selection, save, item/collection deletion and backup operation handlers now retain app-defined validation guidance but use a generic retry message for unexpected failures instead of printing raw plugin/storage exceptions into routine UI.
- **Regression/manual check:** TC-131 and TC-132 assert that injected storage exception text is not shown; TC-136 covers remaining error branches and platform-provided messages.
- **Status:** Source committed, unrun; this does not complete the privacy/logging/network review.


### TSK-429 — Privacy-safe startup storage failure screen — 2026-10-22

- **Requirements:** FR-018 and NFR-002 (privacy-conscious failure messaging).
- **Source:** Startup initialization failures now show browser- or device-specific recovery guidance without printing the raw exception, which may include local storage paths.
- **Regression:** TC-137 checks that recovery guidance is displayed and raw selectable diagnostics are absent.
- **Status:** Source/test committed but unrun; no privacy audit or startup failure injection is claimed.



### TSK-440 — Search hint matches indexed metadata — 2026-10-23

- **Requirement:** FR-005 / NFR-004 (search scope should be discoverable and accurately disclosed).
- **Source:** The Search input hint now names collections, matching `SavedItem.matchesQuery` and the Settings search-scope explanation.
- **Regression:** TC-148 checks the field hint text. Source/test are committed but unrun.
- **Status:** Manual web/Android wording and layout review remains open; validation workflow stays manual-only.

### TSK-441 — Actionable Search empty state for unmatched type filters — 2026-10-23

- **Requirements:** FR-004–005 and NFR-006 (clear retrieval states and accessible recovery).
- **Source:** Search now distinguishes a type filter with no matching saved items from the empty-library state. It explains the mismatch and offers a one-tap clear-filter action; when both query and type filter are set, the action clears both.
- **Regression:** TC-149 covers an unmatched type by itself and the combined query-plus-filter path, ensuring the reset makes existing saved items reachable again.
- **Status:** Source/test committed but unrun; responsive, large-text, keyboard and screen-reader checks remain pending.

### TSK-442 — Actionable favorite-update error feedback — 2026-10-25

- **Requirements:** FR-004, FR-018 and NFR-002–003 (reliable list actions, safe messaging and local persistence).
- **Source:** Favorite toggling now reuses the privacy-safe operation error helper. Unexpected storage failures tell the user to check local storage and retry, rather than suggesting unrelated URL/file repairs.
- **Regression:** TC-150 injects a late item-write failure, checks that raw diagnostic text is not rendered, and verifies best-effort rollback retains the non-favorite state.
- **Status:** Source/test committed but unrun; real browser/Android persistence behavior remains unverified.


### Phase 3 — Settings text-size control (TSK-443, 2026-10-25)

Settings now includes a local **App text size** preference with System default, Large and Extra large choices. The selected multiplier is persisted in the existing preferences box and composed with the platform-provided text scaler, preserving Android/browser accessibility scaling while allowing users to enlarge app text further. Repository regressions cover persistence and rollback after a late write failure; a widget regression covers changing the size and checking the applied scaler. Tests and builds remain unrun, and the design still needs narrow-width, Android and browser review.


### TSK-444 — Consistent favorite-update failure feedback in Item Details — 2026-10-25

- **Requirements:** FR-004 / FR-018 and NFR-002–003 (reliable favorite action, safe error copy and recoverable local persistence).
- **Source:** The Item Details favorite button now uses the shared safe-error helper, matching the Library tile. Unexpected failures recommend checking local storage and retrying, instead of suggesting unrelated URL/file repair.
- **Regression:** TC-152 injects a late storage failure, confirms diagnostic details remain hidden, and checks the favorite state remains false.
- **Status:** Source/test committed but unrun; real browser/Android storage recovery remains unverified.


### Product rename follow-up — 2026-10-25

- Updated the product name in the roadmap and requirements to StashHive. Older StashTrail backups remain a supported import format.
- The Android manifest configurator and its regression tests now enforce the StashHive launcher label; the web page title and install manifest use StashHive as well.
- Automated tests/builds remain deferred until the manual validation checkpoint.

### TSK-462 — Bound Android share intake and validate before string copies — 2026-10-28

- **Requirements:** FR-008/FR-009 and NFR-002/NFR-003.
- **Source:** Share batches are capped at 100 ordered entries with a user-facing warning for omitted remainder. Fingerprint generation performs a length-only first pass over raw input fields and aggregate character bounds before trimming/normalization or JSON/UTF-8 allocation; oversized inputs, including aggregate whitespace-only message fields, bypass fingerprinting and reach normal validation instead. Text shares can use their message field when the provider path is empty, and raw URL/path/MIME bounds are checked before trim/case normalization.
- **Regression:** TC-169 covers batch order/capping and over-limit fingerprint bypass; TC-170 covers message-only text shares.
- **Status:** Source and regression documentation committed; all tests remain unrun. Validate real provider MIME/path behavior, sequential review and warning UX on Android at the manual checkpoint. CI remains manual-only by owner request.

### TSK-463 — Serialize backup export with pending mutations — 2026-10-28

- **Requirements:** FR-012/FR-013 and NFR-003.
- **Source:** Backup export now enters the repository mutation queue before reading local items, attachments and collection preferences. This prevents a concurrent save from exposing older item notifier data alongside replacement attachment bytes.
- **Regression:** TC-171 pauses an attachment edit after its item write, requests a backup, and checks the decoded export contains the matching new item metadata and new attachment bytes.
- **Status:** Source and regression documentation committed; tests remain unrun. Validate concurrent export/edit/delete/restore behavior on browser and Android storage at the manual checkpoint. CI remains manual-only by owner request.

### TSK-464 — Dependency inventory and project-document consistency — 2026-10-28

- **Requirements:** NFR-010 and project documentation maintainability.
- **Source/docs:** Added the direct dependency/license register, linked it from the README, updated the NFR-010 traceability row, corrected stale StashTrail branding in project intake and all current design references/mockups, and aligned requirements approval status with the approved blueprint.
- **Status:** Initial direct dependency inventory is committed. The transitive dependency graph, exact resolved versions and license/security audit are still open because no `pubspec.lock` is committed. Do not claim a completed license review until the lockfile and platform build checkpoint are available.

### TSK-465 — Guard share enqueue against host disposal — 2026-10-28

- **Requirements:** FR-009 / NFR-003.
- **Source:** Incoming share events are ignored once `HomeShell` is no longer mounted, preventing a late stream event from entering a queue whose consumer has been disposed. The active batch completer is tracked and released during host disposal alongside waiting batches.
- **Manual regression:** TC-172 covers stream cancellation, app stop/restart and active-batch completion.
- **Status:** Source guard and manual case committed; Android plugin lifecycle behavior has not been tested on a device. CI remains manual-only by owner request.

### TSK-466 — Bound the waiting queue for share batches — 2026-10-28

- **Requirements:** FR-009 / NFR-003.
- **Source:** The app now admits at most eight waiting share batches independently of the currently active batch. Additional unique events receive explicit feedback that the current share was not queued and must be shared again after pending batches finish, rather than growing the queue without limit. Capacity is checked before de-duplication cache insertion so declined events can be retried after the queue drains.
- **Regression:** TC-173 checks the queue-admission boundary; manual Android verification must also exercise queue-full messaging, FIFO draining and teardown.
- **Status:** Source and test plan committed; the unit regression has not been run and native stream behavior remains unverified.

### TSK-467 — Keep share fingerprinting resilient to unusual file URIs — 2026-10-28

- **Requirements:** FR-009 / NFR-002–003.
- **Source:** MIME inference during duplicate-event fingerprinting now catches file-URI local-path conversion errors and falls back to the original bounded provider path instead of throwing in the stream callback.
- **Regression:** TC-174 covers a file URI with a non-local authority.
- **Status:** Source and regression committed but unrun; validate actual Android provider URI shapes and safe fallback behavior at the manual checkpoint.

### TSK-468 — Prevent stale preference errors from reverting newer UI choices — 2026-10-28

- **Requirements:** NFR-003/NFR-006.
- **Source:** Dark-mode and text-size callbacks now use request revisions so a late failure from an earlier preference update cannot roll the UI over a newer choice already queued in the repository.
- **Regression:** TC-175 covers rapid dark-mode actions behind a delayed failure; TC-176 covers text-size changes while an earlier write fails; TC-177 checks that the visible dropdown returns to the persisted option after a failed choice.
- **Status:** Source and widget regression coverage committed but unrun. Verify real browser/Android storage behavior at the manual checkpoint.

### TSK-469 — Track the last generated backup honestly — 2026-10-28

- **Requirements:** FR-012–015 / NFR-004.
- **Source:** Stores a local timestamp after backup JSON generation succeeds but before the serialized snapshot operation is released, preventing a queued mutation from running between snapshot and timestamp. The Backup & privacy screen shows the localized date/time and explicitly distinguishes generation from confirmed destination delivery; a timestamp preference failure does not block sharing, and late timestamp-write failures attempt to restore the prior status.
- **Regression:** TC-178 verifies persistence/validation, and TC-179 checks the UI's empty state, formatted time and honest caveat.
- **Status:** Source and regressions committed but unrun; native/browser share-sheet update behavior remains pending manual validation.

### TSK-470 — Preserve backup export on timestamp storage failure — 2026-10-28

- **Requirements:** FR-012 / NFR-003.
- **Source:** Backup generation writes the informational timestamp before releasing the same serialized snapshot operation. Timestamp storage remains best-effort: a late write failure attempts rollback and never prevents returning already encoded backup JSON.
- **Regression:** TC-180 injects a failure after the timestamp write and verifies valid backup JSON still returns while the previous timestamp remains persisted.
- **Status:** Source and regression committed but unrun; real quota/storage failure behavior remains pending manual web/Android validation.

### TSK-471 — Keep backup exports consistent after delete rollback — 2026-10-28

- **Requirements:** FR-003, FR-012 and NFR-003.
- **Source:** Backup export uses the same serialized repository queue as delete and rollback. It waits until an in-flight deletion has either committed or restored its old state before taking the snapshot.
- **Regression:** TC-181 pauses deletion after removing the record/attachment, requests a backup, then injects a late failure and verifies that the export includes the restored metadata and exact attachment bytes.
- **Status:** Regression source is committed but unrun; browser/Android storage concurrency remains part of the manual validation checkpoint.

### TSK-472 — Keep backup exports out of interrupted restore states — 2026-10-28

- **Requirements:** FR-012–013 and NFR-003.
- **Source:** Backup generation and restore share the serialized repository mutation queue. An export requested during restore waits for either a successful commit or rollback of staged items/attachments and prior collection preferences.
- **Regression:** TC-182 pauses restore after incoming media is staged, queues a backup, injects an interruption, and verifies that only the original library state is exported.
- **Status:** Regression source is committed but unrun; browser/Android backup and restore concurrency remains pending the manual validation checkpoint.

### TSK-473 — Keep backup exports consistent after save rollback — 2026-10-28

- **Requirements:** FR-002, FR-012 and NFR-003.
- **Source:** Backup export shares the mutation queue with item save and rollback. If a save fails after writing new metadata/attachment bytes, the queued export waits until the old record and payload have been restored.
- **Regression:** TC-183 pauses an attachment replacement after the item write, requests a backup and injects a late failure; the backup must contain the prior title and exact prior bytes.
- **Status:** Regression source is committed but unrun; browser/Android failure-path validation remains pending.

### TSK-474 — Keep backup snapshots aligned with collection renames — 2026-10-28

- **Requirements:** FR-010, FR-012 and NFR-003.
- **Source:** Backup generation is serialized with collection/item mutations and waits for the underlying writes and notifier refreshes to complete before capturing the collection list and item assignments.
- **Regression:** TC-184 pauses a collection rename after persisted writes, queues a backup and verifies that the resulting export contains only the committed new collection assignment.
- **Status:** Regression source is committed but unrun; browser/Android backup consistency remains pending the manual validation checkpoint.

### TSK-475 — Preserve effective text when an unused provider path is oversized — 2026-10-28

- **Requirements:** FR-009 and NFR-003.
- **Source:** Text intake consumes the non-empty effective message before inspecting unused provider path metadata. Oversized inputs bypass fingerprint serialization and then follow normal intake validation.
- **Regression:** TC-185 confirms a valid short message is retained as a note even when the unused provider path exceeds the text limit.
- **Status:** Source behavior and regression are committed, but tests remain unrun. Verify against real Android source apps at the manual checkpoint.

### TSK-476 — Recover from attachment size metadata failures — 2026-10-28

- **Requirements:** FR-008 and NFR-003/NFR-006.
- **Source:** Quick Save's recoverable file-selection path is now explicitly covered when a provider returns a file but throws while reporting its size.
- **Regression:** TC-186 confirms safe error feedback, cleared busy state, retained draft, successful retry, and exact persisted image bytes.
- **Status:** Regression source is committed but unrun; verify failure and retry behavior on actual Android and supported browser/desktop pickers at the manual checkpoint.

### TSK-477 — Recover from attachment byte-stream read failures — 2026-10-28

- **Requirements:** FR-008 and NFR-003/NFR-006.
- **Source:** Quick Save's bounded byte reader is already guarded by a safe error path. The new regression covers a provider whose size lookup succeeds but whose byte stream fails, ensuring the user can recover through a fresh selection rather than losing the draft or seeing private provider diagnostics.
- **Regression:** TC-187 retries after a simulated stream failure and verifies the exact bytes persisted from the subsequent valid image.
- **Status:** Source/test authored and committed, unrun. Confirm partial stream/provider failure behavior on Android and supported browser/desktop targets at the manual validation checkpoint. CI remains manual-only.

### TSK-478 — Bound pasted URL and tag input before parsing — 2026-10-28

- **Requirements:** FR-002 and NFR-003.
- **Source:** Quick Save checks raw URL length before URL parsing and caps the comma-separated tags field at 12,000 characters. It rejects oversized tag text inline and defensively before splitting it into individual tags, while retaining the existing 100-tag and 100-characters-per-tag limits.
- **Regression:** TC-188 verifies oversized tag input is rejected without creating an item; the URL-length regression covers the 4,096-character bound.
- **Status:** Source and regression are committed but unrun. Confirm large paste behavior and ordinary field editing on web/Android during the manual validation checkpoint.

### TSK-479 — Normalize search once and bound oversized queries — 2026-10-28

- **Requirements:** FR-005 and NFR-007.
- **Source:** Search normalizes the query once and reuses that lower-case string for each item match. Queries above 4,096 characters are rejected before trimming/normalization or scanning the saved list, with visible limit feedback.
- **Regression:** TC-189 checks oversized initial query handling; a SavedItem unit case covers normalized-query matching.
- **Status:** Source/tests authored and committed, unrun. Capture performance measurements at 100, 1,000 and 10,000 items and review Unicode/search accessibility on browser and Android at the manual validation checkpoint.

### TSK-480 — Recover from backup picker metadata errors — 2026-10-28

- **Requirements:** FR-013 and NFR-003/NFR-006.
- **Source:** Backup restore's file-size lookup is covered with a failure injection seam; the UI should recover to an idle, retryable state without displaying raw provider paths/details, and a later valid backup should remain importable.
- **Regression:** TC-190 fails the first length lookup, checks no records changed and private details are hidden, then retries with a valid backup and verifies the merge.
- **Status:** Source/test committed but unrun. Verify native/browser file-picker error behavior at the manual validation checkpoint. CI remains manual-only.

### TSK-481 — Ignore oversized whitespace in unused share message fields — 2026-10-28

- **Requirements:** FR-009 and NFR-003.
- **Source:** Incoming text-share intake detects whether the provider's message contains non-whitespace content before applying the 1,000,000-character limit. When an oversized message is all whitespace, intake treats it as unused metadata and falls back to the path without trimming/copying the oversized field. Non-whitespace oversized content still fails validation.
- **Regression:** TC-191 uses a short valid path with an oversized whitespace-only message and expects an editable note draft.
- **Status:** Source and regression documentation committed; regression remains unrun. Verify real Android provider fields at the manual checkpoint; CI remains manual-only.

### TSK-482 — Recover from backup byte-stream read failures — 2026-10-28

- **Requirements:** FR-013 and NFR-003/NFR-006.
- **Source:** Backup restore's existing bounded byte-stream read and error/finally path has explicit coverage for the case where the provider returns a size successfully but fails while emitting bytes. The UI must retain the existing library, suppress raw provider details and allow a retry.
- **Regression:** TC-192 injects a stream error, checks the library remains unchanged and then imports a valid backup after a second file-selection attempt.
- **Status:** Regression source and roadmap entry committed but unrun. Verify actual native/web read failures at the manual checkpoint; CI remains manual-only.

### TSK-483 — Block navigation during an active restore commit — 2026-10-28

- **Requirements:** FR-013 and NFR-003/NFR-006.
- **Source:** Backup & privacy disables the app-bar Back action and blocks system-back navigation after the restore merge is confirmed and the repository begins its staged write/commit phase. When restore completes or fails, the route becomes navigable again.
- **Regression:** TC-193 pauses restore before collection commit, simulates system back and checks the page stays open while restoring, then confirms the restore completes.
- **Status:** Source and regression documentation committed but unrun. Verify slow-storage and real Android back-gesture behavior at the manual checkpoint; CI remains manual-only.

### TSK-484 — Show share truncation feedback after review — 2026-10-28

- **Requirements:** FR-009 and NFR-006.
- **Source:** Oversized share batches retain the omitted count in the waiting queue. The app accumulates omitted counts and shows a combined truncation warning only after all already-queued sequential draft reviews finish, when the Library/home screen is visible again.
- **Manual regression:** TC-194 checks first-100 sequential review, unsupported-item handling, and the final omitted-count warning.
- **Status:** Source and documentation committed; manual Android UX confirmation remains pending. CI stays manual-only.

### TSK-485 — Aggregate share review feedback after the queue drains — 2026-10-28

- **Requirements:** FR-009 and NFR-006.
- **Source:** Counts for unsupported, invalid/unreadable and over-limit entries accumulate while queued batches are reviewed. One combined message—with up to three safe validation hints—is shown when the waiting queue drains, so later Quick Save routes cannot cover earlier feedback.
- **Manual regression:** TC-195 combines multiple queued batches, unsupported entries, one invalid entry and an over-limit batch; verify the final summary on the Library screen.
- **Status:** Source and documentation committed; manual share-batch UX verification remains pending. CI remains manual-only.

### TSK-486 — Bound and test the aggregate share feedback message — 2026-10-28

- **Requirements:** FR-009 and NFR-006.
- **Source:** A pure share-service formatter composes unsupported, invalid/unreadable and omitted counts, de-duplicates hints, caps details at three entries, and returns `null` when nothing needs reporting. HomeShell calls it only after the waiting share queue drains and gives the combined summary an eight-second display duration.
- **Regression:** TC-196 covers combined summary text and hint limits; TC-197 confirms empty summaries are suppressed. TC-195 remains the end-to-end manual UX check for timing/accessibility.
- **Status:** Source and regression documentation committed but unrun. Verify end-to-end summary timing and assistive-technology behavior at the manual checkpoint; CI remains manual-only.

### TSK-487 — Release restore navigation guard after commit failure — 2026-10-28

- **Requirements:** FR-013 and NFR-003/NFR-006.
- **Source:** The route guard remains active only during `_restoring`; this regression documents and checks that `finally` releases the guard after a staged restore fails and repository rollback completes.
- **Regression:** TC-198 injects a restore interruption, verifies existing library data is retained and private details are hidden, then triggers system back to confirm the user can leave the failed restore screen.
- **Status:** Regression source and docs committed but unrun. Verify web/Android rollback and navigation at the manual checkpoint; CI remains manual-only.

### TSK-488 — Make backup share-outcome feedback status-specific — 2026-10-28

- **Requirements:** FR-012 and NFR-003.
- **Source:** Backup export distinguishes `success`, `dismissed` and `unavailable` results. The UI no longer uses one generic fallback for all non-success outcomes: messages state what was reported and avoid claiming the backup definitely reached its destination.
- **Regression:** TC-199 covers each result-to-message mapping. Actual destination delivery is still platform-dependent and needs manual confirmation.
- **Status:** Source and regression documentation committed but unrun. Check the share sheet and resulting file/Downloads behavior at the manual checkpoint; CI remains manual-only.

### TSK-489 — Snapshot caller-owned decoded backup inputs before restore awaits — 2026-10-28

- **Requirements:** FR-013 and NFR-003.
- **Source:** After validation, the repository copies decoded item tag lists, collection names, attachment metadata and attachment byte arrays into an owned snapshot before the first asynchronous boundary. Restore staging and persistence use that snapshot instead of references held by the caller.
- **Regression:** TC-200 mutates the original decoded item/list/map/bytes after the owned snapshot is created but before the first persistent write, then verifies the restored item, tags, collection and bytes remain the originally validated values.
- **Status:** Source and regression committed but unrun. Review peak memory and verify restore consistency with web/Android storage at the manual checkpoint.

### TSK-490 — Snapshot mutable item tags before repository save — 2026-10-28

- **Requirements:** FR-002 and NFR-003.
- **Source:** Repository save clones and freezes the tag list before validation and storage awaits, so mutation of a caller-owned mutable tags list cannot change the metadata that is persisted after the save has started.
- **Regression:** TC-201 pauses save before the record write, mutates the caller's list and checks both the visible item and raw stored record retain the original tags.
- **Status:** Source and regression committed but unrun. Verify together with attachment-byte snapshot and rollback cases at the manual checkpoint.

### TSK-491 — Prevent attachment reads from observing an in-flight replacement — 2026-10-28

- **Requirements:** FR-008 and NFR-003.
- **Source:** Attachment reads share the repository operation queue with writes and backup snapshots. They wait until attachment replacement/deletion/restore operations either commit or finish rollback, preventing the UI from observing an inconsistent item/payload pair.
- **Regression:** TC-202 checks a pending successful replacement; TC-203 checks a failed replacement that must roll back the original bytes before a waiting reader continues.
- **Status:** Source and regression documentation committed but unrun. Validate slow-storage preview/share flows and failure rollback on web/Android at the manual checkpoint; CI remains manual-only.

### TSK-492 — Distinguish pending attachment reads from missing-file states — 2026-10-28

- **Requirements:** FR-011 and NFR-006.
- **Source:** Item Details and the image-view dialog now show an accessible loading state while attachment reads wait behind a repository write. Missing-file feedback is shown only after a completed empty read; read errors use preview-unavailable feedback.
- **Regression:** TC-204 holds an attachment replacement before metadata commit, then checks that the page and dialog present loading instead of falsely reporting a missing attachment.
- **Status:** Source and regression documentation committed but unrun. Review slow-storage transitions and screen-reader announcements on web/Android at the manual checkpoint; CI remains manual-only.

### TSK-493 — Reuse image thumbnail attachment reads across rebuilds — 2026-10-28

- **Requirements:** FR-008, FR-011 and NFR-003/NFR-007.
- **Source:** The image thumbnail owns a stable attachment-read Future and refreshes it only when repository/item identity or revision changes. Ordinary parent rebuilds do not enqueue another serialized read for the same item revision.
- **Regression:** TC-205 counts read starts while rebuilding the Library without changing the saved image, then confirms only one read was scheduled.
- **Status:** Source and regression documentation committed but unrun. Verify replacement refresh and capture performance baselines at the manual checkpoint; CI remains manual-only.

### TSK-494 — Coalesce overlapping attachment reads without crossing writes — 2026-10-28

- **Requirements:** FR-008/FR-011 and NFR-003/NFR-007.
- **Source:** Concurrent requests for the same attachment can reuse one pending read future. Queue sequence tracking prevents a read requested after a later repository operation has been enqueued from joining an older future and seeing stale bytes.
- **Regression:** TC-206 verifies shared concurrent reads return original bytes while a read queued after an attachment replacement returns the committed replacement bytes.
- **Status:** Source and regression committed but unrun. Review same-key thumbnail/detail read behavior and capture performance baseline during the manual validation checkpoint.

### TSK-495 — Release coalesced attachment reads after failure — 2026-10-28

- **Requirements:** FR-008/FR-011 and NFR-003.
- **Source:** In-flight same-key attachment read futures are removed in a guarded finally path. Failure releases the entry, and an older read cannot remove a newer request that is queued after a repository write.
- **Regression:** TC-207 injects a transient read error and confirms the next read succeeds with the original bytes.
- **Status:** Source and regression committed but unrun. Check read-error recovery with real browser/Android storage at the manual validation checkpoint.

### TSK-496 — Keep synchronous item lookups on the published repository snapshot — 2026-10-28

- **Requirements:** FR-002/FR-003 and NFR-003.
- **Source:** `findById` now resolves against an O(1) index of the last published item snapshot, updated before `items` listeners are notified. This avoids exposing raw Hive records staged inside a save before the repository finishes its commit/rollback and refresh.
- **Regression:** TC-208 pauses an attachment replacement after the raw item write and confirms synchronous lookup still returns the old published item until the write completes.
- **Status:** Source and regression plan committed but unrun. Validate delayed saves and rollback on web and Android at the manual checkpoint; CI remains manual-only.

### TSK-497 — Preserve the published lookup snapshot during delete rollback — 2026-10-28

- **Requirements:** FR-003 and NFR-003.
- **Source:** `findById` reads the O(1) index of the last published item snapshot rather than the raw Hive box. When delete temporarily removes a record and then fails, public lookup retains the old item until rollback refreshes the snapshot.
- **Regression:** TC-209 pauses delete after raw item/attachment removal, checks the item remains visible through `findById`, then verifies the simulated failure restores the item and exact attachment bytes.
- **Status:** Source and regression plan committed but unrun. Verify slow delete/rollback and consistency on web and Android at the manual checkpoint; CI remains manual-only.

### TSK-498 — Keep staged restore records out of the published lookup — 2026-10-28

- **Requirements:** FR-013 and NFR-003.
- **Source:** Synchronous lookup now reads only from the published item index; raw records staged by restore are not visible until the commit path refreshes the repository snapshot.
- **Regression:** TC-210 pauses restore after its raw item write and confirms the incoming item remains invisible to `findById` until collection commit completes.
- **Status:** Source/regression plan committed but unrun. Verify successful and interrupted restore visibility on web and Android at the manual checkpoint; CI remains manual-only.

### TSK-499 — Expose repository state through read-only listenables — 2026-10-28

- **Requirements:** FR-002/FR-010 and NFR-003.
- **Source:** Repository item, collection and recovery-counter notifiers are private. Public read-only `ValueListenable` wrappers preserve widget subscriptions and reads without exposing mutable notifier instances or direct setters that can replace snapshots without persistence.
- **Regression:** TC-211 checks state notification after repository operations and confirms published item/collection lists remain unmodifiable through the public interface.
- **Status:** Source and regression plan committed but unrun. Review widget reactivity, formatting, static analysis and platform behavior at the agreed manual validation checkpoint; CI remains manual-only.

### TSK-500 — Keep malformed backup-version errors bounded — 2026-10-28

- **Requirements:** FR-013, NFR-002 and NFR-003.
- **Source:** Backup decoding now validates the format-version field's type before formatting an unsupported-version message. Non-integer input receives concise fixed text rather than echoing untrusted strings or structured values; unknown integer versions remain explicit.
- **Regression:** TC-212 uses a 100,000-character string in `formatVersion` and expects the fixed invalid-version message.
- **Status:** Source and regression plan committed but unrun. Verify large malformed backup handling and restore feedback at the manual checkpoint; CI remains manual-only.

### TSK-501 — Snapshot mutable save inputs before queueing — 2026-10-28

- **Requirements:** FR-002 and NFR-003.
- **Source:** The public `save()` call bounds tags before serialization, validates item fields and attachment data before allocation, then captures owned tag/attachment snapshots before the operation joins the serialized mutation queue. Later caller mutations no longer alter a queued save.
- **Regression:** TC-213 queues an image save behind a paused write, mutates the caller's tags and bytes, and asserts the stored item matches the values submitted to `save()`.
- **Status:** Source and regression plan committed but unrun. Verify queue-time input snapshots, failures and rollback on web and Android at the manual validation checkpoint; CI remains manual-only.

### TSK-502 — Snapshot decoded restore inputs before queueing — 2026-10-28

- **Requirements:** FR-013 and NFR-003.
- **Source:** The public restore method now validates and copies the decoded backup's item/tag lists, collections, attachment metadata/map and byte buffers before enqueueing the restore. The queued operation no longer reads caller-owned mutable structures after waiting for prior repository work.
- **Regression:** TC-214 queues a restore behind a paused save, changes the original backup lists/map/bytes, and asserts the import still matches the data captured at submission.
- **Status:** Source and regression plan committed but unrun. Review peak memory, rollback and target-platform persistence at the manual validation checkpoint; CI remains manual-only.

### TSK-503 — Reject oversized tag lists before serialization — 2026-10-28

- **Requirements:** FR-002, FR-013 and NFR-003.
- **Source:** Shared item validation now bounds tag-list count and each tag length before `SavedItem.toMap()` copies the list. The public save boundary also performs the cheap tag-size preflight before full validation.
- **Regression:** TC-215 passes a guard list whose declared count is above the maximum through item validation, backup encoding and decoded-backup validation, expecting the fixed validation error without any element traversal.
- **Status:** Source and regression plan committed but unrun. Verify direct save, backup encode and restore validation at the manual checkpoint; CI remains manual-only.

### TSK-504 — Bound the attachment-entry count in backups — 2026-10-28

- **Requirements:** FR-013 and NFR-003.
- **Source:** Backup JSON decode and in-memory `DecodedBackup` validation now reject attachment maps with more entries than saved items before walking attachment keys. The portable format already rejects unreferenced payloads, and each saved item can reference at most one attachment.
- **Regression:** TC-216 tests both a direct in-memory attachment map and a JSON backup whose attachment-entry count exceeds its item count.
- **Status:** Source and regression plan committed but unrun. Validate malformed backup limits and restore error handling at the manual checkpoint; CI remains manual-only.

### TSK-505 — Bound collection count before backup export normalization — 2026-10-28

- **Requirements:** FR-012/FR-013 and NFR-003.
- **Source:** Backup encoding now rejects raw collection lists over 500 before walking saved items. The normalizer streams the declared collection list and item-assigned collection names separately rather than spreading both into an intermediate list.
- **Regression:** TC-217 provides an over-limit list whose indexed access throws and confirms the encoder returns the fixed collection-count error based on the list length alone.
- **Status:** Source and regression documentation committed; TC-217 is authored but unrun. Confirm parity between direct encode/decode limits, older backup compatibility and restore behavior at the manual checkpoint.

### TSK-506 — Bound saved-item type values before parsing — 2026-10-28

- **Requirements:** FR-013, NFR-002 and NFR-003.
- **Source:** Backup raw-item validation now checks all item string lengths and confirms the kind is a known saved-item type before model parsing. Local raw-record validation bounds the kind field as well. Model-level wire parsing uses a fixed error message for invalid types instead of echoing untrusted values.
- **Regression:** TC-218 covers oversized and unknown types through direct model parsing, backup decode and local repository recovery while valid neighboring items remain accessible.
- **Status:** Source and regression documentation committed; TC-218 is authored but unrun. Validate malformed backup feedback and legacy local-store recovery at the manual checkpoint; CI remains manual-only.

### TSK-507 — Bound optional backup export timestamp metadata — 2026-10-28

- **Requirements:** FR-012/FR-013 and NFR-002/NFR-003.
- **Source:** Optional `exportedAt` metadata is retained from JSON backups only when the string is no longer than 64 characters; missing, malformed or oversized values normalize to empty while valid item data stays importable. Direct constructed backup objects with overlong timestamps fail restore preflight with fixed text.
- **Regression:** TC-219 verifies both JSON normalization and direct in-memory validation.
- **Status:** Source and regression documentation committed but unrun. Confirm normal timestamp and older v1 backup compatibility at the manual validation checkpoint; CI remains manual-only.

### TSK-508 — Check raw metadata lengths before normalization — 2026-10-28

- **Requirements:** FR-012/FR-013 and NFR-003.
- **Source:** Backup decoding, direct decoded-backup validation and backup collection normalization now check collection lengths before trimming; raw tag lengths are checked before whitespace normalization; JSON and direct attachment key/name/MIME lengths are checked before trimming. Local collection recovery, creation and rename also reject overlong strings before normalization.
- **Regression:** TC-220 covers oversized tag/collection values, direct decoded-backup validation, export encoding and legacy collection preference recovery.
- **Status:** Source and regression documentation committed but unrun. Validate malformed-import and local recovery behavior at the manual checkpoint; CI remains manual-only.

### TSK-509 — Preflight direct model fields before normalization — 2026-10-28

- **Requirements:** FR-002/FR-013 and NFR-003.
- **Source:** `SavedItem.fromMap` now rejects overlong raw fields and oversized tag lists/tag values before trimming or copying data. Valid-size legacy values continue through the existing normalization rules.
- **Regression:** TC-221 verifies direct parsing rejects oversized title/tag fields with fixed messages.
- **Status:** Source and regression documentation committed but unrun. Check model round-trip, legacy tag normalization and malformed backup recovery at the manual validation checkpoint.

### TSK-510 — Bound direct URL and search helper input — 2026-10-28

- **Requirements:** FR-005/FR-006 and NFR-003.
- **Source:** Both web URL parsing helpers reject input over 4,096 characters before trimming/parsing. Both model-level search helpers reject over-limit queries before normalization or scanning saved fields, matching the size policy already present in the UI.
- **Regression:** TC-222 covers oversized direct URL helper input and oversized model search queries.
- **Status:** Source and regression documentation committed but unrun. Verify direct helper behavior, form validation and Search UI messaging at the manual checkpoint.

### TSK-511 — Bound legacy collection preference recovery scans — 2026-10-28

- **Requirements:** FR-010, FR-015 and NFR-003.
- **Source:** Collection preference recovery scans at most 10,000 raw entries per initialization. If the 500 collection cap is filled earlier, the remainder is counted as skipped without traversal. Uninspected entries are reported through the existing recovery counter; saved-item collection assignments are merged afterward and the raw preference is not rewritten.
- **Regression:** TC-223 tests a 10,001-entry duplicate list, skip count, a preserved item-assigned collection and raw preference retention.
- **Status:** Source and regression documentation committed but unrun. Validate recovery messages and browser/Android storage behavior at the manual checkpoint.

### TSK-512 — Sanitize invalid provider file-URI errors — 2026-10-28

- **Requirements:** FR-009 and NFR-002/NFR-003.
- **Source:** File-share intake catches URI-to-local-path conversion errors and returns fixed user-facing guidance instead of allowing raw provider URI/platform exception details into the share-review feedback.
- **Regression:** TC-224 covers an incoming file URI with a non-local authority; TC-174 separately protects duplicate-event fingerprinting for unusual file URIs.
- **Status:** Source and regression documentation committed but unrun. Validate local/non-local URI handling and batch continuation against real Android providers at the manual checkpoint; CI remains manual-only.

### TSK-513 — Bound share-review summary hint processing — 2026-10-28

- **Requirements:** FR-009 and NFR-002/NFR-003.
- **Source:** The share-review summary helper checks at most 16 hint candidates, rejects raw hints over 160 characters before trimming, and keeps only three distinct safe hints.
- **Regression:** TC-225 covers oversized hints and limits iteration over empty hints.
- **Status:** Source and regression plan committed but unrun. Validate summary copy and screen-reader behavior on Android at the manual checkpoint.

### TSK-514 — Prevent overlapping backup export and restore actions — 2026-10-28

- **Requirements:** FR-012/FR-013 and NFR-003.
- **Source:** Backup & privacy blocks the opposite operation while export or restore is active, shows a clear activity label, and exposes disabled-operation status as a live region for assistive technology. Handler guards also reject competing taps, while the repository queue remains the consistency backstop.
- **Regression:** TC-226 pauses backup preparation and checks Restore cannot start with a live status; TC-227 pauses file selection and checks Create backup cannot start until picker cancellation; both tests assert accessible status announcements.
- **Status:** Source and widget regression source committed, unrun. Verify real Android/web file picker and share-sheet transitions at the manual checkpoint.

### TSK-515 — Release the backup JSON string before share-sheet await — 2026-10-28

- **Requirements:** FR-012 and NFR-003/NFR-007.
- **Source:** After UTF-8 encoding, Backup & privacy clears its local reference to the large JSON source string before awaiting the user-controlled platform share sheet. The share payload remains the encoded byte list.
- **Manual regression:** TC-228 checks that the generated backup remains valid UTF-8 JSON with matching metadata/attachments and calls for peak-memory inspection while the share sheet remains open.
- **Status:** Source and documentation committed; no tests, formatting, analysis, builds, or memory profiles were run. Verify large backup export on web and Android at the manual checkpoint. CI stays manual-only.

### TSK-516 — Handle Item Details attachment-read failures — 2026-10-28

- **Requirements:** FR-011 and NFR-002/NFR-003.
- **Source:** Item Details catches repository read failures while preparing a document for the system share sheet, displays safe local-storage/retry feedback and checks mounted state before proceeding.
- **Regression:** TC-229 injects a storage-read error, checks the raw diagnostic is hidden, and verifies the saved attachment remains intact.
- **Status:** Source and regression documentation committed; test remains unrun. Verify storage error recovery and ordinary attachment sharing on web and Android at the manual validation checkpoint. CI stays manual-only.

### TSK-517 — Retry transient image-preview read failures — 2026-10-28

- **Requirements:** FR-011 and NFR-002/NFR-003.
- **Source:** Item Details' image-preview dialog now provides **Retry preview** when an attachment read fails. A retry starts a fresh repository read and updates the dialog and page cache so the failed Future is not reused.
- **Regression:** TC-230 injects a one-time read failure, checks that safe feedback hides raw storage diagnostics, then retries and confirms the preview's attachment read succeeds.
- **Status:** Source and regression documentation committed but unrun. Verify retry behavior, screen-reader feedback and image decoding on web/Android at the manual validation checkpoint. CI remains manual-only.

### TSK-518 — Recover when native share-stream setup fails — 2026-10-28

- **Requirements:** FR-009 and NFR-002/NFR-003.
- **Source:** Android share-intake startup catches synchronous failures while obtaining/subscribing to the live event stream and tells the user that manual capture remains available. It still attempts the independent launch-time intent read, so a cold-start share can be recovered when the live stream is unavailable.
- **Regression:** TC-231 injects a stream setup exception, verifies launch-time intent retrieval is still attempted, and checks safe guidance, hidden plugin diagnostics, continued Library navigation and no framework exception.
- **Status:** Source and regression documentation are committed but unrun. Validate plugin lifecycle and normal event delivery on a physical Android device at the manual validation checkpoint; CI remains manual-only.

### TSK-519 — Keep Quick Save navigation consistent while a picker is pending — 2026-10-28

- **Requirements:** FR-008 and NFR-003/NFR-006.
- **Source:** The Quick Save route guard and visible Back/Cancel controls now remain disabled while either persistence or file selection is pending. Changing the item kind remains enabled during selection so stale picker responses can be invalidated; after picker completion/cancellation, normal navigation is restored.
- **Regression:** TC-232 pauses an image picker and checks in-form navigation and system back remain blocked until the picker returns canceled.
- **Status:** Source and widget regression committed; test not run. Confirm Android/browser picker cancellation and navigation manually at the validation checkpoint. CI stays manual-only.

### TSK-520 — Preflight public SavedItem serialization dimensions — 2026-10-28

- **Requirements:** FR-001 and NFR-003.
- **Source:** SavedItem.toMap() rejects overlong raw item fields and tag lists before copying tags or returning the serialized map. This aligns direct model serialization with repository and backup validation limits.
- **Regression:** TC-233 covers an oversized title, overlong tag, excessive tag count, and a normal valid serialization.
- **Status:** Source and regression committed; test not run. Run TC-233 together with direct parsing and backup/repository boundary cases at the manual validation checkpoint. CI remains manual-only.

### TSK-521 — Bound direct SavedItem search-field processing — 2026-10-28

- **Requirements:** FR-005 and NFR-003/NFR-007.
- **Source:** The public model search helper rejects oversized stored field dimensions and tag lists before constructing a searchable list or lowercasing stored content, consistent with repository input limits.
- **Regression:** TC-234 covers oversized title/content/tags and confirms normal valid searches still work.
- **Status:** Source and regression committed; test not run. Validate alongside direct model parsing/serialization and the performance baseline at the manual validation checkpoint. CI remains manual-only.

### TSK-522 — Validate timestamps in direct SavedItem parsing — 2026-10-28

- **Requirements:** FR-002 and NFR-003.
- **Source:** The model and backup codec share the same supported millisecond range; the public SavedItem.fromMap() factory rejects integer timestamps outside that range before returning a model.
- **Regression:** TC-235 covers invalid created/updated timestamps and a valid parse.
- **Status:** Source and regression committed; test not run. Validate direct parsing and recovery paths at the manual validation checkpoint. CI remains manual-only.

### TSK-523 — Validate timestamps in direct SavedItem serialization — 2026-10-28

- **Requirements:** FR-002 and NFR-003.
- **Source:** SavedItem.toMap now rejects created/updated millisecond timestamps outside the supported DateTime range before returning a serialized map. Direct serialization and parsing use the same timestamp bounds and safe error.
- **Regression:** TC-236 covers invalid created/updated timestamps and an ordinary in-range serialization.
- **Status:** Source and regression are committed; tests remain unrun. Verify serialization, parsing, backup encode/decode and repository-save validation at the manual checkpoint. CI remains manual-only.

### TSK-524 — Guard direct SavedItem date getters — 2026-10-28

- **Requirements:** FR-002 and NFR-003.
- **Source:** The `createdAt` and `updatedAt` getters now validate their millisecond values against the shared supported date range before constructing a local `DateTime`, and report a stable error for invalid direct model instances.
- **Regression:** TC-237 covers invalid created/updated timestamps accessed through the public getters and a valid-value control.
- **Status:** Source and regression committed; tests remain unrun. Validate with TC-235/TC-236, repository timestamp checks and backup encode/decode at the manual checkpoint. CI remains manual-only.

### Phase 3 — timestamp boundary regression (2026-10-29)

- Added **TC-238** to verify both inclusive timestamp limits survive direct SavedItem.toMap() / SavedItem.fromMap() round-trips, complementing the existing rejection checks for values one millisecond outside the supported range.
- Added **TSK-525** to track this boundary regression. Source is committed; no formatter, analyzer, tests or builds were run. Validation remains deferred to the owner’s manual checkpoint.

### Phase 3 — immutable model copy snapshots (2026-10-29)

- `SavedItem.copyWith()` now creates an unmodifiable snapshot of its tag list, including when no replacement list is supplied. This closes a shallow-copy path where later caller mutation could silently change a supposedly immutable model.
- Added **TC-239** and **TSK-526**. Regression source is committed; execution remains pending because CI/builds are intentionally manual-only.

### TSK-526 — Preserve immutable tag snapshots when copying SavedItem — 2026-10-29

- **Requirements:** FR-001 and FR-002.
- **Source:** `SavedItem.copyWith()` now wraps the chosen tag list in `List<String>.unmodifiable`, preventing caller-owned mutable lists from changing the copied model after construction.
- **Regression:** TC-239 verifies mutation of a replacement list, mutation of the original item’s list, and rejection of direct mutation through the copied model.
- **Status:** Source and test are committed. Test execution and formatting/analyzer checks remain pending at the manual checkpoint; CI remains manual-only.


### TSK-527 — Keep synchronous item lookups on committed snapshots — 2026-10-29

- **Requirements:** FR-002 and NFR-003.
- **Source review:** The repository publishes an immutable item snapshot and updates its ID index before notifying listeners. A regression now pauses a replacement save before the item record commits and checks that both findById() and items continue to expose the previous revision until commit.
- **Regression:** TC-240.
- **Status:** Regression source is committed to main; test execution, formatting and analyzer checks remain pending. CI remains manual-only.


### TSK-528 — Make SavedItem constructor tags immutable — 2026-10-29

- **Requirements:** FR-001 and NFR-003.
- **Source:** The SavedItem constructor now snapshots its caller-supplied tags into an unmodifiable list. This closes the remaining direct-construction path where an external mutable list could change an existing model instance.
- **Regression:** TC-241 mutates the source list after construction and attempts direct mutation through the model.
- **Status:** Source and regression are committed to main. Tests, formatting and analysis are intentionally pending until the manual validation checkpoint; CI remains manual-only.


### TSK-529 — Validate share de-duplication limits in release builds — 2026-10-29

- **Requirements:** FR-008 and NFR-003.
- **Source:** ShareEventDeduplicator now validates its public time-window and cache-capacity parameters at runtime instead of relying on assertions that are omitted in release builds. Cache capacity is also capped at 256 entries, so custom callers cannot disable the intended memory bound by selecting an excessive value.
- **Regression:** TC-242 covers zero and negative time windows and capacities, rejects values above the hard maximum and accepts the maximum supported capacity.
- **Status:** Source and regression are committed to main; tests, formatting and analysis remain pending at the manual validation checkpoint. CI remains manual-only.

### TSK-530 — Atomically update Android share manifest — 2026-10-29

- **Requirements:** FR-008 and NFR-003.
- **Source:** The Android share configurator writes the serialized manifest to a same-directory temporary file, flushes it, preserves the existing file mode and atomically replaces the target only after serialization succeeds. Failed replacement cleans up the temporary file and leaves the old manifest in place.
- **Regression:** TC-243 simulates replacement failure and checks the original manifest remains unchanged and no temporary file is left behind.
- **Status:** Source and regression are committed to main; Python tests remain pending at the manual validation checkpoint. CI remains manual-only.


### TSK-304 — Initial code-level privacy and safety review — 2026-10-29

- **Source review:** Reviewed Dart source for direct diagnostic logging calls; none were found. Item Details revalidates stored URLs with an HTTP/HTTPS-only parser before external launch. Share intake bounds content lengths, MIME/path metadata, batch size and attachment reads.
- **Manifest boundary:** Android native files are generated by the manual workflow. The checked-in configurator only changes the app label/launch mode and registers incoming-share MIME filters; it does not add permission declarations.
- **Open validation:** Inspect the generated merged manifest and resolved plugin permissions, capture actual network behavior, and complete Android/browser screen-reader and real-device privacy checks. Do not mark DONE from source review alone.


## Phase 2/3 source-development handoff — 2026-10-29

The active Phase 2/3 source queue has reached the point where the next meaningful step is validation on the manual checkpoint rather than further unverified source churn.

### Implemented in source
- Local library CRUD, collection/tag handling, metadata search, item details, and backup/restore flows.
- Bounded and validated attachment import, safe external URL launching, backup decoding, rollback/recovery paths, and immutable model/repository snapshots.
- Android incoming-share integration with sequential user review, bounded queue/deduplication, manifest configuration, and safe failure handling.
- Responsive/large-text and accessibility source support, error-state feedback, and privacy/data-loss messaging.
- Regression coverage and traceability entries for the hardening changes, including share-intake bounds, rollback consistency, timestamp boundaries, immutable copies, and atomic manifest replacement.

### Testing handoff — not yet verified
- **No tests, formatter, analyzer, CI workflow, or platform builds were run for the recent increments.** Their source and regressions are committed, not proven to pass.
- The next checkpoint is to run the manual workflow, resolve any Flutter/Dart or Android FilePickerPlugin build issues, and then perform the browser/Android smoke tests against the seven committed screen references.
- Required validation includes share-in from real Android apps, browser-profile persistence, backup export/restore and failure recovery, accessibility/screen-reader behavior, and a performance baseline.
- OCR/PDF text extraction remains gated on a separate feasibility study and is not part of this source handoff. Release readiness must not be claimed until validation evidence is added to the traceability matrix.


### TSK-531 — Apply shared premium UI language to StashHive — 2026-10-29

- **Requirements:** FR-004, FR-018 and NFR-006.
- **Source:** Added the shared FinMate/Stockly `PremiumTokens` and reusable components, then applied their blue/mint palette, rounded Material 3 theme, premium page headers, empty state, settings hero/icon chips and stronger selected navigation icons to StashHive. Refreshed all seven editable screen references and the mobile-flow board to the current palette, while keeping StashHive-specific screens and behavior.
- **Regression:** TC-244 covers the documented tokens, page header, icon chip and empty-state action.
- **Status:** Source and test are committed on main; no formatter, analyzer, widget tests or visual platform checks have run. Validate with all seven references during the manual checkpoint.

### TSK-532 — Pin shared Flutter and Android build configuration — 2026-10-29

- **Requirements:** NFR-009.
- **Source:** StashHive now declares minimum Dart 3.13.2/Flutter 3.47.2, and the manual workflow pins Flutter 3.47.2/JDK 27. `tool/configure_android_build.py` normalizes the generated runner to AGP 9.4.0, Kotlin 2.4.10, Gradle 9.8.1, compile SDK 36, Build Tools 36.1.0 and JVM target 17, enables AGP built-in Kotlin consistently, and creates StashHive adaptive hive launcher resources.
- **Regression:** TC-245 covers the generated build baseline, launcher resources, idempotence and fail-clear behavior.
- **Status:** Source and test are committed on main. Do not mark complete until the manual Python tests, analyzer, full tests, web build and Android debug APK succeed; CI remains manual-only.
