# ADR 0011: Cloud build artifacts and tag releases

Status: accepted

## Context

MiaoNotes should be developable from a lightweight workstation while Windows
builds remain reproducible and visible to contributors. A release also needs a
single, auditable path that cannot silently publish a tag whose version differs
from the application.

The first distributable is a portable Windows build. Code signing and an
installer are intentionally deferred until signing identity and update-channel
decisions are frozen.

## Decision

GitHub Actions is the authoritative build environment.

- Pull requests run validation and a Windows release build, but publish no
  downloadable binary.
- Every push to `main` uploads the complete Windows release directory as a
  portable ZIP plus a SHA-256 checksum. These snapshots expire after seven days.
- A tag matching `vMAJOR.MINOR.PATCH` starts the release workflow.
- The version in the tag must exactly match the semantic version in
  `apps/windows/pubspec.yaml`; the Flutter build suffix is ignored.
- A release reruns Core validation, simulator and persistence gates, Windows
  formatting, analysis, tests, and the Windows release build.
- A successful tag build creates a GitHub Release with generated notes, the
  portable ZIP, and its SHA-256 checksum. `v0.*` releases are marked prerelease.
- Workflow release artifacts are also retained for 30 days as a diagnostic copy.
- Dart, Flutter, and the Windows runner image are pinned in the workflows.

The portable ZIP contains the entire Flutter `Release` directory. The executable
must not be distributed without its DLL and `data` siblings.

## Security boundary

The workflows require only the repository-provided GitHub token. They do not
receive Cloudflare R2 credentials, Vault passwords, recovery keys, signing keys,
or application user data.

Release binaries are currently unsigned. GitHub Releases must describe them as
prerelease builds until signing and installer ADRs are accepted.

## Consequences

Local machines may be used primarily as editors, while CI remains the final
source of build truth. Maintainers must update the application version and merge
it into a green `main` branch before pushing the matching tag.

Tags are release operations, not test inputs. A failed tag is investigated and
fixed with a new application version; an already published version is never
silently replaced.
