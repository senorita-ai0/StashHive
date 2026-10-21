# StashHive — Assumptions and Open Decisions

Review this file whenever product scope changes. Confidence reflects how strongly the assumption is supported today, not whether it has been implemented.

| ID | Assumption / decision | Confidence | Impact if wrong | Validation / owner | Status |
|---|---|---|---|---|---|
| ASM-001 | Android is the primary first platform; web is a companion. | Medium | High | Confirm blueprint; validate Android share and web data storage. Product owner | OPEN |
| ASM-002 | The core should work without login, backend, or paid AI API. | High | High | Confirm blueprint; network inspection after prototype. Product owner / developer | PROPOSED |
| ASM-003 | A Flutter codebase is preferred. | High | Medium | Use current Flutter environment after approval; test web and Android builds. Developer | PROPOSED |
| ASM-004 | User-selected attachments should be copied into app-managed storage when appropriate. | Medium | High | Test large imports, deletion, restart, backups and uninstall messaging. Developer | OPEN |
| ASM-005 | Web data is stored per browser/origin and is not automatically synchronized to Android. | High | High | Validate IndexedDB/browser persistence and export/import. Developer | PROPOSED |
| ASM-006 | Metadata search is the minimum dependable search; OCR/PDF text extraction is a staged enhancement. | High | High | Run OCR/size/latency/language POC before promoting OCR to MVP Must. Developer | OPEN |
| ASM-007 | Urdu and Roman Urdu text may be entered, saved, and searched as user-provided text, but OCR for Urdu/Nastaleeq is not promised. | High | Medium | Unicode tests; OCR language-quality benchmark. Developer | PROPOSED |
| ASM-008 | Video and social media content can be represented as URLs for MVP; downloading media is out of scope. | High | Medium | Test provider URLs can be stored/opened without scraping. Product owner | PROPOSED |
| ASM-009 | Saving a link does not automatically download the whole website. | High | High | UX copy, test, and user comprehension check. Product owner / QA | PROPOSED |
| ASM-010 | User-controlled export/restore is required because local data can be lost. | High | High | Validate cross-platform archive and failure recovery. Developer / QA | PROPOSED |
| ASM-011 | First release may be English UI with Unicode-safe user data. | Medium | Medium | Confirm language priority; verify RTL/locale if Urdu UI is added later. Product owner | OPEN |
| ASM-012 | Monetization can wait until first-run save/search and retention are validated. | High | Medium | Conduct opt-in tests; add ads or one-time unlock only after separate decision. Product owner | PROPOSED |
| ASM-013 | A single metadata store can serve Android and web. Hive CE is a leading candidate, not yet selected. | Medium | High | POC with records, tags/collections, migration, export, web persistence and 10k search benchmark. Developer | OPEN |
| ASM-014 | App package/domain/trademark availability for StashHive is not legally verified. | High | Medium | Check official stores, registrar, and relevant trademark database before public release. Owner | OPEN |
| ASM-015 | No license has been chosen for the repository. | High | Medium | Owner decides before public release/open-source distribution. Owner | OPEN |

## Blocking decisions before build approval

1. Approve Android-first + companion-web scope, with no promised sync.
2. Approve the MVP feature boundaries and staged OCR approach.
3. Confirm backup/restore as a release requirement.

Database package, target Android API, exact Flutter/package versions, extraction library, application ID, license, and monetization provider should be decided after targeted validation; they do not all need to be decided during blueprint review.
