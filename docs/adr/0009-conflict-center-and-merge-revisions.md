# ADR 0009: Conflict center and explicit merge Revisions

- Status: accepted
- Date: 2026-08-10

## Decision

The Windows client exposes unresolved concurrent heads through an on-demand
conflict center. It does not choose a body with last-write-wins. The user sees
every current head, chooses one as a starting point, and may edit the Markdown
title and body before confirming.

Confirmation creates one ordinary immutable Revision whose parent list contains
every current head. The existing heads and their history remain stored as
ancestors. The merge Revision and its Event enter the same durable outbox and
encrypted background synchronization path as any other local commit.

Rich-text conflicts preserve the complete selected MiaoDoc value in this phase.
Manual structured editing remains deferred until the rich-text editor is
available; no conversion to HTML or Markdown is performed.

## Atomicity and stale-review protection

Conflict resolution is one SQLite transaction:

1. require that the conflict is still open;
2. require that its recorded heads exactly equal the note's current heads;
3. refuse if the note has an uncommitted local Draft;
4. create the merge Revision and Event;
5. replace the DAG heads with the merge head;
6. enqueue both immutable remote objects;
7. materialize the chosen content and mark the conflict resolved.

If synchronization adds another head while the dialog is open, confirmation
fails and the user must review the new set. A dirty Draft is never overwritten
by conflict resolution.

## Startup boundary

The startup-to-editor path performs no conflict-detail query. The existing
post-frame local coordinator reads only the recovery counters and exposes the
number of open conflicts. Full Revision bodies are loaded only when the user
opens the conflict center.

Remote materialization no longer triggers the local idle-commit timer. The
workspace increments a local-save generation only after an actual local Draft
write; background pulls and merge refreshes do not impersonate user edits.

## Verification

Core tests create concurrent heads on three persistent devices, inspect the
stored conflict, create a merge Revision, synchronize it to every device, and
verify convergence to one head. A second test proves that a dirty local Draft
blocks resolution. The Windows widget test drives the complete conflict-center
flow and verifies the materialized title/body, two-parent merge, resolved count,
and durable outbox.
