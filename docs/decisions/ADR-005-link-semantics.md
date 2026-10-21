# ADR-005: A saved link is not an offline website

- **Status:** Proposed; approval pending
- **Date:** 2026-10-21

## Context

The app should save websites, articles, video links, and social links. A URL does not itself contain the page or media content, and background fetching can create privacy, access, scripting, and reliability problems.

## Proposed decision

MVP stores the URL and locally entered/confirmed metadata. It opens the URL externally. Any fetched title/preview or true offline snapshot is a separately named and represented capability that requires a later scope decision.

## Acceptance rule

The user can distinguish Bookmark, Copied File, Preview Metadata, and (if ever implemented later) Offline Snapshot. The app never marks an item as available offline unless its required content is present locally and verified.
