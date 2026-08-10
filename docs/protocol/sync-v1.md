# MiaoNotes Sync Protocol v1

## Safety rule

No single device failure, remote-store failure, wrong endpoint, corrupt object, or
retry may silently expand into data loss on other devices.

## Identity

Every object carries `vaultId` and `vaultGeneration`. A client stops before
writing when either differs from its local identity. A generation change is a
re-bootstrap boundary, not an incremental-sync event.

`deviceId` is a namespace for event sequencing and device management. It is not a
cryptographic authorization boundary in protocol v1.

## Immutable objects

```text
MiaoNotes/
  vault/config.json
  crypto/config.json
  revisions/{noteId}/{revisionId}.json
  events/{deviceId}/{sequence20}-{eventId}.json
```

Objects are created with put-if-absent semantics. Repeating the same key and bytes
is success; observing different bytes at an existing immutable key is corruption.
Snapshots and attachments are reserved for later phases and do not change the
source-of-truth rule:

```text
Revision DAG + device event streams = source of truth
Snapshot = disposable checkpoint
```

The Vault and crypto configs are readable bootstrap metadata. Revision, Event,
and future protected payloads are canonical AES-256-GCM envelopes. HKDF-SHA256
derives a separate payload key for each logical object path, and that path is
also authenticated as associated data. Clients must decrypt and authenticate an
object before parsing its Revision/Event JSON or checking its protocol hash.

Encrypted bytes remain subject to the same immutable rule. Repeating a logical
key and plaintext must produce the same envelope bytes so an ambiguous upload is
safe to retry. A missing crypto config beside existing protected objects is a
legacy-migration boundary and stops synchronization.

## Revision v1

A revision contains:

- schema, vault identity, note ID, revision ID, and device ID;
- zero or more parent revision IDs;
- operation (`upsert` or `tombstone`);
- canonical note format (`markdown` or `miaodoc`), content, title, and tags;
- UTC creation time and a SHA-256 payload hash.

Two children of the same parent are concurrent heads. Protocol v1 preserves both
heads and reports a conflict. It never resolves body conflicts by last-write-wins.
A user-approved merge revision names every resolved head as a parent.

Before creating that merge, a client must verify that the reviewed head set is
still the current head set and that no dirty local Draft would be overwritten.
The merge Revision, Event, head replacement, outbox writes, materialized note,
and conflict status change are one local transaction. A newly arrived head makes
the review stale and requires the user to inspect the conflict again.

## Event v1

Each device owns a strictly increasing sequence starting at 1. An event points to
one immutable revision object and records its SHA-256 object hash. Gaps stop cursor
advancement. Corrupt or missing referenced objects stop application of that event.

## Local transaction boundary

Creating a committed revision, updating local heads, allocating the next device
sequence, and adding both remote objects to the outbox is one SQLite transaction.
An application may exit once the draft/revision/outbox transaction is durable; it
does not wait for S3.

Applying a remote event is a second atomic boundary. The client inserts its
parent-first revision chain, updates DAG heads, records the event, advances that
device's cursor, materializes clean note state, and refreshes conflict state in
one SQLite transaction. A validation or database failure rolls back all of these
changes, including the cursor.

## Sync order

```text
flush dirty drafts to local revisions
verify remote vault identity
pull and validate unseen events
apply revisions without overwriting concurrent heads
push the local immutable outbox in dependency order
```

A long-offline device therefore protects genuinely new local work before pulling,
but it cannot resurrect an old clean state because clean state never creates a new
revision merely by reconnecting.

Interactive clients split the first line from the network run. Their local editor
coordinator durably creates revisions and outbox entries; the background remote
coordinator then verifies, pulls, and pushes only committed objects. This preserves
the same protocol order without giving a network task ownership of live Drafts.

## Failure handling

- Remote unavailable: keep drafts, revisions, and outbox locally; retry later.
- Ambiguous upload result: retry the identical immutable put.
- Hash mismatch or missing object: do not update the cursor or local note.
- Ciphertext authentication failure or missing key: do not parse or apply it.
- Vault mismatch or generation change: enter safe mode; do not write remotely.
- Concurrent tombstone and edit: preserve both heads for explicit resolution.

The pull path never overwrites a dirty local draft. It may add verified revisions
and heads around that draft, but the user's in-progress text remains the
materialized editor state until an explicit local commit or conflict resolution.
