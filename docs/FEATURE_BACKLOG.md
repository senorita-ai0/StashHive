# StashHive — Feature Backlog

**Last reviewed:** 2026-10-30  
**Master status / new-chat handoff:** [docs/FEATURE_STATUS.md](FEATURE_STATUS.md) — update the master table and relevant detailed records after each feature increment.
**Implementation rule:** complete each feature as a small vertical slice: source, regression tests, user-facing behavior, documentation, and explicit verification status. Changes go directly to `main`; CI/builds remain manual-only.

## Principles

- Preserve StashHive's local-first and privacy-by-default behavior.
- Core library use must not require an account, cloud backend, or paid AI service.
- Do not claim cross-device sync, OCR, offline website archives, or link status without evidence.
- Avoid silent destructive actions. Duplicate candidates are suggestions; the user decides what to keep.
- Keep platform verification separate from source implementation. Do not report unrun tests/builds as passing.

## Prioritized backlog

| ID | Priority | Feature | Scope and acceptance criteria | Status |
|---|---|---|---|---|
| SH-001 | P1 | Duplicate link detection and review | Normalize URLs for duplicate checking (case-insensitive scheme/host, default ports, trailing slash, fragment and common tracking parameters). On a new link save, show matching saved links and ask whether to continue. Never silently discard or delete an item. Add tests for URL normalization, false-positive boundaries, and exclusion of the current edited item. Extend to exact attachment hashes only in a later slice. | SOURCE IMPLEMENTED — link-only review flow and regression source committed; execution pending |
| SH-002 | P1 | Advanced search and Smart Collections | Add type/tag/collection/domain/favorite/date filters and reusable saved filters. Filters must combine predictably, work offline, and persist locally. | SOURCE IMPLEMENTED — combined filters, saved presets and Organize Smart Searches; regression execution pending |
| SH-003 | P1 | Bulk actions | Allow multi-select, collection assignment, tag add/remove, favorite changes, export, and confirmed deletion. Partial failures must be reported and not silently lose items. | SOURCE + WIDGET REGRESSION SOURCE IMPLEMENTED — favorite/move/tag/delete and selected-only Markdown export; tests unrun |
| SH-004 | P1 | Importers and portable exports | Support a documented, tested bookmark HTML importer and selected service exports where a stable format exists. Add CSV and Markdown export without removing versioned JSON backup/restore. Validate file sizes/shapes and preview import counts before writing. | SOURCE + UNIT/WIDGET REGRESSION SOURCE IMPLEMENTED — preview-first HTML import, CSV export, selected Markdown; tests unrun |
| SH-005 | P1 / gated | Local full-text extraction | Prototype offline text extraction for PDFs and OCR for supported images. Measure accuracy across English, Urdu-script samples, Roman Urdu, app size, latency, memory, and failure handling before adopting a dependency. | BLOCKED — isolated digital-PDF probe scaffold committed; tests, runtime benchmarks, platform/size measurements still pending. See `tool/pdf_text_extraction_poc/README.md` and `docs/research/local-text-extraction-feasibility.md` |
| SH-006 | P2 | Reader mode, highlights, and annotations | Add optional readable article content only through a user-initiated flow; support highlights and personal notes tied to a saved item. Clearly distinguish bookmark metadata, temporary preview, and an offline archive. | PARTIAL SOURCE IMPLEMENTED — explicit temporary reader, bounded fetch, selectable quote capture, Unicode-safe offsets, conservative exact-quote/context re-anchoring with explicit user confirmation; tests/platform checks unrun |
| SH-007 | P2 | Visual library improvements | Improve image/document previews and add useful grid/masonry layouts without degrading list navigation, accessibility, or performance for large libraries. | SOURCE IMPLEMENTED — persistent grid/list toggle and regression source committed; execution pending |
| SH-008 | P2 | Smart organization rules | Offer user-controlled rules and suggested tags. Keep basic tagging functional without AI; suggestions must be explainable, optional, and reviewable before applying. | SOURCE IMPLEMENTED — local rule manager, bounded preference storage and Quick Save review chips committed; regression tests unrun |
| SH-009 | P2 | Link health and archive status | Provide an explicit user-triggered or configurable check, record last checked status and time, and explain that network failures may be temporary. No hidden background scraping. | SOURCE IMPLEMENTED — on-demand Android HTTP status check, bounded local result history, private-address blocking and honest browser limitations; tests unrun |
| SH-010 | P2 | Rediscovery and reading progress | Add optional unread/read status, progress, and a revisit view for older saved items. Reminders/notifications require separate UX and permission review. | SOURCE + UNIT/WIDGET REGRESSION SOURCE IMPLEMENTED — status/progress, 14-day Rediscover filter and oldest-first queue; verification pending |
| SH-011 | P3 | Optional cross-device sync | Design opt-in encrypted synchronization, conflict resolution, authentication and key recovery only after local reliability is validated. Android and web remain separate until sync is actually implemented and tested. | NOT STARTED |
| SH-012 | P3 | Feeds, newsletters, transcripts, and text-to-speech | Consider RSS/newsletter intake, supported transcript saving, and playback only after the core capture/find loop is stable. Keep network access and content source visible. | NOT STARTED |
| SH-013 | P3 | Semantic and visual discovery | Evaluate local semantic search, similar-image and color search only after performance/privacy feasibility is demonstrated; no required cloud embeddings or paid inference. | NOT STARTED |
| SH-014 | Ongoing | Platform assurance and recoverability | Continue Android share-intent device checks, browser persistence/quota tests, backup/restore and rollback regressions, accessibility checks, performance measurements, and resolution of the historical Android FilePickerPlugin build failure. | IN PROGRESS — manual verification pending |

## Delivery sequence

1. **SH-001:** duplicate links and review prompt.
2. **SH-002:** advanced filters and saved filters.
3. **SH-003:** multi-select and bulk actions.
4. **SH-004:** bookmark import and additional exports.
5. **SH-005:** offline extraction proof of concept; implementation only if evidence meets the size, language and performance gates.
6. **SH-006–SH-010:** reading and workflow enhancements.
7. **SH-011–SH-013:** optional sync and advanced discovery, after privacy/architecture review.

## Definition of done for each feature

- Acceptance criteria are documented and traceable to tests.
- Relevant unit/widget tests are authored and source-reviewed.
- Existing backup compatibility, deletion semantics, and local-data privacy are preserved.
- Error, empty, loading, cancellation, and accessibility states are covered where applicable.
- Documentation states what is and is not implemented.
- Tests/builds are run only at the owner's requested manual validation checkpoint; otherwise explicitly report them as unverified.
## SH-006 reader implementation gate — 2026-10-29

Before source implementation, follow [the article-reader feasibility and privacy gate](research/article-reader-feasibility.md). First slice is an explicitly user-initiated temporary reader with bounded transport/parsing, safe plain-text rendering, recoverable states and tests. Do not persist fetched content or imply offline archives. Text selection/highlight anchoring is a separate follow-on slice after Android/web feasibility is proven. The initial reader and selection source is now committed; tests remain unrun and Android/web behavior remains unverified.

## SH-006 — reader source increment (2026-10-29)

- [x] Add explicit Item Details reader entry point and disclose that a tap sends a request from this device.
- [x] Add bounded native HTTP(S) fetch, public-address preflight/pinning, redirect refusal, supported content-type checks, byte/text/time limits and plain-text sanitization.
- [x] Keep browser CORS limitations explicit and preserve external-browser opening; no proxy or content persistence.
- [x] Author initial URL/sanitization regression tests.
- [ ] Run the new and existing tests at the owner-approved manual validation checkpoint.
- [ ] Validate Android network behavior, redirects/DNS/private destinations, response limits and accessible error states.
- [x] Add selection-based quote capture with bounded context and source offsets using Flutter selectable text; show context with the saved annotation.
- [ ] Verify selection and highlight save behavior on Android and web; the saved offsets are advisory because article content can change.

## SH-006 — deterministic transport hardening — 2026-10-29

- [x] Add test-only injectable resolver and transport response seams while retaining OS DNS and pinned direct sockets in production.
- [x] Add authored cases for success/sanitization, redirects, unsupported MIME, byte/display caps, private/mixed DNS answers, DNS timeouts and HTTP/transport errors.
- [x] Use one absolute deadline across the native request path.
- [ ] Run the test suite at the owner-approved manual validation checkpoint.
- [x] Add Item Details/repository regression source for no implicit fetch, explicit tap, unchanged bookmark fields after reader open, selected-quote-only persistence, and portable backup exclusion of full fetched article text.
- [x] Add a synthetic matrix for private/reserved IPv4 answer ranges and malformed unclosed script/comment tails.
- [x] Restrict native reader requests to standard HTTP/HTTPS ports (80/443); the external browser remains available for other ports.
- [x] Keep highlight success/failure feedback on the Reader route and author widget regression source for visible save confirmation and retry after failure.
- [x] Add reader/repository regression assertions for non-persistence of the complete temporary article body in JSON backup, CSV and selected Markdown exports.
- [ ] Expand remaining content-parsing edge cases and native/platform error accessibility; run all reader/export regressions at the owner-approved checkpoint.
- [ ] Complete TC-264/267/268 repository and platform assertions; SH-006 remains partial.


## SH-006 — response text-encoding refinement (2026-10-29)

- [x] Decode declared Windows-1252 (windows-1252 / cp1252) punctuation and symbol bytes correctly instead of interpreting them as Latin-1 control characters.
- [x] Add a deterministic synthetic-response regression for a quoted charset parameter and representative legacy punctuation.
- [ ] Run charset and complete reader tests at the owner's manual validation checkpoint; test source has not been executed.
- [ ] Keep SH-006 partial until native/web behavior, tests, accessibility, and platform checks have evidence.


## SH-006 — export privacy regression coverage (2026-10-29)

- [x] Extend the reader/repository regression source to assert CSV and selected-Markdown output includes the explicit saved quote but excludes the complete temporary article text.
- [ ] Run the export/privacy regression at the manual validation checkpoint; tests remain unexecuted.
- [ ] Verify actual share-sheet behavior and platform/accessibility behavior before closing SH-006.


## SH-006 — legacy charset alias regression (2026-10-29)

- [x] Add source coverage for the cp1252 alias and ensure the Latin-1 decoder remains separate from Windows-1252 mapping.
- [ ] Execute TC-269 and the full reader test set at the owner-approved manual validation checkpoint.


## SH-006 — reader accessibility source (2026-10-29)

- [x] Add explicit semantic labels for loading and save progress and heading semantics for the article and error-state titles.
- [x] Author a widget regression for the loading progress label using a pending synthetic response.
- [ ] Execute the widget regression and inspect selection, navigation, errors and saving with Android/web assistive technology; source labels alone do not establish accessibility completion.


## SH-006 — save-progress accessibility regression (2026-10-29)

- [x] Author a delayed-save widget test for the “Saving highlight” semantic label and eventual success feedback.
- [ ] Run both Reader accessibility widget cases and perform Android/web assistive-technology checks; all remain unverified.


## SH-006 — HTML entity parsing edge cases (2026-10-29)

- [x] Decode a conservative set of common named text entities used for typography, currency and symbols.
- [x] Decode numeric references before named references so escaped ampersands are not recursively decoded in the same pass.
- [x] Add synthetic regression coverage for named entities, case-insensitive names, hexadecimal numeric references and single-pass escaping.
- [ ] Execute sanitizer/reader tests and confirm rendering output on Android/web; source and test are not verified.


## SH-006 — semantic container extraction order (2026-10-29)

- [x] Remove script/style/noscript/SVG/iframe/object/template blocks and HTML comments before locating semantic article/main containers.
- [x] Author a regression for fake article tags in script strings/comments alongside a real article and navigation content.
- [ ] Run the sanitizer regression matrix and inspect native/web behavior at the owner-approved checkpoint. The lightweight regex sanitizer is still not a complete HTML parser.


## SH-006 — source integrity, extraction order and text controls (2026-10-29)

- [x] Remove a duplicated malformed tail from the reader service and confirm each core URL/sanitizer/loader declaration occurs once in the committed file.
- [x] Strip embedded active content and navigation chrome before article/main extraction, so fake article-shaped markup cannot shadow the actual article.
- [x] Replace non-printing control bytes during plain-text normalization without altering Urdu/other ordinary Unicode text.
- [x] Add synthetic cases for fake article tags inside script/comment/navigation content and control-character cleanup.
- [ ] Run the reader regression suite and current Flutter checks at the owner's manual validation checkpoint; no tests have been run for these changes.


## SH-006 — embedded page-title safety (2026-10-29)

- [x] Strip script/style/embedded blocks and comments before extracting a page title.
- [x] Add a synthetic regression for fake `<title>` elements inside a script string and HTML comment, plus a real entity-encoded document title.
- [ ] Execute title/reader tests and verify native and browser behavior at the owner's manual validation checkpoint; source/test remain unverified.


## SH-006 — UTF-8 BOM handling (2026-10-29)

- [x] Strip the leading UTF-8 byte-order mark from native decoded response text.
- [x] Add TC-270 source coverage verifying the BOM is absent from the first visible character.
- [ ] Run the reader regression suite at the owner-approved manual validation checkpoint; source and test have not been executed.


## SH-006 — Unicode-safe Reader truncation (2026-10-29)

- [x] Ensure the body and extracted-title display caps do not end between the high and low surrogates of a supplementary Unicode character.
- [x] Add TC-271 source coverage placing an emoji across the body text limit.
- [ ] Run the Reader regression suite at the owner-approved manual validation checkpoint; source and test have not been executed.


## SH-006 — title truncation regression — TC-272 (2026-10-29)

- [x] Add a regression case placing a supplementary Unicode character across the 300-code-unit title cap.
- [ ] Execute TC-271, TC-272 and the full Reader regression suite at the owner-approved manual validation checkpoint.


## SH-006 — bounded HTML meta charset fallback (2026-10-29)

- [x] Use the response-header charset first; if absent for HTML, inspect at most the first 1,024 bytes for a direct meta charset or legacy http-equiv/content declaration.
- [x] Add TC-273 and TC-274 regression source for a Windows-1252 euro byte decoded via both HTML declaration forms.
- [ ] Run the Reader charset and complete regression suites at the owner-approved manual validation checkpoint; tests remain unexecuted.


## SH-006 — ignore embedded fake charset declarations — TC-275 (2026-10-29)

- [x] Remove HTML comments and script/style/noscript blocks from the bounded meta charset scan before extracting encoding hints.
- [x] Add TC-275 regression source with fake charset tags in comment/script content.
- [ ] Run TC-273–TC-277 and the complete Reader regression suite at the owner-approved manual validation checkpoint; tests remain unexecuted.


## SH-006 — protect HTTP charset precedence — TC-276 (2026-10-30)

- [x] Add a synthetic response regression where HTTP declares Windows-1252 but the HTML meta tag claims UTF-8; verify the header's euro-byte decoding wins.
- [ ] Run TC-273–TC-276 and the complete Reader regression suite at the owner-approved manual validation checkpoint; tests remain unexecuted.


## SH-006 — enforce the 1,024-byte charset prescan boundary — TC-277 (2026-10-30)

- [x] Add a synthetic response regression with a Windows-1252 meta declaration positioned after byte 1,024; verify the declaration is ignored and UTF-8 fallback remains active.
- [ ] Run TC-273–TC-277 and the complete Reader regression suite at the owner-approved manual validation checkpoint; tests remain unexecuted.


## SH-006 — parse only actual meta charset attributes — TC-278/TC-279 (2026-10-30)

- [x] Parse meta tag attributes rather than searching the entire tag text for \`charset=\`.
- [x] Accept a direct \`charset\` attribute, or a legacy charset only when \`http-equiv=Content-Type\` and the \`content\` attribute declares it.
- [x] Add TC-278 for charset-like description/keyword text and TC-279 for a real charset following unrelated metadata.
- [ ] Run TC-273–TC-279 and the complete Reader regression suite at the owner-approved manual validation checkpoint; tests remain unexecuted.


## SH-006 — Unicode-safe quote selection and context capture — TC-280–TC-282 (2026-10-30)

- [x] Normalize selection start/end boundaries outward when they fall inside a UTF-16 surrogate pair; keep stored offsets aligned with the captured quote.
- [x] Keep the bounded before/after context windows from starting or ending inside a supplementary Unicode character.
- [x] Reject collapsed and out-of-range selection offsets before creating a quote payload.
- [x] Add TC-280–TC-282 source coverage.
- [ ] Run TC-280–TC-282 and the full Reader regression suite at the owner-approved manual validation checkpoint; tests remain unexecuted.


## SH-006 — conservative saved-quote re-anchoring — TC-283–TC-287 (2026-10-30)

- [x] Find exact saved-quote occurrences in the newly fetched temporary article; never treat old offsets as current evidence.
- [x] Rank repeated occurrences by contiguous suffix/prefix agreement with the saved before/after context.
- [x] Return a suggestion only for a unique quote or a uniquely strongest contextual match with at least 12 exact context code units; tied/weak matches remain ambiguous.
- [x] Reject quotes shorter than 8 characters, oversized article text and invalid/oversized context; expose at most 8 ranked candidates.
- [x] Add Item Details' **Find in latest article** action and show a temporary highlighted suggestion in Reader.
- [x] Require the user's explicit **Update saved position** action before persisting refreshed offsets/context; preserve annotation ID, quote, note and creation time.
- [x] Add TC-283–TC-287 unit, widget and repository regression source.
- [ ] Execute re-anchoring, full Reader, backup/export and platform tests at the owner-approved manual validation checkpoint. Matching is exact-text only; edited/translated/reformatted quotes may not be found and are never fuzzy-guessed.


### SH-006 — re-anchoring input and persistence safety follow-up — TC-286–TC-288 (2026-10-30)

- [x] Add a repository/widget regression proving that opening the locate-quote preview does not mutate the saved annotation before explicit confirmation.
- [x] Reject malformed UTF-16 quote/context values from legacy annotation data before matching.
- [x] Verify the matcher exposes no more than eight candidate positions even when the exact quote occurs many times.
- [x] Carry the expected quote into the persistence boundary and reject a stale Reader suggestion if the saved quote changed before confirmation.
- [x] Show a compact excerpt with before/after context above the full article so the proposed occurrence can be reviewed before confirmation.
- [ ] Run TC-283–TC-288 and the full Reader/repository/export regression suite at the manual validation checkpoint.


### SH-006 — re-anchor backup/export compatibility — TC-289 (2026-10-30)

- [x] Extend the repository re-anchor flow regression to round-trip updated annotation offsets and context through the versioned JSON backup.
- [x] Confirm CSV/Markdown retain the user-saved quote and note but omit unrelated fetched article paragraphs; saved item title/content/URL remain unchanged.
- [ ] Run TC-283–TC-289 plus backup, CSV, Markdown and Reader suites at the manual validation checkpoint.
