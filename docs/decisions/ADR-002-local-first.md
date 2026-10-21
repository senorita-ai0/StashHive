# ADR-002: Local-first core with user-controlled backup

- **Status:** Proposed; approval pending
- **Date:** 2026-10-21

## Context

Budget is effectively zero, saved content can be private, and the app is intended for individual users rather than a provider/customer marketplace. A hosted backend, auth, and cloud storage would add cost, privacy risk, and ongoing maintenance.

## Options

1. Cloud-first library with sign-in and sync.
2. Local-first library plus user-controlled export/restore.
3. Hybrid sync service from the first release.

## Proposed decision

Option 2. Core use should need no account/backend; users can export a portable versioned backup and import it on another device manually.

## Trade-offs

Users do not get automatic sync or shared libraries. App-private Android files can be removed on uninstall and browser storage may be cleared. Make those limits clear and ensure backup/restore is reliable before release.

## Revisit when

User validation shows multi-device sync is essential and a sustainable free/paid service model plus privacy design is explicitly approved.
