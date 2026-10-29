# StashHive — Master Feature Status & Chat Handoff

**Last audited:** 2026-10-29  
**Repository:** [senorita-ai0/StashHive](https://github.com/senorita-ai0/StashHive)  
**Default branch:** `main`  
**Audit baseline commit:** `f861bae384e15fbe5ca12419ed010d3723ce9113`  
**Purpose:** This is the short, durable status page for the owner and any future ChatGPT session. Read it before resuming development and update it after every meaningful implementation, test, build, or scope change.

> **Important status distinction:** “Source implemented” means code and/or test source has been committed. It does **not** mean tests pass or the feature is ready. Mark a feature fully done only when its required automated and platform checks have evidence recorded.

## 1. Overall project status

| Area | Current status | Evidence / next action |
|---|---|---|
| Product blueprint and local-first principles | Source scope approved | See `docs/requirements.md`, `docs/architecture.md`, and `AGENTS.md`. |
| Core Flutter library | Source implemented | Library, Search, Collections and Settings; typed items; tags, collections, favorites; metadata search; details; local repository; JSON backup/restore. Execution and current platform behavior still require verification. |
| Priority feature source work | Several slices implemented | See the SH-001–SH-014 table below. Most added tests have been authored but deliberately not run. |
| Android share intake | Source implemented; device validation pending | Shares should open editable Quick Save drafts; check real provider/MIME types and cold/warm starts. |
| Web storage | Source implemented; persistence/quota validation pending | Browser storage is local to the profile/origin; there is no automatic sync. |
| Android build | **BLOCKED / UNVERIFIED** | A previous Android debug build failed with a missing `FilePickerPlugin` class. `file_picker 12.3.0` is a candidate fix, not confirmed. |
| Web build | Historical result only | A previous pre-Phase-2 web build passed. No current build has been run against all subsequent source changes. |
| Formatting, analyzer, unit/widget tests | **NOT RUN for recent increments** | Do not report green until the owner's manual validation checkpoint is run and results are recorded. |
| CI policy | **Manual-only** | `.github/workflows/flutter.yml` uses `workflow_dispatch`; never trigger it unless the owner asks for validation. |
| Release readiness | **NOT READY / NOT VERIFIED** | Android build, web build, automated suite, physical-device checks, browser persistence, backup recovery, accessibility, and performance checks remain pending. |

## 2. Feature implementation table

**Legend**
- **Source implemented** — core source and expected regression source are present; checks may still be pending.
- **Partial** — some usable scope is present; one or more explicitly requested parts remain.
- **Blocked** — a proof of concept or decision is required before production implementation.
- **Not started** — no implementation slice has been committed.
- **Verification pending** — tests/builds/manual checks have not confirmed the feature.

| ID | Feature | Implementation status | Verification status | Remaining work / exit criteria |
|---|---|---|---|---|
| SH-001 | Duplicate link detection and review | **Source implemented** — normalized URL matching; Quick Save shows matches and asks whether to cancel or explicitly save another copy. | **Pending** | Run URL-normalization unit tests and Quick Save widget tests; inspect false-positive boundaries. Exact attachment hashes and duplicate review during backup import are future scope. |
| SH-002 | Advanced Search and Smart Collections | **Source implemented** — combined type/tag/collection/domain/favorite/date filters; saved local presets and Organize Smart Searches. | **Pending** | Run TC-247–TC-249 and associated widget/repository tests; verify persistence and responsive/accessible filter UX. |
| SH-003 | Bulk library actions | **Source implemented** — select items; favorite, move collection, add/remove tags, confirmed delete, selected-only Markdown export. | **Pending** | Run TC-251, TC-252, TC-260 and widget regressions; verify cancellation, selection boundaries, and partial-failure feedback. |
| SH-004 | Import and portable exports | **Source implemented** — preview-first browser bookmark HTML import, duplicate review, CSV export and selected Markdown export; existing versioned JSON backup remains. | **Pending** | Run TC-253, TC-254, TC-260–TC-261; test malformed/large imports, duplicate entries, folder assignment, cancellation, and export file behavior. |
| SH-005 | Local PDF/OCR full-text extraction | **Blocked / feasibility only** — an isolated digital-PDF selectable-text probe exists; no production OCR dependency has been added to the app. | **Not run** | Run the isolated probe and record runtime/accuracy, offline behavior, memory, package-size delta, and language limitations. Scanned-PDF/image OCR (including Urdu/Nastaleeq) remains unproven; do not promote to production until evidence and owner approval. |
| SH-006 | Reader, highlights and annotations | **Partial** — manually entered quote/note annotations can be attached to items, displayed, deleted, searched, and included in JSON/CSV/Markdown outputs. | **Pending** | In-app article reader and selecting/highlighting text from rendered article content are **not implemented**. Define a user-initiated and privacy-aware content-loading approach before implementation; then add tests. |
| SH-007 | Visual library improvements | **Source implemented** — persistent Library grid/list toggle. | **Pending** | Run TC-255 and responsive/accessibility checks; masonry and further image/document preview improvements remain optional refinements. |
| SH-008 | Smart organization rules | **Source implemented** — local rule manager, bounded preference storage, suggested tags shown as reviewable Quick Save chips. | **Pending** | Run TC-258 and confirm suggestions are optional, explainable, removable, and do not silently change saved items. |
| SH-009 | Link health and archive status | **Source implemented** — on-demand Android HTTP status check, bounded local check history, private-address blocking, and honest browser limitations. | **Pending** | Run TC-259; verify timeouts, redirects, local/private targets, network errors, Android behavior and browser copy. This does not create an offline page archive. |
| SH-010 | Rediscovery and reading progress | **Source implemented** — reading status/progress and a local Rediscover filter showing items at least 14 days old that are not Completed, oldest first. | **Pending** | Run TC-256 and TC-263; verify age cutoff, ordering, persistence, UI/accessibility and progress semantics. |
| SH-011 | Optional cross-device sync | **Not started** | N/A | Requires separate design for opt-in encryption, account/key recovery, conflict resolution, privacy, and server costs. Android and web libraries remain separate. |
| SH-012 | Feeds, newsletters, transcripts and text-to-speech | **Not started** | N/A | Defer until core capture/search/restore are validated; decide supported sources, user-initiated network behavior and accessibility requirements. |
| SH-013 | Semantic and visual discovery | **Not started** | N/A | Research local semantic/similar-image/color search only after privacy, dependency, performance and device feasibility review. No mandatory cloud/paid AI. |
| SH-014 | Platform assurance and recoverability | **In progress** — many hardening/regression sources exist. | **Pending** | Validate Android plugin/build/share intake, web persistence/quota, backup rollback, accessibility/screen readers, privacy/network, and 100/1,000/10,000-item performance. |

## 3. Existing core features (source baseline)

These are present in the repository, but the feature-complete label must not be confused with current build/test proof:

| Capability | Source state | Notes |
|---|---|---|
| Save/edit/delete links, notes, images, documents/PDFs | Implemented in source | User-selected attachments use a documented size limit. |
| Tags and collections | Implemented in source | Collection and saved-item integrity/rollback paths have regression sources. |
| Metadata Search | Implemented in source | Searches stored title, URL, notes/text, tags and collection data; OCR/PDF extracted text is not part of the live app. |
| Item details, favorite, sort and Library filters | Implemented in source | Review the screen reference and tests before altering UI. |
| Versioned JSON backup/restore | Implemented in source | Defensive parsing and rollback regressions exist; real interruption/platform recovery remains unverified. |
| Android incoming-share capture | Implemented in source | External content must be reviewed by user in Quick Save; never silently save. |
| Responsive/premium UI, text scaling and accessibility improvements | Implemented in source | Must be checked against the seven committed screen references and with actual assistive technology. |
| Local smart-tag rules, link health, read progress and Rediscover | Implemented in source in the feature slices above | All recent regressions remain unverified until tests are run. |

## 4. Current validation blockers

The project is not ready for release or hand-off to end users until the owner-approved manual validation checkpoint supplies results for:

1. Run the Python Android configurator tests; Dart formatter; Dart analyzer; all unit/widget tests; isolated PDF probe tests separately.
2. Build the Flutter web release and Android debug APK. In particular, confirm or fix the historical `FilePickerPlugin` Android compile failure.
3. On an Android device, test shared URL/plain text/image/PDF, cold/warm start and multi-item save/cancel behavior.
4. On a supported browser, test reload persistence, quota/failure feedback, backup/export/import and responsive keyboard/accessibility behavior.
5. Test save/edit/delete, duplicate review, advanced filters/presets, bulk actions, HTML import/export, annotations, smart rules, link health, reading progress and Rediscover.
6. Inspect logs/network/merged Android manifest and plugin permissions for privacy; do not transmit or log saved content.
7. Record performance at 100, 1,000 and 10,000 metadata-only items; do not add OCR dependencies without before/after app-size, memory, latency, offline and language evidence.
8. Update the related test case, traceability row and this page with actual outcomes. Never mark a check passed based solely on authored source.

Historical note: the pre-Phase-2 pipeline passed dependency resolution, formatting, analysis, tests and the web release build, but the Android build failed. Those old results do not verify current source.

## 5. Next work queue

1. **Do not repeat SH-001–SH-004 implementation from scratch.** Their source slices are already on `main`; first validate them at the planned manual checkpoint when the owner requests it.
2. **SH-005 remains gated** until the isolated PDF probe has evidence. Do not integrate a PDF/OCR package into the main app yet.
3. Continue the unfinished part of **SH-006** only after documenting an explicit user-initiated article-content approach; reader mode and selection-based highlights remain outstanding.
4. Continue small SH-007–SH-010 refinements only when justified by implementation gaps; do not mark them fully done until tests/platform checks have evidence.
5. After each feature slice, update: this page, `docs/FEATURE_BACKLOG.md`, `docs/implementation-progress.md`, `docs/roadmap.md`, `docs/test-plan.md`, and `docs/traceability-matrix.md` as applicable.

## 6. Instructions for a new chat (copy/paste)

> Continue development of **StashHive** in `https://github.com/senorita-ai0/StashHive`. First read `AGENTS.md` and `docs/FEATURE_STATUS.md`, then inspect the latest `main` commit and the relevant feature/test files. This page is the master handoff; use `docs/FEATURE_BACKLOG.md` for feature scope and `docs/implementation-progress.md` for detailed source history. Keep all changes directly on `main`; do not create a branch or PR. Do not trigger CI/builds or run the final validation workflow unless I explicitly request the manual validation checkpoint. Never claim tests/builds pass unless actually run. Continue from the next incomplete slice in this status table, and update this status page and the related backlog/progress/roadmap/test/traceability documents on every feature change. The latest audited source baseline for this status page was `f861bae384e15fbe5ca12419ed010d3723ce9113`; re-check the current HEAD before editing.
## 7. Development continuation — 2026-10-29

- Latest inspected commit before this update: `5735bedb277afb10b72e754bb007c949bde9118d` (roadmap handoff link). This status page's earlier audit baseline was stale; current work was performed against `main`.
- Read `AGENTS.md`, this master status, backlog, implementation progress, roadmap, test plan, traceability matrix, requirements, architecture, README and screen references before choosing the next slice.
- **Next incomplete feature remains SH-006.** Existing manual quote/note annotations are source-implemented; an in-app article reader and selection-based highlights remain not started.
- Added `docs/research/article-reader-feasibility.md` as a design/privacy gate before reader implementation. It requires explicit user initiation, safe URL/network boundaries, strict resource limits, plain-text rendering of untrusted content, and a clear distinction between temporary fetched preview and offline archive.
- No application source or tests were changed in this design-only increment. No tests, analyzer, formatter, or builds were run. CI remains manual-only.
- Next source task: inspect and reuse the existing annotation model/repository and Item Details screen, then implement a bounded, injectable reader fetch/parse slice with unit tests before adding selection/highlight behavior.

## SH-006 source increment — 2026-10-29

- Added an explicit **Read in StashHive** action to Item Details for saved HTTP(S) links. It only opens the reader route after a user tap; save, search and background flows do not initiate a fetch.
- Added a bounded native reader service: HTTP(S) only, reject URL credentials and private/reserved destinations, resolve and pin a public destination address, refuse redirects, accept HTML/plain text only, cap the response at 1 MiB and displayed text at 60,000 characters, and apply a short timeout.
- Native reader content is sanitized to plain text; script/style/iframe/object/template/svg/noscript blocks are removed before display. Page content is held in transient UI state and is not added to SavedItem, repository storage or backups.
- Web behavior deliberately reports cross-origin/CORS limitations and offers the external-browser path; no proxy was added. The external-browser action remains available on the reader screen.
- Added test/article_reader_test.dart source for URL scheme/credential/private-literal rejection, text sanitization and Unicode normalization. These tests have **not** been run.
- **Still incomplete:** selection-based quote/highlight capture and offset/context metadata. Native fetch behavior, security edge cases, web UX, analyzer, formatter, unit/widget tests, Android build and web build remain unverified. Do not mark SH-006 complete.
- CI remains manual-only; no workflow, build, formatter, analyzer or test command was run for this source increment.
- Latest source commits include 4cfec61 (Item Details integration), 6ac3610 (native sanitizer reuse) and b8c8ff7 (reader regression source). Re-check HEAD before the next edit.
