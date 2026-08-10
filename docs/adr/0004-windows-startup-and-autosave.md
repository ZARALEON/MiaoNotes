# ADR 0004: Windows startup and autosave boundary

- Status: accepted
- Date: 2026-08-10

## Decision

The Windows client is a native Flutter application that depends directly on the
pure-Dart `miaonotes_core` package. It keeps its Flutter dependency resolution
separate from the root pure-Dart workspace because Flutter pins analyzer support
packages independently from Drift's development-only code generator.

The repository remains one Monorepo and the application continues to consume the
same local Core source through a path dependency.

## Startup order

The client renders a minimal Flutter frame immediately, then opens one local
SQLite connection and loads recent notes. The editor is focused as soon as that
local state is ready. Optional background work is scheduled by a post-frame hook
and cannot delay the local workspace.

No network request, remote vault verification, sync replay, attachment hydration,
or code generation is part of startup.

## Autosave

Editing updates the in-memory draft synchronously. A coalescing writer begins the
SQLite draft write without awaiting it on the UI callback. If more input arrives
while a write is running, only the latest pending snapshot is written next.

Navigation, lifecycle changes, and application shutdown flush the pending writer.
Save errors leave the newest snapshot pending, remain visible in the editor, and
offer an explicit retry. Revision creation and remote outbox work remain separate
background operations.
