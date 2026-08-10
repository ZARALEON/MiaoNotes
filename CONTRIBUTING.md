# Contributing to MiaoNotes

Thank you for helping improve MiaoNotes. The project welcomes focused bug
fixes, tests, documentation, performance work, and carefully scoped features.

## Product constraints

Every contribution must preserve the product's priority order:

1. open quickly;
2. accept input immediately;
3. persist drafts locally;
4. search locally;
5. synchronize safely in the background.

Network access, S3, encryption setup, maintenance, migration, and code
generation must never block the startup-to-editor path. Rust Core, Electron, an
official backend, plugins, AI, and team collaboration are outside the current
scope.

## Before changing a frozen boundary

Open an issue before changing any of the following:

- SQLite schema or migration behavior;
- Sync Protocol, object layout, Revision DAG, or conflict semantics;
- cryptographic formats, algorithms, envelopes, or key storage;
- startup, autosave, durability, recovery, or export guarantees;
- dependencies that materially affect application size or startup time.

Architecture changes require a new ADR under `docs/adr/`. Wire-format changes
also require an update under `docs/protocol/` and backward-compatibility tests.

## Development workflow

1. Fork the repository or create a focused branch.
2. Keep each pull request limited to one coherent change.
3. Add or update tests for observable behavior.
4. Open a draft pull request early and let GitHub Actions run the authoritative
   Linux Core and Windows Flutter gates.
5. Resolve every failing check before requesting review.

Local toolchains are optional for documentation-only contributors. If Dart and
Flutter are installed, run the relevant checks before pushing:

```text
dart pub get
dart format --output=none --set-exit-if-changed packages/miaonotes_core tools/sync_simulator
dart analyze packages/miaonotes_core
dart analyze tools/sync_simulator
dart test packages/miaonotes_core
dart test tools/sync_simulator

cd apps/windows
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build windows --release
```

The committed Drift output must match its source schema. GitHub Actions
regenerates it and rejects stale generated code.

## Security and test data

Never commit real S3/R2 credentials, passwords, recovery keys, master keys,
tokens, private certificates, personal Vaults, or local databases. Tests must
use deterministic fixtures, Fake ObjectStore, or explicitly temporary and
least-privileged integration resources.

Do not report security vulnerabilities in a public issue. Follow
[`SECURITY.md`](SECURITY.md) instead.

## Pull request expectations

A pull request should explain:

- what changed and why;
- user-visible and compatibility impact;
- startup, durability, synchronization, and security impact;
- tests and measurements used to validate the change.

By contributing, you agree that your contribution is licensed under the
Mozilla Public License 2.0 (`MPL-2.0`).
