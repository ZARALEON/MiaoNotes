# ADR 0010: Portable Export v1 and verified directory publication

- Status: accepted
- Date: 2026-08-10

## Decision

MiaoNotes provides an explicit, user-triggered plaintext export. Export is not
part of startup, autosave, local version creation, or background synchronization.
Before taking a snapshot, the Windows controller flushes the current editor
Draft to SQLite. The Core then reads the following in one SQLite transaction:

- every current note, including deleted and dirty Drafts;
- every immutable Revision;
- every open and resolved conflict record;
- the non-secret Vault identity.

Sync cursors, outbox state, S3/R2 credentials, passwords, recovery keys, and
unwrapped Vault master keys are excluded. Export v1 is a portable backup, not a
copy of live synchronization state.

## Directory format

Each export is a new directory below the user's `Documents/MiaoNotes Exports`
folder. It contains:

```text
manifest.json
vault.json
conflicts.json
notes/<stable-id>/note.json
notes/<stable-id>/content.md
notes/<stable-id>/content.miaodoc.json
revisions/<stable-note-id>/<stable-revision-id>.json
```

Metadata and MiaoDoc files use canonical JSON. Markdown stays UTF-8 Markdown.
Opaque, SHA-256-derived path components prevent note or Revision identifiers
from becoming filesystem paths; the original identifiers remain in metadata.

## Publication and integrity

The exporter writes to a unique sibling `.partial-*` directory. Every data file
is flushed, read back, and recorded in `manifest.json` with byte length and
SHA-256. The manifest is written last. A second pass verifies every declared
path, size, and digest before the directory is renamed to its final name on the
same volume. Existing exports are never overwritten.

On failure, cleanup is restricted to the exact partial directory whose parent is
the configured export root. No final directory is published. Manifest paths are
strict relative forward-slash paths; absolute paths, traversal, drive prefixes,
backslashes, and duplicates are rejected.

## Security and recovery boundary

The dialog warns that portable exports are readable plaintext. This is an
intentional usability tradeoff for data portability and is distinct from E2E
encryption of remote protocol objects.

Export v1 establishes a verifiable recovery artifact. Destructive import into a
live Vault is deferred; it requires a separate preview, validation, duplicate
policy, and rollback decision rather than silently mutating local data.

ADR 0012 subsequently accepts restore into an empty local Vault only. Import
into or merge with a populated Vault remains deferred.

## Verification

Core tests prove a snapshot includes immutable history and the latest dirty
Draft. Windows tests verify Markdown and metadata output, path isolation,
manifest verification, tamper detection, and cleanup after an injected write
failure. The recovery-code parser also now consumes visual separators by their
known group positions, preserving legal Base64URL hyphens inside the key.
