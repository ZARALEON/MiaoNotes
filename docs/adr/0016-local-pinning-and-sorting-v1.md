# ADR 0016: Local pinning and sorting v1

- Status: accepted
- Date: 2026-08-13

## Decision

The Windows sidebar supports per-note pinning and three browse orders: newest
update first, oldest update first, and title ascending. Pinned notes form the
first group in every browse order. Search keeps FTS5 relevance ordering inside
the pinned and unpinned groups so a view preference does not replace search
semantics.

Pin state and the selected browse order are local workspace preferences. They
are stored in the existing SQLite `settings` table and do not enter NoteDraft,
Revision, Event, E2E payload, Portable Export, or Portable Import data. The UI
labels pin actions and pinned notes as local to the current device.

## Protocol and schema boundary

Sync Protocol v1 has no general note-metadata operation. Adding pin state to a
Revision would change the frozen canonical payload and conflict model; encoding
it as a reserved tag would expose implementation state as user content. This
phase therefore changes neither Schema v1 nor Sync Protocol v1. Cross-device pin
sync requires a separately designed metadata protocol and a new ADR.

Each pinned note uses a `note_pinned:<noteId>` setting. The browse order uses one
`note_sort_order` setting. Unpinning removes the per-note row. No preference
write marks a Draft dirty, creates a Revision, or adds an outbox object.

## Responsiveness

Preferences are read from local SQLite only. The selected sort order is loaded
before the bounded recent-note query during workspace initialization. Network,
crypto, and remote synchronization remain outside this path. The existing
persistence benchmark remains a release gate.

## Exclusions

Pinning and sorting v1 does not provide manual drag ordering, pinned groups,
cross-device preference sync, per-tag sort choices, or permanent note ranking.

## Verification

Core tests cover pin persistence, unpinning, all local-only protocol boundaries,
and deterministic ordering. Windows controller and widget tests cover the sort
menu, pin control, visible local-only state, and immediate sidebar reordering.
