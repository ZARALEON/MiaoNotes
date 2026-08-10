# ADR 0012: Portable Import v1 with atomic empty-Vault restore

- Status: accepted
- Date: 2026-08-10

## Decision

MiaoNotes can restore a Portable Export v1 directory through an explicit,
user-triggered preview and confirmation flow. Import is never part of startup,
autosave, local commit, or background synchronization.

Import v1 is intentionally not a merge operation. It is allowed only when:

- the local database has no notes, revisions, events, outbox objects, cursors,
  conflicts, or attachments;
- the local device event sequence is still at one; and
- the Windows client has no active S3/R2 synchronization profile.

The automatically initialized placeholder Vault does not count as user data. A
successful import replaces that placeholder identity with the exported Vault
identity while retaining the new installation's local device identity.

## Verification and preview

The Windows import service verifies the manifest, byte lengths, and SHA-256
digests before parsing any object. It additionally rejects:

- undeclared or missing files;
- symbolic links and paths outside the selected directory;
- case-insensitive path collisions;
- unknown file layouts or mismatched stable path components;
- manifests larger than the two-GiB Import v1 boundary;
- note, Revision, conflict, count, timestamp, or Vault metadata mismatches.

The user sees the exported Vault ID, timestamp, note count, Revision count, and
conflict count before confirmation. Every digest and structure check is repeated
after confirmation to prevent a file changed after preview from being imported.

## Core transaction

Core validates all identifiers and references before opening the write
transaction. Revisions must belong to the exported Vault, reference an exported
note, form an acyclic per-note DAG, and contain only available same-note parents.
Draft bases, committed Revision pointers, and conflict heads must resolve.
Current open conflicts must exactly match the reconstructed DAG heads.

One SQLite transaction then:

1. adopts the exported Vault identity;
2. inserts Revisions in deterministic topological order;
3. reconstructs current note heads;
4. restores clean and dirty Drafts plus conflict history;
5. creates new local sync Events and durable outbox entries for every imported
   Revision; and
6. advances the retained local device sequence.

Re-announcing immutable Revision objects makes a local disaster recovery usable
with an empty remote store and remains idempotent when the remote already has
those objects. Any validation, disk, or injected write failure rolls back the
Vault identity and every imported row.

## Security and exclusions

Import consumes the same readable plaintext artifact described by ADR 0010. It
does not import S3 credentials, passwords, recovery codes, Vault master keys,
device credentials, sync cursors, or previous device event sequences. Remote
sync must be configured and cryptographically unlocked again after recovery.

Import v1 does not merge into a populated Vault, overwrite notes, import
attachments, or automatically change external sync configuration.

## Verification

Core tests cover history restoration, search materialization, durable requeue,
missing-parent rejection, and full rollback after an injected fault. Windows
tests cover export-to-import round trips, post-preview tampering, undeclared
files, inconsistent counts, workspace refresh, and the visible import entry
point. The dialog keeps bounded progress states while service and Core tests own
the filesystem and transaction matrix.
