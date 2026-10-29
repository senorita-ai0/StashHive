# SH-006 — User-initiated article reader design gate

**Status:** Initial reader and selection-source implementation committed; tests and platform behavior remain unverified.  
**Date:** 2026-10-29

## Scope for the next implementation slice

Build an optional, explicit **Open in StashHive reader** action for saved HTTP(S) links. It must not run automatically during save, background refresh, or search. Opening a URL in the reader is a distinct user action and must be labeled as network access.

### Privacy and safety boundaries

- Keep the original saved bookmark and its metadata unchanged when opening reader mode.
- Do not fetch page content during Quick Save, background work, or while the app is idle.
- Only accept credential-free HTTP(S) URLs on standard ports (HTTP 80, HTTPS 443). Reject local/private/reserved destinations; validate DNS resolution and refuse redirects before native fetch to reduce SSRF/DNS-rebinding risk. Non-standard ports remain available through the user's explicit external-browser action.
- Bound request time, response bytes, redirect count, parsing work, and displayed text. Handle timeouts, unsupported content types, malformed HTML, and unavailable connectivity with recoverable UI.
- Do not send cookies, app credentials, or saved-item notes to the site. Do not log full URLs, response bodies, selected text, or personal annotations.
- Reader content is a **temporary fetched preview**, not an offline archive. Do not persist fetched HTML/text in the library or imply that it will be available offline.
- Keep the existing external-browser action available. Never silently open a link or fetch content.
- Treat page content as untrusted data: render plain readable text and safe links, not arbitrary scripts, embedded frames, or executable HTML.

### Selection/highlight decision

Selection-based quote capture is now prototyped in source using selectable sanitized reader text and an explicit Save highlight action. It stores the quote, bounded surrounding context and UTF-16 offsets in the existing annotation record. Do not promise stable re-anchoring until selection behavior is verified on Android and web. Since page content changes, show saved quotes as personal excerpts and do not claim a highlight will always re-anchor exactly.

### Implementation sequence

1. Inspect existing annotation model, repository APIs, item detail UI and tests; reuse current persistence/export paths.
2. Add a reader state model and parser boundary with explicit limits and injectable transport/parser for deterministic tests.
3. Add an explicit Item Details action and loading/success/empty/unsupported/offline/error states.
4. Add tests for URL validation, redirect/private-target rejection, content-type and byte limits, hostile HTML, timeouts, no persistence of fetched page content, and unchanged bookmark metadata.
5. Prototype text selection separately on Android and web. Only then choose a cross-platform selection implementation and add offset/context regression tests.
6. Update status/backlog/progress/roadmap/test plan/traceability after each implementation slice.

## Not in this slice

- Background scraping or link previews during save.
- Permanent/offline website snapshots.
- Browser extension, cloud proxy, paid API, or account.
- Script execution, arbitrary page JavaScript, or automatic media downloads.
- OCR/PDF extraction; SH-005 remains independently gated.

## Exit criteria

- Reader is only invoked by an explicit user action and the network behavior is clearly disclosed.
- Request and parsing resource limits are tested.
- Existing bookmark, annotation, backup and search behavior remains intact.
- Android and web behavior is demonstrated separately; browser CORS limitations are explained rather than bypassed through a hosted proxy.
- No tests/builds are marked passed until actually executed at the owner-approved manual validation checkpoint.

## Source hardening update — 2026-10-29

The initial native transport now separates response handling behind a test-only resolver/transport boundary. Production defaults remain OS DNS plus direct connections to vetted/pinned IPv4 destinations; no proxy or third-party service is introduced. A single absolute deadline spans the native request flow. Tests can use synthetic response bodies/statuses and fake DNS answers, avoiding real internet traffic. Source and regression coverage are authored only; no test/build/analysis has been run, and this does not replace Android/web platform checks.
