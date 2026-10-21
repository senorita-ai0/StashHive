# ADR-001: Proposed platform scope

- **Status:** Proposed; approval pending
- **Date:** 2026-10-21

## Context

The project needs a low-cost public-facing personal library and the user already develops Flutter apps. Android supports useful share/import behavior, while web offers low-cost distribution but has different storage/filesystem constraints.

## Options

1. Android only.
2. Android first, plus Flutter web companion.
3. Android, iOS, web, and desktop all as first-release targets.

## Proposed decision

Option 2: Android is the primary MVP target; Flutter web is a companion release only after a browser persistence and backup proof of concept. iOS/desktop are deferred.

## Rationale and trade-offs

- One Flutter/Dart domain/UI codebase limits duplicated work.
- Android enables a direct share target for supported URLs/text/images/files.
- Web can distribute without requiring a Play Store listing, but browser storage is tied to the origin/profile and can be cleared; cross-device sync is not implied.
- Full platform parity would broaden testing and storage scope before the product is validated.

## Revisit when

The browser persistence/restore spike fails or Android sharing requires disproportionate native work; then reconsider Android-only MVP.
