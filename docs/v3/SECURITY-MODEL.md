---
title: "Ternux v3 security model"
description: "Threat boundaries, least privilege, artifact verification, and safe data ownership."
lang: "en"
---

## Security model

**Status: DESIGNED.** Android's Termux app sandbox is the primary security
boundary. PRoot changes process identity and filesystem view but does not
provide kernel-grade isolation from the Termux UID. Ternux must describe this
accurately.

## Assets and threats

Protected assets include Termux credentials and private files, guest data,
models, Android media, sensor access, signing keys, update artifacts, and
network-facing local services. Threats include a malicious guest package,
untrusted extension, compromised download, local web request forgery,
path traversal, symlink substitution, stale process identity, overbroad
storage grant, and accidental cleanup.

## Required controls

- Native service sockets live in private directories with restrictive modes;
  UI endpoints bind loopback and validate origin and per-session action token.
- Artifact manifests pin source, version, architecture, digest, license, and
  install ownership. Signature verification is preferred; pinned checksums
  protect transport and accidental substitution but are not represented as
  independent publisher identity.
- Installer paths are resolved beneath an allowlisted root; symlinks, path
  traversal, concurrent mutation, and unsafe ownership are checked before
  write or cleanup.
- Guest/device permissions are scoped and revocable. Camera/microphone access
  is on demand. Model discovery is read-only and automatic cleanup never
  crosses ownership boundaries.
- Update and removal operations are staged, journaled, and recoverable. A
  failure does not delete the last known-good executable or user data.
- Diagnostics redact prompt text, media, access tokens, environment secrets,
  and private absolute paths unless the user explicitly exports a report.

## Extension trust

Extensions use a versioned manifest and declare requested capabilities before
installation. Initial extensions are data and command bundles with no
auto-executed install hooks. Any later executable hook runs through a reviewed
allowlist, with explicit user confirmation, a declared filesystem scope, and
an auditable rollback. Extensions cannot silently add startup services or
expand guest mounts.

## Uninstall and recovery

`tx uninstall` enumerates Ternux-owned host paths and registered guests before
asking for confirmation. Defaults preserve user model stores and unrelated
Termux packages. The confirmation displays bytes and paths by category.
Recovery operations repair known manager state; they do not recursively delete
unknown files or reinstall a guest without explicit selection.
