---
title: "Ternux Next Version Termux APT distribution feasibility"
description: "Evidence-based decision and qualification gates for any future Ternux APT channel."
lang: "en"
---

## Decision summary

**Recommendation: keep APT out of the Phase 0 critical path and keep the verified
source installer as the supported route.** Preserve the option to prototype a
signed, versioned APT channel after the Phase 0 security and release foundations
are in place. Do not describe APT as available while its stable repository is
withdrawn. This is a feasibility recommendation, not authorization to
republish a package channel.

The historical implementation demonstrates that a signed Termux package and
repository can be built and installed. It does not establish that ongoing APT
delivery is currently operational or that it is safer or simpler than the
installer. The stable package channel was withdrawn on 2026-11-14 as part of a deliberate
release-policy change. The available history does not identify a fundamental
limitation in `pkg` or the repository format. The
available history records a deliberate release-policy withdrawal, not an
identified fundamental limitation in `pkg` or the repository format. A prior
website deployment could also have removed the hosted APT tree; preservation
and signature/checksum validation were subsequently added. The exact remaining
maintenance cost and upgrade behavior require a fresh prototype before a
positive decision.

## Evidence baseline

- `docs/TERMUX-APT.md` records stable `/apt` as withdrawn and states that the
  stable bootstrap, key, index, and package endpoints are unavailable. The
  opt-in `/apt-rc` route is not a supported installation source.
- `docs/release/V2-RELEASE-RECONCILIATION.md` records that a signed historical
  package was installed by Termux `pkg`, then the stable distribution was
  withdrawn. The later source archive is source-based.
- `packaging/termux/` contains package, repository, bootstrap, and Pages
  preservation tooling. `.github/workflows/termux-apt-release.yml` is
  version-gated to the withdrawn historical package and has controlled RC
  publication and stable-channel withdrawal paths; it is not a Next Version release pipeline.
- Prior evidence is historical. No current package installation, stable
  repository publication, key rotation drill, rollback, or Next Version package upgrade
  is proven by these files.

## Trade-off assessment

| Area | Potential APT benefit | Cost or unresolved risk | Required prototype evidence |
|---|---|---|---|
| Discovery and updates | Familiar `pkg install` / `pkg upgrade`; dependency metadata and package inventory | Ternux is an orchestrator with guest state and recovery semantics, not just a static CLI; package upgrades must not silently mutate guests | Clean Termux install, package upgrade with live guests, interrupted upgrade, rollback |
| ARM64 delivery | Termux `Architecture: all` can distribute shell/Python assets across ARM64 devices | Native helper binaries and optional artifacts still need explicit ABI variants and provenance | Inspect package contents and dependency closure on supported Termux ARM64 |
| Repository hosting | Signed index, Release metadata, checksums, and package channel can provide standard package workflows | Pages deployment, retention, key custody/rotation, index expiry, and incident response become ongoing operations | Reproducible build; signed metadata verification; failure and key-rotation drills |
| Dependencies | `Depends` can declare Termux host packages | Termux packages change independently; guest dependencies cannot be represented as host package dependencies | Test clean dependency install, missing dependency, held package, and offline/error path |
| Versioning | APT offers explicit versions and downgrade mechanics | Package version, installer source pin, CLI, and guest schema must remain aligned | Upgrade, downgrade, version pin, and migration compatibility tests |
| Removal | `pkg uninstall` integrates with host package ownership | It can remove host files while guest data must remain safe and separately owned | Verify package removal preserves guest/model data and removes only owned files |
| Integrity | Signed repository metadata authenticates the archive key and protects metadata integrity | Key compromise/rotation and compromised CI remain supply-chain threats; hash alone is not publisher identity | Protected signing environment, full fingerprint verification, provenance and recovery plan |
| Maintenance | Standard package metadata can simplify ordinary updates | Second delivery path doubles docs, CI, release coordination, user support, and endpoint monitoring | Measure owner maintenance tasks over at least two release cycles |

## Gate sequence

### A. Research

1. Reconcile the withdrawn source release withdrawal history with the exact previous workflow
   runs, release assets, and support commitments before changing scripts.
2. Document package ownership: Termux host files, guest data, caches, models,
   config, logs, and generated artifacts.
3. Define supported Termux versions, package dependencies, version policy,
   key custody, key rotation, expiry, rollback, and repository incident
   response.
4. Compare the user benefit and maintenance hours against the source installer.
   If no material benefit is demonstrated, stop and retain the installer-only
   policy.

### B. Isolated prototype

1. Build a reproducible `Architecture: all` package from an exact source commit;
   produce a manifest, digest, and build provenance.
2. Publish only to an isolated experimental channel with a distinct key and
   explicit opt-in instructions.
3. Verify signed `InRelease`, package/index hashes, full key fingerprint,
   version pinning, dependency closure, and package contents on a clean Termux
   installation.
4. Test install, update, interruption, retry, downgrade, uninstall, missing
   network, stale metadata, invalid signature, and key-rotation recovery.
5. Confirm package removal and failed upgrades preserve all guest data and
   unrelated Termux packages.

### C. Qualification and release decision

APT remains `EXPERIMENTAL` until all prototype evidence is repeatable and the
project owner explicitly accepts the maintenance and security responsibilities.
It may be marked `SUPPORTED` only when repository availability, signed metadata,
reproducible package builds, safe upgrade/removal/recovery, provenance,
monitoring, rotation, and release documentation all pass on the stated Termux
baseline. Otherwise keep it `PLANNED` or reject it and continue with the source
installer.

## Current status

| Property | Status |
|---|---|
| Stable APT endpoint | Withdrawn / unavailable |
| Signed earlier release package history | Historically verified; not current |
| RC endpoint | Not a supported install source; current availability must be checked before use |
| Next Version feasibility | Evaluated in this document; prototype and operational-cost evidence remain open |
| User-facing claim | Do not advertise APT installation |
| Supported install route | Version-specific source installation guide |
