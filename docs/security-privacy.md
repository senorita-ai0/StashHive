# StashHive — Security and Privacy Plan

**Status:** Design plan only, not a claim of audited security or legal compliance.

## Privacy promises proposed for MVP

- No account is required for local library use.
- The core library stays on the device/browser; saved items are not uploaded to StashHive servers because no such service is planned for the MVP.
- No saved URLs, titles, notes, filenames, image text, or document text are written to diagnostic logs or analytics.
- Only request the platform access necessary for a user-selected import/share action; no location or contacts permission.
- Opening a link sends the user to an external website. That website has its own privacy/network behavior; StashHive does not promise the destination itself is private.
- Local storage can be lost if the app is uninstalled or browser/site data is cleared. Export/restore is the planned portability mechanism.

## Threats and protections

| Threat | Design protection | Verification |
|---|---|---|
| Malformed/deceptive URL | Allow only suitable schemes for open (initially `http`/`https`); show domain; do not auto-fetch. | URL validation tests. |
| Malicious or mislabeled attachment | Restrict supported types/size, validate where possible, never execute files, handle parser failure. | Unsupported/MIME/size tests. |
| Malicious backup ZIP | Validate paths against traversal, file count/size, manifest version, IDs, checksums; stage before writing live state. | Corrupted/path-traversal archive cases. |
| Accidental attachment deletion | Document ownership/copy/reference state; transactional or recoverable delete and export. | Delete cancellation and restore tests. |
| Browser storage cleared/quota exceeded | Warn about per-browser persistence, show storage errors, provide export/restore. | Web reload, quota/error simulation, manual data-clear test. |
| Sensitive content exposed by logs/analytics | No content logging; no analytics SDK in MVP. | Inspect logs and network on core journeys. |
| Unnecessary permissions | Prefer user-selected file/share mechanisms and private app storage. | Manifest/permission review on each release. |
| Dependency supply-chain or license issue | Track direct dependencies, versions, licenses, maintenance and security advisories before adoption. | Dependency review at package selection and upgrades. |

## Data lifecycle rules to design

- User chooses when export occurs and where it is saved.
- Export manifest names format/schema version and identifies included file types/counts; it must not include secrets.
- Restore validates before modifying the current library; unknown format versions fail safely.
- User can delete an item and understand whether a copied attachment is removed; do not delete an original file the app does not own.
- Thumbnails and extracted text are derived data and can be recreated/cleared. They must not become the only copy of a user attachment.
- No remote OCR, cloud sync, analytics, ad SDK, or automatic page fetching in the core MVP. Any later introduction requires a distinct privacy review and explicit approval.

## Incident/reporting

If the project becomes public, add a monitored security contact before release. Until an official contact and disclosure process exist, do not invent an email address or claim a formal security response service.


## Phase 1 implementation details — verification pending

- Import source: user-selected images and supported document extensions; 15 MB per-file cap in the initial UI.
- Backup v1: JSON with base64 attachment content, maximum 15 MB per file and 100 MB combined attachment bytes; decode validates app marker/version, record count, IDs, URL schemes, text/tag bounds and attachment references before writing.
- Restore uses merge semantics rather than replacing the user's current library. ID collisions are remapped, and the repository attempts to roll back records written during an exception.
- These safeguards are authored but not security-audited or test-proven until CI and manual malformed-file tests pass.


## Phase 1 implementation notes — verification pending

- Manual user-selected files only; 15 MB per-file cap in the initial UI.
- Backup v1 validates app/version marker, record count, record IDs, URL schemes, text/tag bounds, attachment encodings and missing references before import; 15 MB per file and 100 MB combined attachment bytes.
- Restore uses merge semantics; colliding IDs are remapped, and code attempts to roll back newly written records after a storage exception.
- These safeguards are authored but not security-audited or test-proven until CI and malformed-file/interrupt tests pass.


## Share-event replay handling — verification pending

- Android share intake suppresses matching initial-intent/stream deliveries for a short three-second window, using a bounded in-memory cache. The same URL can be shared again after the window.
- This avoids permanent suppression of repeated URLs. Tests are authored but not run for the current Phase 2 changes.


## Backup validation refinement — source added, verification pending

- Restore now checks required saved-item field types before constructing models, requires a collections list, bounds and validates collection names, validates attachment key/name/MIME metadata, and rejects attachment payloads that no item references.
- Backup creation includes collection names referenced by saved items even if an older or inconsistent local collection list omitted them, so a round-trip does not silently strand those items outside the Collections screen.
- Repository restore validates the complete decoded backup before beginning writes. This reduces malformed-input partial import risk; it does not yet prove recovery from a disk/box write failure during the write phase.


## Restore rollback hardening — source added, verification pending

- Restore reserves both item-box and attachment-box keys, including orphaned keys and keys tied to unreadable records, before choosing imported IDs.
- If a restore fails after writes begin, cleanup is attempted for every staged item and attachment, then the prior collection preference value is restored (or the preference key is removed if it did not previously exist). A rollback failure does not mask the original restore exception.
- This is best-effort rollback, not an atomic database transaction. Power loss, process death and physical storage failure during rollback remain unverified.


## Attachment edit failure handling — source added, verification pending

- Before replacing attachment bytes, save captures the prior raw attachment-box value. If the item record cannot commit, it tries to restore that value; for a new attachment with no prior value, it removes the staged bytes.
- Cleanup failures do not mask the original item-save exception. This is best-effort in-process rollback, not an atomic transaction against power loss or storage failure.


## Phase 3 UI error handling increment — 2026-10-22

Normal file selection, save, item/collection deletion and backup operation error messages preserve app-defined validation guidance but do not display raw unexpected plugin/storage exceptions. Startup failure copy now hides the raw initialization exception (which can include local paths) and provides browser- or device-specific recovery guidance. Regression source checks item/collection deletion fallbacks and startup copy. This is a source-level improvement only: platform-owned messages, logs, permissions and network behavior still require the manual privacy review; no audit or test pass is claimed.


## Phase 3 code-level privacy review — 2026-10-29

**Scope:** source inspection only; this is not a platform security audit or evidence of successful builds.

- Inspected the Dart sources for direct diagnostic logging calls such as `print`, `debugPrint`, `developer.log` and common logger calls. No matches were found in the current `lib/` source files reviewed.
- Item link opening validates persisted links with the HTTP/HTTPS-only parser immediately before calling the external launcher, so legacy unsafe schemes are rejected even if they predate current save/restore validation.
- Shared content and attachment intake apply explicit limits to text, URLs, provider paths, MIME metadata, batch size, waiting share batches and attachment bytes before or during the corresponding allocations/read operations.
- The Android manifest is generated during the manual workflow rather than checked into the repository. The custom configurator adds share intent filters and the app label/launch mode; it does not add permission declarations. The generated manifest and resolved plugin permission footprint still require review from an actual build.
- No remote OCR, account system, analytics or cloud-sync service is implemented in this MVP source.

### Manual link health checks

- Status checks require a direct user action and contact the destination from the user's own device; the destination may see the user's network address.
- The checker does not send notes, tags, attachment bytes, cookies or account credentials, and does not read/store page bodies. Link results are bounded, local-only preference metadata and are excluded from backup v1.
- Native checks reject private/local/reserved resolved addresses, pin the connection to the prevalidated DNS address to reduce DNS-rebinding exposure, force a direct connection, and do not follow redirects. They issue HEAD only and report method refusal rather than falling back to GET. Browser builds report that reliable external status inspection is limited by browser security; no remote proxy is used.
- A timeout, access restriction, server error or redirect is not treated as proof of permanent link failure. This feature does not run in the background.

**Remaining verification before this review can close:** inspect the generated merged Android manifest and resolved dependency permissions; capture browser/Android network behavior; perform real-device file/share, TalkBack and browser screen-reader checks; rerun the source/tests and manual platform builds at the owner's checkpoint. The review remains open until those checks have evidence.
