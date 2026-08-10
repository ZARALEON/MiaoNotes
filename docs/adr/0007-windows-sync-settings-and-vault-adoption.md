# ADR 0007: Windows sync settings and guarded Vault adoption

- Status: accepted
- Date: 2026-08-10

## Decision

The Windows client exposes R2 configuration from a small cloud button in the
notes sidebar. The user supplies an HTTPS endpoint, bucket, optional object
prefix, S3 access key ID, and S3 secret access key. Saving performs a read-only
list and Vault identity probe before enabling the existing background sync
coordinator.

The endpoint, bucket, prefix, and region are non-sensitive and are stored in
`sync-profile.json` beside the local database. The access key ID and secret are
stored together as one generic credential in the current Windows user's
Credential Manager set. They are never written to SQLite, the JSON profile,
logs, exceptions, or source code.

The implementation calls `CredWriteW`, `CredReadW`, `CredDeleteW`, and `CredFree`
through pure Dart FFI. It introduces no Flutter method-channel plugin and no
native project code. Returned credential blob memory and temporary write buffers
are overwritten before release where the API permits.

## Startup boundary

Application construction creates only the sync settings controller. It does not
read the profile or call Windows Credential Manager. Profile loading, credential
retrieval, connection probing, and network sync begin from the existing
post-frame background callback after the local SQLite workspace and editor have
rendered.

Missing, malformed, offline, or rejected configuration therefore changes only
the visible sync status. It cannot block opening, typing, Draft persistence, or
local Revision creation.

## Connection and replacement

A candidate configuration lists only the configured protocol prefix and reads
`MiaoNotes/vault/config.json`. It performs no write before the local and remote
Vault identities have been classified. An invalid remote identity stops the
connection. Replacing a working configuration keeps the old connection alive
until the candidate has passed its read-only probe.

Disabling sync removes the local profile and the exact Windows credential. It
does not delete local notes, revisions, outbox objects, or any remote R2 object.

## Guarded Vault adoption

An empty remote has no identity and may be initialized by the normal immutable
sync flow. A matching remote may connect immediately. A remote with another
Vault identity requires an explicit import confirmation.

The Core permits that adoption only when all of these remain empty:

- notes and Drafts;
- revisions and events;
- outbox and remote cursors;
- conflicts.

The next local event sequence must also still be one. Adoption retains the local
device ID but replaces the generated empty Vault identity with the remote one. If
any protected row exists, the transaction throws and neither local identity nor
remote objects are changed.

## Verification

Tests cover non-sensitive profile persistence, credential redaction, an exact
Windows Credential Manager write/read/delete round trip, first connection,
read-only mismatch handling, empty-database adoption, rejection after a saved
Draft, settings UI connection, and the post-frame credential-loading gate.
