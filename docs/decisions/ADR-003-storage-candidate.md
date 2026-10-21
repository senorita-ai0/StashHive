# ADR-003: Cross-platform local metadata store

- **Status:** Open — no package selected
- **Date:** 2026-10-21

## Context

Metadata must persist locally in Android and browser builds, support tags/collections/filters, and export/restore. Attachment bytes may use different platform storage adapters.

## Options to evaluate

- `hive_ce`: package docs describe browser boxes backed by IndexedDB and file-backed boxes on other platforms. It may simplify an Android + web baseline but query/index behavior must be benchmarked.
- `isar_community`: evaluate query/index needs and verify its current supported-platform declarations and web behavior.
- SQLite packages: `sqflite` is well established on mobile/desktop, but the package page describes web support through a separate experimental adapter; separate implementations may increase complexity.
- Other local stores only if the above fail the POC.

## Decision

Do not select one yet. Test CRUD, structured filtering, migration, search at 100/1k/10k items, restart persistence, browser behavior, export, and restore on Android and web.

## Decision criteria

1. Works on both target platforms without requiring a server.
2. Has maintained packages and clear licensing.
3. Supports safe migrations and export/restore.
4. Performance is acceptable for a personal library.
5. Does not force large native dependencies or materially increase the download size.

## Revisit when

A POC demonstrates a candidate clearly meets the criteria. Pin exact versions only after inspecting current environment and package health.
