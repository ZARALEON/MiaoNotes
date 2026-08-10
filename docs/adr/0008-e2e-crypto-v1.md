# ADR 0008: E2E Crypto v1 and encrypted remote objects

- Status: accepted
- Date: 2026-08-10
- Supersedes: the phase deferral of cryptographic envelopes in ADR 0001

## Decision

All remote Revision and Event payloads are encrypted before they reach an S3 or
R2 ObjectStore. MiaoNotes uses a random 256-bit Vault master key, AES-256-GCM,
Argon2id password derivation, and HKDF-SHA256 key separation. The existing
logical object keys and Revision/Event identities do not change.

`MiaoNotes/vault/config.json` and `MiaoNotes/crypto/config.json` remain readable
bootstrap metadata. The crypto config contains only public algorithms and
parameters, salts, nonces, authenticated ciphertext, the active key ID, and the
Vault identity. It never contains a password, recovery key, or unwrapped master
key.

Every other protocol object is a canonical JSON encrypted envelope containing
the schema, algorithm, key ID, nonce, ciphertext, and GCM authentication tag.
The exact logical object path and key ID are authenticated as AES-GCM associated
data. Copying valid ciphertext to a different object key therefore fails
authentication.

## Key hierarchy

```text
random 256-bit Vault master key
  |-- password envelope: Argon2id -> AES-256-GCM key wrap
  |-- recovery envelope: random recovery key -> HKDF-SHA256 -> AES-256-GCM key wrap
  `-- remote object: HKDF-SHA256(path) -> AES-256-GCM payload key
```

The production password envelope uses a 16-byte random salt, 19,456 KiB of
memory, two iterations, one lane, and a 32-byte Argon2id output. The recovery
key is 32 random bytes encoded as a one-time `MN1-...` code. Password and
recovery envelopes authenticate the Vault ID, generation, key ID, and envelope
purpose, so an envelope cannot be moved between Vaults or purposes.

## Immutable retry compatibility

The remote protocol requires an ambiguous immutable upload to be retried with
identical bytes. A random nonce on every retry would violate that rule. Crypto
v1 derives a distinct AES key for each logical object path with HKDF. It then
derives the 96-bit nonce from HMAC-SHA256 of the plaintext under that per-object
key. Identical immutable content at one path produces identical ciphertext;
different paths use different keys. The protocol never intentionally encrypts
two different payloads at the same immutable path.

## Windows key storage and startup boundary

The Windows client stores the unwrapped 32-byte master key as a separate generic
credential addressed by Vault ID and key ID. The S3 credential remains in its
own credential entry. Passwords and recovery codes are not persisted.

Profile loading, Credential Manager access, Argon2id, crypto setup, and remote
I/O begin only after the editor's first frame. Draft persistence and local
Revision creation remain usable while the Vault is locked or R2 is unavailable.

The first encrypted connection displays the recovery code once. Disconnecting
removes the local profile, S3 credential, and saved Vault key, but does not
delete local notes or remote objects.

## Migration boundary

An empty remote, or one containing only its Vault identity, may receive a new
crypto config. If a remote lacks a crypto config but already contains any
Revision, Event, or other protected object, the client refuses to connect. It
does not silently mix legacy plaintext and E2E ciphertext. A separate,
backup-first migration tool is required in a later phase.

## Verification

Tests cover password and recovery unlock, absence of raw secrets from the crypto
config, wrong-password rejection, ciphertext round trips, deterministic retries,
immutable conflicts, ciphertext corruption, cross-path substitution, plaintext
legacy refusal, exact Windows master-key storage, one-time recovery UI, encrypted
background uploads, and the post-frame loading gate.
