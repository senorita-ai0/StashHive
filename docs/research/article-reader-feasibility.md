# SH-006 — User-initiated article reader design gate

**Status:** Design decision recorded; implementation not started and no tests run.  
**Date:** 2026-10-29

## Scope for the next implementation slice

Build an optional, explicit **Open in StashHive reader** action for saved HTTP(S) links. It must not run automatically during save, background refresh, or search. Opening a URL in the reader is a distinct user action and must be labeled as network access.

### Privacy and safety boundaries

- Keep the original saved bookmark and its metadata unchanged when opening reader mode.
- Do not fetch page content during Quick Save, background work, or while the app is idle.
- Only accept valid HTTP(S) URLs. Reject credentials embedded in URLs and local/private/reserved destinations; validate DNS resolution and redirects before any native fetch to reduce SSRF/DNS-rebinding risk.
- Bound request time, response bytes, redirect count, parsing work, and displayed text. Handle timeouts, unsupported content types, malformed HTML, and unavailable connectivity with recoverable UI.
- Do not send cookies, app credentials, or saved-item notes to the site. Do not log full URLs, response bodies, selected text, or personal annotations.
- Reader content is a **temporary fetched preview**, not an offline archive. Do not persist fetched HTML/text in the library or imply that it will be available offline.
- Keep the existing external-browser action available. Never silently open a link or fetch content.
- Treat page content as untrusted data: render plain readable text and safe links, not arbitrary scripts, embedded frames, or executable HTML.

### Selection/highlight decision

Do not promise native text selection and highlight anchoring until the rendering approach is proven on Android and web. For the first slice, reuse the existing manual quote/note annotation model. Then prototype selection from the sanitized reader text and store a bounded quote plus surrounding context/offset metadata, tied to the saved item ID. Since page content changes, show saved quotes as personal excerpts and do not claim a highlight will always re-anchor exactly.

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
