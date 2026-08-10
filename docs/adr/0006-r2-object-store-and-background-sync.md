# ADR 0006: R2 ObjectStore and Windows background sync boundary

- Status: accepted
- Date: 2026-08-10

## Decision

`miaonotes_core` implements Cloudflare R2 through the generic S3-compatible API.
The adapter uses AWS Signature Version 4, region `auto`, path-style bucket URLs,
conditional `If-None-Match: *` writes, read-after-conflict byte verification, and
paginated ListObjectsV2 queries. It supports exact-key deletion only as an
administrative cleanup method; Sync Protocol v1 never deletes remote objects.

The adapter accepts one endpoint origin, bucket, credentials, and optional object
prefix. Logical protocol keys cannot escape that prefix. Authentication and
transport errors are classified without including response bodies, authorization
headers, access key IDs, or secret values in exceptions.

## Credential boundary

Credentials are not compiled into the client, checked into the repository, or
written to a local settings file. The integration smoke tool reads S3 credentials
from its process environment only. Cloudflare account API tokens are not required
for S3 object operations and are not consumed by the application.

Production configuration will later persist secrets through Windows Credential
Manager. Until that UI exists, the Windows application accepts an injected
`ObjectStore` and optional disposer at its application boundary.

## Windows scheduling boundary

The remote coordinator starts from the post-frame background callback, after the
SQLite workspace and editor are usable. It performs an initial sync, observes
completed local commits, polls every minute, and offers an explicit retry. Network
work never participates in application opening, keystroke handling, Draft saves,
or local Revision creation.

Interactive synchronization calls `syncCommitted`, which cannot commit mutable
Drafts. The local commit coordinator remains the only application component that
can turn editor Drafts into immutable Revisions. Pull materialization also keeps
dirty Drafts intact and refreshes the visible workspace only while no local save
or commit is in flight.

## Verification

The SigV4 signer is locked against AWS's published S3 signing example. Local
tests cover S3 URI encoding, credential redaction, immutable write idempotency,
conflicts, Unicode keys, pagination, prefix isolation, and exact deletion.

A live R2 smoke run writes two objects below a cryptographically random temporary
prefix, verifies put/get/list/conflict behavior, deletes both exact keys in a
`finally` cleanup, and confirms the prefix is empty. No existing bucket object is
listed outside or modified beyond that prefix.
