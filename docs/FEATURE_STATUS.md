# StashHive — Master Feature Status & Chat Handoff

**Last audited:** 2026-10-30  
**Repository:** [senorita-ai0/StashHive](https://github.com/senorita-ai0/StashHive)  
**Default branch:** `main`  
**Audit baseline commit:** `ca09268a44a70cb4e8a2e7cd915755dc604eded5`  
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
| SH-006 | Reader, highlights and annotations | **Partial source implemented** — explicit reader action, bounded native temporary preview, single-pass common HTML entity decoding, HTTP charset plus bounded early HTML meta charset fallback (ignoring comments and embedded script/style/noscript blocks), UTF-8 BOM stripping, Unicode-safe title/body caps, selectable text, save-selected-quote action, and bounded context/offset metadata on local annotations; quote/context capture normalizes UTF-16 surrogate-pair boundaries. | **Pending** | Validate native fetch/URL protections, entity/charset decoding including TC-273–TC-282, browser fallback, selection UX (including Unicode boundary handling), annotation/backup and CSV/Markdown export compatibility, and accessibility. Article extraction remains a lightweight sanitizer, not a full readability engine; saved offsets may not re-anchor after page changes. |
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
3. Continue **SH-006 validation and hardening**: reader and selection-based quote capture are source-implemented, but platform behavior and regression suites remain unverified. Do not claim reliable highlight re-anchoring after article changes.
4. Continue small SH-007–SH-010 refinements only when justified by implementation gaps; do not mark them fully done until tests/platform checks have evidence.
5. After each feature slice, update: this page, `docs/FEATURE_BACKLOG.md`, `docs/implementation-progress.md`, `docs/roadmap.md`, `docs/test-plan.md`, and `docs/traceability-matrix.md` as applicable.

## 6. Instructions for a new chat (copy/paste)

> Continue development of **StashHive** in `https://github.com/senorita-ai0/StashHive`. First read `AGENTS.md` and `docs/FEATURE_STATUS.md`, then inspect the latest `main` commit and the relevant feature/test files. This page is the master handoff; use `docs/FEATURE_BACKLOG.md` for feature scope and `docs/implementation-progress.md` for detailed source history. Keep all changes directly on `main`; do not create a branch or PR. Do not trigger CI/builds or run the final validation workflow unless I explicitly request the manual validation checkpoint. Never claim tests/builds pass unless actually run. Continue from the next incomplete slice in this status table, and update this status page and the related backlog/progress/roadmap/test/traceability documents on every feature change. The latest audited source baseline for this status page was `ca09268a44a70cb4e8a2e7cd915755dc604eded5`; re-check the current HEAD before editing.
## 7. Development continuation — 2026-10-29

- Latest inspected commit before this update: `5735bedb277afb10b72e754bb007c949bde9118d` (roadmap handoff link). This status page's earlier audit baseline was stale; current work was performed against `main`.
- Read `AGENTS.md`, this master status, backlog, implementation progress, roadmap, test plan, traceability matrix, requirements, architecture, README and screen references before choosing the next slice.
- **Next incomplete feature remains SH-006.** Existing manual quote/note annotations are source-implemented; an in-app article reader and selection-based highlights remain not started.
- Added `docs/research/article-reader-feasibility.md` as a design/privacy gate before reader implementation. It requires explicit user initiation, safe URL/network boundaries, strict resource limits, plain-text rendering of untrusted content, and a clear distinction between temporary fetched preview and offline archive.
- No application source or tests were changed in this design-only increment. No tests, analyzer, formatter, or builds were run. CI remains manual-only.
- Next source task: inspect and reuse the existing annotation model/repository and Item Details screen, then implement a bounded, injectable reader fetch/parse slice with unit tests before adding selection/highlight behavior.

## SH-006 source increment — 2026-10-29

- Added an explicit **Read in StashHive** action to Item Details for saved HTTP(S) links. It only opens the reader route after a user tap; save, search and background flows do not initiate a fetch.
- Added a bounded native reader service: HTTP(S) only on standard ports (80/443), reject URL credentials and private/reserved destinations, resolve and pin a public destination address, refuse redirects, accept HTML/plain text only, cap the response at 1 MiB and displayed text at 60,000 characters, and apply a total response deadline. IPv6 native destinations are conservatively blocked in this first slice.
- Native reader content prefers semantic article/main containers when present, then sanitizes to plain text; script/style/iframe/object/template/svg/noscript/navigation/footer/aside blocks are removed before display. This remains a lightweight fallback, not a full readability engine. Page content is held in transient UI state and is not added to SavedItem, repository storage or backups.
- Web behavior deliberately reports cross-origin/CORS limitations and offers the external-browser path; no proxy was added. The external-browser action remains available on the reader screen.
- Added test/article_reader_test.dart source for URL scheme/credential/private-literal rejection, text sanitization and Unicode normalization, plus test/article_reader_page_test.dart for invalid-URL recovery and the selected-passage save flow using an injectable reader result. These tests have **not** been run.
- **Now source-implemented:** selection-based quote capture stores the selected text, bounded surrounding context and offsets in the existing annotation record; Item Details shows the context to help identify excerpts. **Still incomplete:** platform verification, robust article extraction/readability quality and final regression evidence. Native fetch behavior, security edge cases, web UX, analyzer, formatter, unit/widget tests, Android build and web build remain unverified. Do not mark SH-006 complete.
- CI remains manual-only; no workflow, build, formatter, analyzer or test command was run for this source increment.
- Latest source increments include 3f2e1fb (select and save reader passages), 7bcb082 (persist quote offsets/context), and cda6eee (preserve external-browser opening when reader blocks a target). Re-check HEAD before the next edit.

## SH-006 deterministic transport regression increment — 2026-10-29

- Refactored the native reader into a testable DNS/transport boundary without changing production networking: production still uses OS DNS, vetted/pinned public IPv4 sockets and direct HTTP; test-only hooks can supply DNS answers and synthetic responses.
- The synthetic native response policy now has regression source for a sanitized HTML success path, redirect responses, unsupported MIME, oversize response, display-text truncation, a matrix of reserved/private IPv4 answers, mixed public/private DNS, DNS timeout, HTTP error response and transport timeout. Additional sanitizer source checks malformed unclosed script/comment tails.
- Enforced one absolute deadline across DNS resolution, request/response phases and body reading, rather than restarting the full timeout at every stage.
- Added test/article_reader_repository_test.dart to verify no reader request occurs on details-screen load, a tap starts one request, opening a temporary preview leaves the saved record unchanged, saving a selected passage persists only the user-approved annotation, and portable backup contains the annotation but not the full fetched article. Reader success/failure feedback now appears on the visible Reader route, with widget-test source for both outcomes. TC-264–TC-268 have partial regression source, but none has been run; actual platform checks remain pending.
- Source review caught and corrected malformed expressions in the sanitizer hardening and hostname-validation edits; both complete functions were re-fetched after repair. No tests, formatter, analyzer or builds were run. Android/web behavior is still unverified. CI remains manual-only.
- Latest relevant commits include a774ec0 (repair/complete native title extractor), 627717f (fake-title regression), b818cad (reader source integrity repair), and 4501f50 (navigation/control-character regressions). Re-check HEAD before the next edit.


## SH-006 reader decoding polish — 2026-10-29

- Fixed the native response decoder's Windows-1252 handling. Declared windows-1252 and cp1252 now map the punctuation/symbol bytes in the 0x80–0x9F range instead of treating them as Latin-1 controls; latin1 and iso-8859-1 keep their separate byte mapping.
- Added a synthetic transport regression for quoted Windows-1252 charset declarations and euro sign, curly quotes, and em dash output. The test is authored only and has not been run.
- Latest source commits: 94c4677 (Windows-1252 decoding fix) and a350571 (reader charset regression source). Re-check HEAD before the next edit.
- SH-006 remains partial. No test, formatter, analyzer or build was run; Android/web verification remains pending and CI remains manual-only.


## SH-006 export non-persistence regression — 2026-10-29

- Extended the repository/reader widget regression source to generate CSV and selected-Markdown exports after a selected quote is saved. It checks that each export contains the user-saved quote but does not contain the complete temporary article body.
- The regression also retains the portable JSON backup assertion: the annotation survives backup while the complete fetched text does not enter the saved item's content.
- Source only; these tests have not been executed. Android/web selection, actual share targets, accessibility and all validation checkpoints remain pending. Latest reader export-test commit: f770abb.


## SH-006 legacy charset regression follow-up — 2026-10-29

- Added coverage for the cp1252 charset alias and a separate Latin-1 byte mapping, alongside the quoted Windows-1252 charset case. This test source is committed but has not been executed.
- Latest charset test commit: 1ed3b06. No formatter, analyzer, test or build was run. CI remains manual-only; SH-006 remains partial.


## SH-006 reader accessibility source refinement — 2026-10-29

- Added semantic labels to Reader loading and save-progress indicators and marked the article title and unavailable-state title as semantic headings.
- Added widget regression source that holds a synthetic reader response pending and checks for the accessible loading label. The test is not run; a screen-reader/device audit and remaining error-state accessibility checks are still required.
- Commits: 10e1f87 (UI semantics) and e8d0fab (widget regression source). SH-006 remains partial; CI remains manual-only.


## SH-006 reader save-progress accessibility regression — 2026-10-29

- Added a deterministic widget regression using a deliberately pending highlight-save callback. It checks that the saving indicator exposes the semantic label “Saving highlight”, then completes the save and confirms the normal success message appears.
- This is authored source only; the widget test has not been run. Actual TalkBack/VoiceOver/keyboard behavior remains pending. Commit: 7df2f18.


## SH-006 HTML entity decoding refinement — 2026-10-29

- Expanded safe common named-entity decoding for copyright/registered/trademark marks, currency, quotes, bullets and typographic symbols.
- Reordered decoding so numeric references are handled before named references. This prevents escaped text such as `&amp;#169;` from being recursively unescaped during a single sanitizer pass; untrusted output remains plain text.
- Added a regression for common named entities, uppercase entity names, a numeric hexadecimal reference and non-recursive escaped-ampersand cases. Test source is authored but unrun. Commits: abbb973 and a79b9fd.
- Also added a delayed-save accessibility test (7df2f18). No tests, formatter, analyzer or builds were run; SH-006 remains partial and CI manual-only.


## SH-006 semantic extraction hardening — 2026-10-29

- Active/embedded blocks and HTML comments are now removed before looking for an `<article>` or `<main>` container. This avoids a literal fake article tag inside a script string or comment being selected instead of the page's real article content.
- Added a synthetic regression combining a script-string `<article>`, a commented `<article>`, navigation chrome and a real article. The test is authored but has not been run.
- The sanitizer remains a lightweight text extractor, not a standards-complete HTML parser or Readability implementation. Commits: 9be6a98 (source) and 8809696 (test source). No tests, formatter, analyzer or builds were run; CI remains manual-only.


## SH-006 source integrity and extraction hardening — 2026-10-29

- Removed a stale duplicated tail from `lib/services/article_reader.dart` that repeated the URL validator, sanitizer and loader and left malformed text after the first loader definition. Re-fetched the committed file and confirmed one declaration each for `parseArticleReaderUrl`, `_isPrivateIpv4Literal`, `sanitizeArticleMarkup`, and `loadArticleForReader`, with no leftover malformed fragment.
- Sanitizer preprocessing now removes active/embedded markup, navigation/footer/aside containers and comments before searching for article/main, preventing fake article tags inside those regions from shadowing real content. It also replaces non-printing control bytes with spaces while retaining Unicode and normalizing line breaks.
- Regression source now includes script/comment/navigation fake-article markup and non-printing text-control characters. These tests are authored but unrun. Commits: b818cad and 4501f50. SH-006 remains partial; formatter, analyzer, tests, builds and platform verification are pending; CI remains manual-only.


## SH-006 embedded title extraction hardening — 2026-10-29

- Native article metadata extraction now removes script/style/noscript/SVG/iframe/object/template blocks and HTML comments before looking for the document `<title>`, so title-shaped strings in scripts/comments cannot take precedence over the real title. The actual title text still passes through the reader's plain-text/entity sanitizer and remains capped at 300 characters.
- Added a synthetic HTTP response regression with fake titles in both script and comment content and a real entity-encoded title. The new case is committed but not run.
- Source review caught malformed duplicate tail content after the first title edit; the IO service was reconstructed from its valid prefix plus one complete title extractor and one public-address helper. A fresh fetch confirms one declaration each for loader, fetch, response parser, charset parser, text decoder, title extractor, and address checker. Commits: a774ec0 and 627717f. SH-006 remains partial; all validation stays pending, CI manual-only.


## SH-006 UTF-8 BOM decoding — 2026-10-29

- Native reader decoding now recognizes a leading UTF-8 byte-order mark (EF BB BF) and removes it before rendering the temporary article/plain-text preview; the signature no longer appears as the first visible character.
- Added TC-270 regression source using an injected plain-text response with a leading UTF-8 BOM. This source change is committed, but the test has not been run.
- Commits: source `7c38b51`; regression source `5a78361`. SH-006 remains partial; no formatter, analyzer, tests, builds or CI were run. Android/web behavior and the full reader suite remain pending.


## SH-006 Unicode-safe Reader truncation — 2026-10-29

- Native Reader now truncates displayed article text and extracted titles at a UTF-16 boundary that will not leave a dangling surrogate when the cap falls between the two code units of an emoji or other supplementary Unicode character.
- Added TC-271 regression source with a supplementary character placed exactly across the 60,000-code-unit display limit; the case asserts the character is not split and no surrogate code units leak into the resulting text.
- Commits: source `3bf987e`; regression source `2588cc0`. This is source/test authoring only: no formatter, analyzer, tests, builds or CI were run. SH-006 remains partial pending test execution and Android/web verification.


## SH-006 Unicode-safe title regression — TC-272 (2026-10-29)

- Added a second Unicode-boundary regression for the 300-code-unit extracted-title cap. It places an emoji across the title limit and asserts the title does not contain a dangling surrogate while the article body remains readable.
- Test source committed as `0374c24`; the test has not been run. TC-271 covers the body cap and TC-272 covers the title cap. No formatter, analyzer, test, build or CI run was performed; SH-006 remains partial pending manual validation.


## SH-006 bounded HTML meta charset fallback — 2026-10-29

- Native Reader now uses an HTTP Content-Type charset when one is declared; when HTML has no HTTP charset, it scans only the first 1,024 bytes for a meta charset declaration and the legacy http-equiv/content charset form. This improves decoding of some older pages without scanning the entire body for encoding hints.
- Added regression source for direct meta charset and legacy http-equiv charset declarations using a Windows-1252 euro byte. Cases are TC-273 and TC-274; they have not been run.
- Commits: source 41f7e1b; regression cases ac7a62b. No formatter, analyzer, tests, builds or CI were run. Charset detection remains deliberately limited, not standards-complete; SH-006 stays partial pending manual validation.


## SH-006 embedded charset declaration filtering — TC-275 (2026-10-29)

- Hardened the bounded HTML charset prescan so comments and script/style/noscript blocks are removed from the scanned prefix before locating meta charset declarations. This prevents a fake tag embedded in untrusted content from overriding text decoding.
- Added TC-275 regression source containing fake Windows-1252 meta tags inside both an HTML comment and script text, with an invalid UTF-8 byte in the article body to make false detection visible.
- Source and test were committed together in df4b3c4 using a clean single-copy Reader file after an earlier attempted update duplicated source fragments. The committed Reader IO service and test file were re-fetched during the 2026-10-30 continuation; the fake-charset filter and regression each appear once. No tests, formatter, analyzer, build or CI were run; SH-006 remains partial.


## SH-006 HTTP charset precedence regression — TC-276 (2026-10-30)

- Added a deterministic Reader regression where the HTTP header declares Windows-1252 while the HTML meta tag declares UTF-8. The test expects byte 0x80 to decode as the euro sign, protecting the explicit-header-first policy already implemented in `_parseResponse`.
- Test source commit: `766b8dda50a8960f61414454b00978bd523b28c1`. The test has not been run. No formatter, analyzer, tests, builds or CI were run; SH-006 remains partial and CI manual-only.


## SH-006 bounded charset prescan limit regression — TC-277 (2026-10-30)

- Added a deterministic Reader regression placing a Windows-1252 meta tag after the first 1,024 response bytes. The test expects UTF-8 fallback (replacement character for byte 0x80), protecting the prescan's strict size bound.
- Test source commit: `95b0c68fbed0decc824d812e369ced76798016ba`. The test has not been run. No formatter, analyzer, tests, builds or CI were run; SH-006 remains partial and CI manual-only.


## SH-006 actual meta charset attribute parsing — 2026-10-30

- Hardened the bounded native HTML charset prescan to parse actual meta attributes rather than searching the entire tag string for \`charset=\`.
- A direct \`charset\` attribute is accepted. The legacy form is accepted only when \`http-equiv=Content-Type\` and the \`content\` attribute contains the charset declaration. Description/keyword values that merely mention charset syntax are ignored.
- Added TC-278 (ignore charset-like text in unrelated meta attributes) and TC-279 (continue to a real charset after unrelated metadata).
- Production source commits: \`7cf1c3553ae96c6c9509a0baee7b1cdd1811ce60\` and \`b6ff3fedc0161235a465bea23f01de734dfc636c\` (regex escaping correction). Regression source commit: \`e1ef640422f78f3315ed20572eb40ea649ecda5c\`.
- Updated test plan, traceability, backlog, implementation progress and roadmap. Source/test files were re-fetched, but no formatter, analyzer, test, build or CI run was performed. SH-006 remains partial; CI remains manual-only.


## SH-006 Unicode-safe Reader selection and context capture — 2026-10-30

- Added shared \`ArticleReaderSelection\` / \`captureArticleReaderSelection\` logic. Selection edges between UTF-16 surrogate code units expand outward to include the complete Unicode character; saved offsets are calculated from that same quote range.
- The helper applies the same edge protection to the bounded before/after context snippets. Collapsed and out-of-range selection offsets are rejected.
- \`ArticleReaderPage\` now uses this shared helper both when capturing the current selection and when preparing the save callback, preventing mismatch between visible quote, offsets and context.
- Added TC-280–TC-282 source regressions. Source commit: \`a79b83098c8443047ad12891bf712fb6e3588535\`; UI integration commit: \`1e58492ac78088d34cf61c3d686d52098e08281b\`; test commit: \`ca09268a44a70cb4e8a2e7cd915755dc604eded5\`.
- Updated architecture, backlog, implementation progress, roadmap, test plan and traceability. Re-fetched source/tests/docs contain the expected helper and regression tests. No formatter, analyzer, test, build or CI run was performed; SH-006 remains partial and CI manual-only.
