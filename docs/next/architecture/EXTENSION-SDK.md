---
title: "Ternux Next Version Extension SDK"
description: "Planned manifest, permission, lifecycle, compatibility, and security contract for Ternux-owned extensions."
lang: "en"
---

## Status and scope

**Status: PLANNED; no general-purpose Extension SDK is implemented.** Existing
Ternux workloads and integrations remain governed by their current manifests
and release evidence. This design applies to a future Next Version extension boundary; it
does not change published source archive behavior or qualify current previews.

Extensions are packages that add a Ternux-owned workload, compute backend,
desktop integration, or Device Bridge adapter. They must not turn a package
manifest into a promise of kernel isolation: guests and extensions ultimately
run under the Termux app UID. LAI and every unrelated repository or product
remain outside Ternux scope unless the owner makes a new explicit decision.

## Package contract

Each extension has a versioned, schema-validated manifest containing:

- Stable extension ID, display name, publisher, and manifest schema version.
- Extension version, compatible Ternux API range, guest/profile constraints,
  supported CPU architectures, and declared entry points.
- Immutable artifact URL or repository identity, archive format, SHA-256, and
  signing identity/key reference where signatures are available.
- License identifier and bundled notices, declared dependencies, disk/resource
  estimates, and upgrade/removal behavior.
- A typed capability list with a plain-language reason for each permission.

The manager rejects unknown required fields, duplicate IDs, incompatible API
ranges, missing provenance, invalid digests, unsupported architectures, and
dependencies that form a cycle. Optional metadata may be ignored only when the
schema explicitly marks it optional.

## Permissions and execution boundary

Permissions are explicit capabilities, not arbitrary host paths or ambient
environment variables. A grant is scoped to one extension, one guest or
workload, and the smallest required resource. Examples include a selected
guest-owned directory, a brokered camera capture request, or an approved
network operation. Host-device access must go through a Ternux-owned broker
with point-of-use consent and a visible denial/cancel path.

The SDK must reject unrestricted Termux home access, arbitrary `/sdcard`
mounts, secret/environment scraping, silent permission escalation, and
implicit root assumptions. Extension code executes with the same Android app
UID boundary as Ternux; a PRoot guest is not a security sandbox against the
Termux app owner or peer processes with that UID. No manifest claim may imply
otherwise.

## Lifecycle and compatibility

The manager uses a staged lifecycle:

1. Discover metadata without executing extension code.
2. Validate schema, compatibility, permission requests, provenance, license,
   architecture, available storage, and dependencies.
3. Show the user a plan and obtain grants before any privileged broker action.
4. Download to a private temporary path, verify signature/digest and archive
   path safety, then stage without overwriting the active version.
5. Run bounded health checks; activate atomically or restore the prior version.
6. Update through the same staged transaction. Remove only extension-owned
   files and retain user data unless the user explicitly selects its removal.

Extensions declare a minimum and maximum compatible manager API. The manager
does not silently install an incompatible extension, execute mutable `main`
branch source as recovery, or remove another extension's files. Interrupted
install, update, and removal operations must be safely resumable or roll back.

## Acceptance and security tests

Before an SDK or extension is marked `VERIFIED`, test at minimum:

- Valid and invalid schemas, duplicate IDs, API mismatch, dependency cycles,
  unavailable architecture, insufficient space, and unsupported guest.
- Signature and checksum mismatch, altered metadata, path traversal, absolute
  paths, symlink escapes, archive-root mismatch, and partial downloads.
- Permission grant, denial, revocation, cancellation, timeout, and broker
  failure; confirm no operation proceeds after a denial or revocation.
- Interrupted install/update/remove, failed health check, rollback, repeated
  idempotent operations, and preservation of user data and unrelated guests.
- License/provenance visibility and compatibility behavior across supported
  manager API versions.

Source presence and a passing package install are insufficient for a support
claim. Record exact Ternux commit, extension version/digest, device, guest,
commands, logs, and limitations for each qualification. The complete matrix is
maintained in the [Next Version acceptance criteria](ACCEPTANCE-CRITERIA.md) and
[testing strategy](TESTING-STRATEGY.md).
