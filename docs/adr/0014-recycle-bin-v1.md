# ADR 0014: Recycle Bin v1 with reversible tombstone Revisions

- Status: accepted
- Date: 2026-08-10

## Decision

The Windows client exposes confirmed soft deletion and an on-demand recycle bin.
Deletion is never a physical row, Revision, Event, or remote object purge. A note
with committed history appends a standard Sync Protocol v1 tombstone Revision;
restoration appends a standard upsert Revision whose parent is that tombstone.
The title, body, format, and tags remain in immutable history and are restored
without a separate backup lookup.

The recycle bin is queried only after the user opens it. Deleted notes stay out
of recent-note and FTS search results, so startup and normal browsing do not scan
them. No network operation is awaited by the delete or restore interface; the
resulting immutable objects enter the existing durable outbox.

## Local-only notes

A saved Draft without a Revision has never been announced to another device.
Deleting it creates a clean local recycle-bin entry but no Revision, Event, or
outbox object. Restoring that entry creates its first normal upsert Revision.
Discarding an untouched placeholder editor creates no database row.

## Atomicity and concurrency

Core changes the deletion flag, creates the Revision and Event when required,
updates DAG heads and conflicts, and enqueues remote objects in one SQLite
transaction. A tombstone created from concurrent heads is an explicit merge over
all current heads. Remote deletion of the currently visible clean note moves the
editor to another recent note or a new empty Draft after pull refresh.

Failures leave the prior note visible and retryable. Restoration verifies that
the requested note still exists in the recycle bin before changing it.

## Exclusions

Recycle Bin v1 does not provide permanent deletion, retention timers, bulk
operations, remote object garbage collection, or history rewriting. Those would
require a separately frozen cross-device retention and compaction protocol.

## Verification

Core tests cover committed delete/restore DAGs, search exclusion, durable outbox
counts, local-only deletion, and full rollback after an injected commit fault.
Windows controller and widget tests cover
confirmation, list removal, on-demand recycle loading, restoration, content
preservation, and remote deletion of the current editor.
