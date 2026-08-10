# MiaoNotes / 喵喵便签

[English](README.md) | [简体中文](README.zh-CN.md)

> A lightweight, local-first notes app built for fast opening, fast capture, and safe synchronization.

MiaoNotes is a local-first, lightweight notes application. Its Windows Flutter
client and pure-Dart synchronization core are now being developed together while
the editor remains independent from network availability.

The product order is non-negotiable:

1. open quickly;
2. accept input immediately;
3. persist drafts locally;
4. search locally;
5. synchronize safely in the background.

Network access, S3, encryption setup, maintenance, and code generation must not be
part of the startup-to-editor path.

## Repository layout

```text
apps/
  windows/                  # Native Flutter shell, editor, and local autosave
packages/
  miaonotes_core/           # Models, Drift/SQLite store, protocol, sync engine
tools/
  sync_simulator/           # Deterministic multi-device fault simulator
docs/
  adr/                      # Frozen architectural decisions
  protocol/                 # Wire and object layout specifications
```

## Development

The workspace requires Dart 3.10 or newer.

```text
dart pub get
cd packages/miaonotes_core
dart run build_runner build
cd ../..
dart format .
dart analyze .
dart test packages/miaonotes_core/test
dart test tools/sync_simulator/test
cd tools/sync_simulator
dart run bin/sync_simulator.dart
```

The Windows application is intentionally resolved separately and requires a
stable Flutter SDK. A native build also requires Visual Studio's Desktop
development with C++ workload.

```text
cd apps/windows
flutter pub get
flutter analyze
flutter test
flutter build windows --release
```

## Cloud builds and releases

GitHub Actions is the authoritative build environment, so a local machine can be
used primarily as a code editor. Pull requests validate Core and Windows. Every
green push to `main` also provides a seven-day Windows snapshot under that
workflow run's **Artifacts** section.

Maintainers publish a version by first updating `apps/windows/pubspec.yaml`,
merging the change into a green `main`, and then pushing the matching
`vMAJOR.MINOR.PATCH` tag. The tag workflow repeats all release gates and creates a
GitHub Release containing:

- `MiaoNotes-vMAJOR.MINOR.PATCH-windows-x64-portable.zip`;
- the corresponding `.sha256` checksum.

Extract the complete ZIP before starting MiaoNotes; the executable depends on
the DLL and `data` files beside it. Current `v0.*` packages are unsigned
prereleases and may display a Windows reputation warning. No R2 or Vault secret
is stored in GitHub Actions.

The SQLite source of truth is `packages/miaonotes_core/schema/schema_v1.sql`.
Its Drift mirror is checked for exact parity, and generated database types are
committed. Product startup does not run code generation.

## Current phase boundary

Included now: the native Windows Flutter shell, fast local editor/autosave path,
`miaonotes_core`, SQLite Schema v1, the durable Drift repository, Fake ObjectStore,
Cloudflare R2/S3 ObjectStore, Sync Protocol v1, the persistent sync coordinator,
and the Sync Simulator. Drafts, revisions, events, DAG heads, per-device pull
cursors, device sequence allocation, and outbox records survive process restarts.
Pull application and cursor advancement are atomic, while remote uploads are
idempotent and resume from the durable outbox after a failure or restart.

The Windows shell creates local immutable versions after an idle editing window.
New typing that overlaps a background commit is rebased onto the resulting DAG
head. R2 can be configured from the cloud button in the notes sidebar. The remote
store starts only after the editor renders, syncs only already-committed objects,
polls in the background, and exposes offline, authentication, Vault mismatch, and
retry states without reducing local editing availability.

The sidebar exposes on-demand local full-text search over note titles and bodies.
Queries are debounced, safely converted to FTS5 prefix terms, and can be focused
with `Ctrl+F`. Search never performs network I/O or joins the startup path.

Tags v1 can be edited directly below the note title and travel inside the normal
Draft, Revision, E2E encryption, export, and import paths. The sidebar loads its
tag directory only when the filter button is opened. Exact tag filtering composes
with full-text search, and a new note inherits the active tag filter so it remains
visible in context.

Recycle Bin v1 provides confirmed soft deletion and on-demand restoration. A
note with existing history appends a synchronized tombstone Revision; restoring
it appends a normal child Revision with the original content. A never-committed
local note stays recoverable without announcing a meaningless remote deletion.
The recycle bin is loaded only when opened, and permanent history deletion is
not exposed.

R2 secrets are intentionally absent from source code, SQLite, and configuration
files. The Windows client stores them as a generic credential in the current
user's Windows Credential Manager set through pure Dart FFI. Non-sensitive
endpoint and bucket settings use a small local JSON profile. Both are loaded only
after the editor's first frame. A temporary integration tool can still read
credentials from process environment variables, work below a random
`_miaonotes-temporary-tests/` prefix, and delete the exact objects it creates.

Remote Revision and Event payloads now use E2E Crypto v1. A random Vault master
key encrypts per-object AES-256-GCM envelopes; Argon2id protects its password
envelope and HKDF-SHA256 separates recovery and object keys. The Windows client
stores only the unwrapped master key in a separate Credential Manager entry.
Passwords and the one-time recovery key are never persisted. Crypto setup and
unlock remain post-frame background work, so a locked Vault cannot delay local
opening, typing, or Draft persistence.

An existing remote without crypto metadata is accepted only when it has no
protected objects. Legacy plaintext Revision/Event data is refused rather than
silently mixed with ciphertext.

Connecting to an existing remote Vault is guarded: a mismatched Vault is read-only
until the user explicitly chooses import, and import is allowed only while the
local database contains no notes, revisions, events, outbox entries, cursors, or
conflicts.

Concurrent note bodies are now visible in the Windows conflict center. The user
can compare every head, select a version, edit the merged Markdown result, and
save an explicit merge Revision. Every prior head remains in history, dirty local
Drafts are protected, and the merge uses the existing encrypted outbox path.
Conflict details are loaded only on demand after startup.

Portable Export v1 is available from the save icon in the sidebar. It flushes
the current Draft, then exports all notes (including dirty and deleted notes),
immutable Revision history, and conflict records to a new directory under
`Documents/MiaoNotes Exports`. Every file is covered by a SHA-256 manifest and
the temporary directory is published only after a complete verification pass.
The export is deliberately readable plaintext and never contains passwords,
recovery keys, Vault master keys, or R2 credentials. Verified import remains a
separate explicit action: it revalidates every manifest entry, previews counts
and Vault identity, and restores only into an empty local Vault with no active
sync profile. Core rebuilds the Revision DAG and sync outbox in one SQLite
transaction, so a failed or tampered import leaves no partial data.

The persistent release gate covers three-device convergence, concurrent heads,
ambiguous upload responses, offline restart recovery, corrupt remote objects, and
concurrent tombstone/edit histories.

The Windows application keeps an independent Flutter lock file while consuming
the local Core package by path. This preserves a pure-Dart Core toolchain despite
Flutter's SDK-pinned analyzer dependencies.

Explicitly excluded: Rust core, Electron, an official backend/account system,
plugins, AI, team collaboration, and any synchronous startup-time remote work.

## Contributing and security

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before
changing frozen architecture, protocol, crypto, persistence, or startup
boundaries. Report suspected vulnerabilities privately as described in
[SECURITY.md](SECURITY.md), not in a public issue.

## License

MiaoNotes is licensed under the Mozilla Public License 2.0 (`MPL-2.0`). See
[LICENSE](LICENSE) for the complete terms.
