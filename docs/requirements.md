# StashHive — Requirements and Acceptance Criteria

**Status:** Approved for source implementation on 21 October 2026; platform feasibility and acceptance verification remain pending.  
**Priorities:** Must = essential to the proposed MVP; Should = high value if the proof of concept supports it; Could = later; Won't = explicitly excluded from MVP.

## Product identity and compatibility

The visible product name is StashHive. Keep the existing `stashhive` package/storage identifiers and version-1 backup marker stable. Older StashTrail backups must remain importable.

## Actors and terminology

- **User:** one person managing their own library. No admin or social roles are required.
- **Saved item:** a record of something the user wants to find later.
- **Bookmark/link:** a URL plus locally saved metadata; not the same as an offline webpage.
- **Attachment:** a copy of an image/document stored by StashHive or a user-selected file reference. Availability differs by platform and import choice.
- **Extracted text:** text extracted on-device from an image/PDF when a validated processor is available. It is optional metadata, not a replacement for the original file.
- **Collection:** a user-created grouping of items. **Tag:** a searchable label. An item may have multiple tags and optionally a collection.

## Functional requirements

| ID | Requirement | Priority | Acceptance criteria | Dependencies / test |
|---|---|---|---|---|
| FR-001 | Support typed saved items: link, image, text/note, and document/PDF. Video and social content are initially stored as links unless an actual supported file is imported. | Must | Given each supported item type, when saved, then it appears with a clear type label and opens through the appropriate action. | Data model; TC-001 |
| FR-002 | Manually create and edit an item with title, notes/text, URL when relevant, tags, collection, favorite, and timestamps. | Must | Required fields are validated; edits persist after restart; invalid URLs do not crash the app. | UI/forms and repository; TC-002 |
| FR-003 | Delete one item and make the effect on attached copied files clear. | Must | User sees a clear action; cancel keeps the item; confirm removes the record and applies the documented attachment cleanup rule. | Repository + file lifecycle; TC-003 |
| FR-004 | Browse a unified library with search entry point, item-type filter, sort order, and favorites filter. | Must | Results match selected filters; empty/loading/error states are understandable. | Screen specs; TC-004 |
| FR-005 | Search saved metadata: title, URL, user notes/text, and tags; search is case-insensitive where applicable and preserves Unicode text. | Must | A saved unique term can find the correct item; clearing the query restores normal library results; non-Latin user-entered text is not corrupted. | Search/index; TC-005 |
| FR-006 | Add links manually and open them externally. | Must | Valid links are saved without requiring page scraping; tapping opens the correct destination when a handler is available, otherwise displays a recoverable error. | URL validation/opening; TC-006 |
| FR-007 | Save text snippets and personal notes without a URL or attachment. | Must | A user can save, edit, search, and delete a note offline. | Note UI/storage; TC-007 |
| FR-008 | Import user-selected images and documents using platform-appropriate selection/share mechanisms. | Must for manual picker; Should for Android share intake until spike passes | Import copies data when appropriate or clearly records a reference; cancelling picker does not create a ghost item; unsupported/oversized files show an explanation. | Storage/import proof of concept; TC-008 |
| FR-009 | Receive shared URLs/text/images/files from Android apps. | Should pending technical validation | When a supported item is shared to StashHive, the app shows a confirmation/edit step and saves once; unsupported MIME types fail safely. | Android intent/share spike; TC-009 |
| FR-010 | Add and remove tags, create/rename/delete collections, and assign an item to a collection. | Must | Renaming/deleting a collection follows the documented rule; deleting a collection does not silently delete its items. | Data relationships; TC-010 |
| FR-011 | Show a detail view with source URL, note, file/type information, tags, saved time, and available actions. | Must | Bookmark vs copied file vs cached preview/offline snapshot is explicitly distinguished. | Detail design; TC-011 |
| FR-012 | Export the library and its copied attachments into a portable, versioned backup chosen by the user. | Must before release | Export completes with a summary; the archive has a manifest and schema version; failure/cancellation does not damage the live library. | Backup format; TC-012 |
| FR-013 | Restore a backup after validating its format and version. | Must before release | Valid backup imports with reported counts; invalid/corrupt archives are rejected without corrupting existing data; conflict policy is documented and user-visible. | Backup parser; TC-013 |
| FR-014 | Work offline for local library browsing, notes, metadata search, editing, and backups once required files are available locally. | Must | With network disconnected, local functions still work; opening an online URL clearly requires a network. | Storage, integration tests; TC-014 |
| FR-015 | Provide a browser version with local persistence and explicit browser data limitations. | Should until POC confirms storage and export | Reloading the page retains data in the same supported browser profile; the UI explains that browser/site-data clearing and using another browser/device can lose/access a different library. | Flutter web + IndexedDB/browser storage spike; TC-015 |
| FR-016 | Extract local text from supported images/screenshots and PDFs for additional search. | Should, gated on a successful offline/size/language proof of concept | When extraction is available, search finds a test phrase and indicates unavailable/failed extraction without pretending it succeeded. Unsupported languages are documented. | OCR/text extraction spike; TC-016 |
| FR-017 | Avoid automatic scraping or full offline website capture in the MVP. | Won't | Saving a URL never implies that site content was downloaded; any later preview is explicitly opt-in and separately represented. | Product copy review; TC-017 |
| FR-018 | Provide clear privacy information, backup/restore access, and safe handling of saved data. | Must | No sign-in is required; the product does not send saved content to a remote service; deletion and backup flows explain effects. | Privacy review; TC-018 |
| FR-019 | Prevent duplicate imports from accidental repeated taps when a reliable content fingerprint can be computed. | Could | If implemented, duplicates are identified for review; no item is silently discarded. | Hashing and UX; TC-019 |
| FR-020 | Support reminders for saved items. | Won't for MVP | No reminder or notification is scheduled in MVP. | Later backlog |
| FR-021 | Keep user library private; no public feed, collaboration, or shared collections. | Won't for MVP | No content is publicly accessible or remotely synchronized. | Architecture / privacy review |
| FR-022 | Compose advanced local search filters and save reusable named search presets. | Should | Type, text query, tag, collection, domain, favorite state, saved-date range and sort combine predictably. Up to 20 locally stored presets can be created, replaced by case-insensitive name, applied and deleted. Invalid stored presets are ignored safely. Presets remain in the current app/browser profile and are not included in backup v1. | SH-002; TC-247–TC-249 |

## Non-functional requirements

| ID | Requirement | Priority | Acceptance criteria / verification |
|---|---|---|---|
| NFR-001 | No required hosted backend, account, or paid AI service for core use. | Must | Core demo works in airplane mode after installation, apart from opening external URLs. Network inspection confirms no library content is transmitted by core flows. |
| NFR-002 | Data minimization and safe defaults. | Must | Request only permissions needed for selected import/share flows; no contacts/location permission; saved content is not emitted in logs/analytics. |
| NFR-003 | Persistence and recoverability. | Must | Restart persistence, export, restore, corrupted-backup rejection, and app/browser data-loss messaging pass tests on target platforms. |
| NFR-004 | Platform honesty. | Must | App UI and docs do not claim cross-device sync, offline website viewing, or universal OCR unless demonstrated. |
| NFR-005 | Unicode-safe storage/search. | Must | Tests cover English, Urdu-script sample input, Roman Urdu, emoji, accents, and punctuation; OCR accuracy is tested separately. |
| NFR-006 | Usable responsive interface and accessibility. | Must | Layouts tested at narrow mobile and desktop browser widths; semantic labels, contrast, large text, keyboard focus on web, and touch targets reviewed. Target WCAG 2.2 AA for web as the design goal, subject to manual review. |
| NFR-007 | Performance. | Must | Prototype benchmarks are recorded for realistic library sizes (100, 1,000, 10,000 metadata-only items); agreed release targets are set after baseline measurements. No arbitrary latency guarantee is claimed in this draft. |
| NFR-008 | App size / memory. | Must | Baseline package size and memory use are measured before and after any OCR dependency; high-cost libraries require explicit acceptance. |
| NFR-009 | Maintainability. | Must | Domain logic separated from platform I/O; dependencies and tested versions documented; tests run reproducibly. |
| NFR-010 | Licensing and ownership. | Must | Each adopted dependency's license and maintenance status are checked; app license remains undecided until the owner chooses it. |

## Explicit MVP exclusions

- Authentication, cloud sync, remote database, public sharing, community/feed.
- Automatic full webpage archiving, scraping, or unrestricted background downloads.
- AI summaries, vector/semantic search, paid model calls, or a hosted OCR API.
- Promised Urdu/Nastaleeq OCR before a demonstrated proof of concept.
- Browser extension and iOS/desktop feature parity before separate validation.
- Ads, subscriptions, billing, and store release implementation before usability validation and a separate release/monetization approval.

## Approval note

These requirements were approved for source implementation on 21 October 2026. Treat them as the current MVP acceptance criteria while the implementation is in progress. Platform feasibility and acceptance verification remain pending; material scope or acceptance changes still require the owner's agreement.
