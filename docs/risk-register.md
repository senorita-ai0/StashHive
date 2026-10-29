# StashHive — Risk Register

Scale: Probability and impact are Low / Medium / High qualitative estimates. Review before each milestone.

| ID | Risk | Probability | Impact | Mitigation / next action | Trigger / status |
|---|---|---|---|---|---|
| RSK-001 | OCR library/model increases APK size, memory, battery use, or latency. | High | High | Keep OCR optional; test several local sample files and capture package-size delta before choosing a dependency. | Before TSK-005 decision; OPEN |
| RSK-002 | Urdu/Nastaleeq OCR is inaccurate or unavailable offline. | High | Medium | Acknowledge that Tesseract Urdu data exists but accuracy is unproven; benchmark labelled Urdu/Nastaleeq samples separately and distinguish manually entered Urdu search from OCR. See `docs/research/local-text-extraction-feasibility.md`. | Runtime sample test required before any OCR requirement promotion; OPEN |
| RSK-003 | Browser storage is cleared or quota limits attachments. | Medium | High | Versioned export/restore, quota/error messaging, avoid claiming durable file-system access or sync. | Web POC and release review; OPEN |
| RSK-004 | App uninstall removes app-private files and library unless exported. | Medium | High | First-run data ownership message, backup reminder, restore tests; explain behavior. | Before release; OPEN |
| RSK-005 | Android share intents vary by source app and MIME type. | Medium | High | Narrow allowlist, real-device proof of concept, recoverable unsupported-content handling. | TSK-004; OPEN |
| RSK-006 | Cross-platform storage choice creates separate code paths or weak querying. | Medium | High | Repository abstraction and spike on Android + web before committing. | TSK-003; OPEN |
| RSK-007 | Product becomes feature-heavy and hard to navigate. | Medium | Medium | Save/find core loop first; keep cloud, social, full webpage archive and AI out of MVP. | Every scope review; OPEN |
| RSK-008 | Existing save-it-later/screenshot apps make discovery difficult. | High | High | Identify a specific user pain; validate reviews and test user tasks before development/release. | Before monetization/launch; OPEN |
| RSK-009 | Backup restore corrupts items or trusts malicious archive paths. | Medium | High | Versioned manifest, path/size/hash validation, staging import and failure tests. | TSK-006, TSK-302; OPEN |
| RSK-010 | Future ads or analytics undermine privacy or clutter the interface. | Medium | Medium | No monetization SDK in initial core; later separate consent, policy, placement and privacy review. | M4; OPEN |
| RSK-011 | App name, domain, store listing or trademark conflicts. | Medium | Medium | Verify relevant official sources before public branding; current name is not legally cleared. | Before TSK-403; OPEN |
| RSK-012 | Local development/CI or publishing costs are assumed to be zero despite account/store requirements. | Medium | Medium | Keep core runtime free; document optional hosting/store/ads account constraints before release. | Release planning; OPEN |
| RSK-013 | Imported files have misleading extensions, unsupported formats, or excessive size. | Medium | High | Validate content types where feasible, cap sizes, handle errors, do not execute imported files. | TSK-105, tests; OPEN |
| RSK-014 | Saved content accidentally appears in logs or network requests. | Low–Medium | High | Explicit no-content logging rule, inspect logs/network in TC-018, no analytics in initial core. | Every release; OPEN |
