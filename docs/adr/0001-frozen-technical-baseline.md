# ADR 0001: v4.1 frozen technical baseline

- Status: accepted
- Date: 2026-08-10

## Decision

MiaoNotes uses Flutter + Dart, SQLite + Drift, and SQLite FTS5. The core protocol
is implemented as a pure Dart package so that all clients share the same wire
model without a native bridge.

Synchronization uses immutable revisions in a DAG and an immutable event stream
per device. It does not use CRDTs. S3-compatible object storage is a user-supplied
optional backend; MiaoNotes does not operate an account service or official cloud.

Remote payload encryption remains frozen to AES-256-GCM, Argon2id, and
HKDF-SHA256. Cryptographic envelopes are outside the phase-1 simulator, but their
future addition may not change revision or event identity.

## Performance boundary

The local draft write path is independent from revision creation and from remote
I/O. UI startup reads only the minimum local SQLite state needed to display recent
notes. Sync, hashing of committed revisions, FTS maintenance beyond the current
transaction, and attachment work run after the editor is usable.

## Rejected for v1

- Rust core and native FFI bridges;
- Electron;
- an official backend or mandatory account;
- plugins, AI, and collaborative editing;
- SQLCipher by default;
- network-dependent startup.

Changing any item above requires a new ADR and a measured startup impact report.
