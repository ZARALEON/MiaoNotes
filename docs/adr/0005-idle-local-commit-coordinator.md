# ADR 0005: Idle local commit coordinator

- Status: accepted
- Date: 2026-08-10

## Decision

The Windows client separates durable Draft saves from immutable Revision
creation. Keystrokes update the Draft save queue immediately. After two seconds
without another completed edit, a post-startup coordinator commits dirty Drafts
into Revision, Event, DAG head, and Outbox records using the existing Core
transaction.

The coordinator starts only after the local workspace has rendered. It never
runs in the startup-to-editor path and never performs network I/O.

## Editing during a commit

All application-level Draft writes and background commits share one controller
boundary. A commit first drains saved Draft changes, then temporarily holds newer
in-memory edits while Core creates the immutable revision. Those newer edits are
rebased onto the resulting local DAG head and saved immediately afterward.

This prevents a stale editor snapshot from creating an unrelated root revision
or an artificial conflict when a user types during background version creation.

## Failure and shutdown

A failed local commit leaves the durable dirty Draft intact and exposes a retry
state in the editor. The application never needs to wait for remote storage to
close. On shutdown it cancels a merely scheduled commit and flushes the mutable
Draft; a later startup schedules any recovered dirty Draft for background commit.

## User-visible status

The editor distinguishes local save, waiting for background version creation,
version creation, local failure, and the number of immutable objects waiting for
sync. A waiting-remote count is informational and does not reduce local editing
availability.
