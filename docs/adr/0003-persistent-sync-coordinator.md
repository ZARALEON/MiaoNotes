# ADR 0003: Persistent sync coordinator

- Status: accepted
- Date: 2026-08-10

## Decision

Protocol v1 synchronization is coordinated by the pure-Dart
`PersistentSyncEngine`. It connects the Drift repository directly to the generic
`ObjectStore` boundary and performs no work on the startup-to-editor path.

A sync run uses this order:

1. commit dirty drafts into the local immutable log;
2. verify or create the remote vault identity object;
3. pull unseen per-device events and their parent-first revision chains;
4. push ready immutable outbox objects in dependency order.

This `syncOnce` order is retained for headless tools and recovery flows. The
interactive Windows client uses `syncCommitted` instead: its editor-owned local
commit coordinator completes step 1 before notifying remote sync, so a network
task can never commit mutable UI state behind the editor's back.

The ordering protects offline edits before remote state is observed. Revision
objects are uploaded before the events that advertise them.

## Pull safety

Remote keys, vault identity, canonical payload hashes, revision object hashes,
and per-device event sequence continuity are validated before a cursor advances.
Applying revisions, events, heads, conflicts, materialized clean note state, and
the cursor is one SQLite transaction. Dirty drafts are never overwritten by a
pull.

Unknown gaps, missing parents, hash mismatches, cycles, or vault-generation
changes stop synchronization without partial application.

## Push safety

The durable outbox is the only source for remote writes. Puts are immutable and
idempotent. A failed or ambiguous result records an attempt and retry time but
keeps the object locally. Restarting the process resumes from that same outbox;
success removes only the acknowledged object.

## Performance boundary

The coordinator is explicitly background-only. The application can open and edit
using SQLite while the network is absent, slow, misconfigured, or corrupt. No
remote listing, hashing pass, or retry loop is permitted before the editor becomes
usable.
