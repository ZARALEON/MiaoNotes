# Security Policy

## Supported version

MiaoNotes is pre-release software. Security fixes currently target the latest
commit on `main`; no older release line is guaranteed to receive backports.

## Reporting a vulnerability

Please do not open a public issue for a suspected vulnerability. Use GitHub's
[private vulnerability reporting](https://github.com/ZARALEON/MiaoNotes/security/advisories/new)
to share the details privately with the maintainer.

Include, when possible:

- affected commit or version;
- reproduction steps or a minimal proof of concept;
- expected and observed behavior;
- impact on local data, synchronization, encryption, credentials, or recovery;
- any suggested mitigation.

Particularly sensitive areas include Vault key handling, AES-GCM object
envelopes, password and recovery envelopes, Windows Credential Manager, S3
request signing, remote object validation, path handling, conflict resolution,
export integrity, and any condition that can cause silent data loss.

Do not include real user data, production credentials, recovery keys, or Vault
master keys in a report. Use synthetic fixtures and revoke any credential that
may already have been exposed.

The maintainer will assess reports privately and coordinate disclosure after a
fix or mitigation is available. Please allow a reasonable investigation period
before publishing details.
