# ADR 0002: Durable local store transaction boundary

- Status: accepted
- Date: 2026-08-10

## Decision

SQLite Schema v1 is now opened and migrated by Drift. Drift code generation is a
development-only step; generated types are committed so application startup never
runs a generator or schema parser.

The editor writes a mutable local Draft directly to SQLite. A later background
commit creates the immutable Revision and Event, updates DAG heads, allocates the
device sequence, and writes both remote objects to the Outbox in one transaction.

If any part fails, SQLite rolls back the complete commit while retaining the dirty
Draft. The application can therefore close as soon as local persistence succeeds
and never waits for S3.

## Startup decision

The first Windows client will use one local Drift/SQLite connection with prepared
statement caching and WAL. It will not create a read-isolate pool at startup. A
pool adds process and memory overhead that is unjustified for the initial recent
notes query; this decision can change only after profiling shows a benefit.

## Migration safety

Schema v1 is created automatically. Unknown upgrades do not attempt destructive
repair: opening stops and the future application enters read-only safe mode until
an explicit migration exists.
