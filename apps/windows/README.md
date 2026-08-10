# MiaoNotes Windows MVP

The Flutter shell opens the local Drift/SQLite database, restores the most recent
note, focuses the Markdown editor, and writes edits through a coalescing local
save queue. The first typed change starts saving immediately without making the
UI await SQLite.

Startup will follow this order:

```text
open local SQLite -> render recent notes -> focus editor -> start background work
```

It must never wait for S3, E2E setup, attachment hydration, index maintenance, or
sync replay before the editor becomes usable.

Background work is exposed as an application hook and is scheduled only after
the local workspace has rendered its first frame. No remote backend is configured
by default.

## Current surface

- recent local notes;
- title and Markdown body editing;
- immediate local autosave with visible state and retry;
- idle Draft-to-Revision commit without blocking the editor;
- visible count of immutable objects waiting for sync;
- on-demand local FTS5 search across note titles and bodies with `Ctrl+F`;
- new note button and `Ctrl+N`;
- manual local version commit with `Ctrl+S`;
- Windows-native executable shell.

Development uses the stable Flutter SDK. Producing the `.exe` requires Visual
Studio with the Desktop development with C++ workload; analysis and Flutter
widget tests do not require that native compiler.
