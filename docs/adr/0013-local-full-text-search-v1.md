# ADR 0013: On-demand local full-text search v1

- Status: accepted
- Date: 2026-08-10

## Decision

The Windows sidebar exposes title and body search backed by the existing SQLite
FTS5 index. Search is explicitly user-triggered and is never part of startup,
autosave, local commit, synchronization, or remote object processing.

The UI waits for a short 180-millisecond editing pause before querying. `Ctrl+F`
focuses the search field, a visible clear action returns to recent-note ordering,
and an empty result has a dedicated state. Creating a note also leaves search
mode so the new editor is immediately visible.

## Query safety and ordering

Core, rather than the UI, converts user text into the FTS expression. Whitespace
separates terms, punctuation-only terms are ignored, embedded quotes are escaped,
and each remaining term becomes a quoted prefix term joined with `AND`. Raw user
text is never interpreted as FTS operators or syntax.

Results use FTS5 `bm25` relevance followed by most-recent update time, retain the
existing 50-note bound, and exclude tombstones. An empty query returns the normal
recent-note list.

## Responsiveness and failure boundary

Workspace query generations prevent a slower earlier request from replacing a
newer result. Search progress and retryable failure stay inside the sidebar;
editor content and locally persisted Drafts remain available. Search performs no
schema migration, adds no package, and does not alter Sync Protocol v1.

## Verification

Core tests cover prefix matching, multi-term matching, punctuation, and malformed
quote input. Windows controller and widget tests cover filtering, clearing, and
leaving search mode when a new note is created.
