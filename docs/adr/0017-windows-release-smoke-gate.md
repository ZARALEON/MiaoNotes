# ADR 0017: Windows release smoke gate

- Status: accepted
- Date: 2026-08-13

## Decision

Every Windows snapshot and tagged release build must start the compiled
`miaonotes.exe` before packaging. The gate waits for both a native main window
and a newly created SQLite database, then closes only the process it launched.
Unit and widget tests remain required; this gate adds coverage for failures in
native runner startup, Flutter engine loading, packaged runtime files, and the
real file-backed application bootstrap.

The smoke process receives a unique directory through the
`MIAONOTES_DATA_DIRECTORY` environment variable. This override takes precedence
over `LOCALAPPDATA` only when explicitly set. Normal launches continue to use
`%LOCALAPPDATA%\MiaoNotes`, so the release gate cannot read or alter a runner's
normal notes, sync profile, or R2 configuration.

## Startup boundary

The override is resolved synchronously from the process environment and performs
no I/O by itself. Directory creation and SQLite opening remain the first local
application operations. Network, R2, credential loading, crypto setup, and
background synchronization remain after the editor's first frame and are not
required for the smoke gate to pass.

## Failure policy

The gate fails when the executable exits early, does not create its isolated
database, or does not expose a main window within 30 seconds. Packaging and
artifact publication must not run after such a failure. Temporary smoke data is
left in the hosted runner's ephemeral temporary directory for job diagnostics.

## Exclusions

This is not a full end-to-end UI test, a real R2 integration test, an installer
test, or a substitute for testing on physical Windows machines. It deliberately
does not enter credentials, create user content, or modify Sync Protocol v1.
