---
title: "Ternux v3 implementation roadmap"
description: "Dependency-ordered delivery phases and exit gates for Ternux v3."
lang: "en"
---

## Implementation roadmap

**Status: DESIGNED. Owner direction (2026-11-14): every phase in this former
v3 roadmap is required before the next v2-major stable release; there will be
no separate v3 stable release.** Sequence is dependency-driven. A phase closes only when
its acceptance evidence is recorded; schedule estimates are intentionally
omitted until the baseline and device capacity are measured.

| Phase | Scope | Exit gate |
|---|---|---|
| 0. Baseline | v2 release, repository, device state, known limitations | Exact release facts, evidence links, recovery/support boundary reviewed; a v1.4.0-to-v2 rollback demonstration is not required |
| 1. Contracts | Component ownership, state model, API, security, ADR process | API schemas and threat review accepted; no unresolved ownership conflicts |
| 2. Native core | Guest registry, manager service, structured jobs, CLI parity | Service optional; CLI works offline; lifecycle is per-guest and idempotent |
| 3. Control Center | Local UI, status, start/stop, logs, diagnostics | Loopback/socket security tests, accessibility, low-resource idle profile |
| 4. Workspace | Multi-distro profile/recipe engine, selection flows, theme package | Clean install/remove/update matrix for Debian, Ubuntu, Alpine; other profiles gated individually |
| 5. Compute | Capability registry, backend packs, resource policy | Per-device route probes, correctness, fallback, artifact/license and rollback gates |
| 6. AI | LAI adapter, model discovery, workload registry, job reporting | Model provenance, representative task correctness, memory/thermal and performance evidence |
| 7. Device Bridge | On-demand camera/mic/storage brokers | Permission, denial, cancellation, file integrity, privacy and per-device checks |
| 8. Extensions | Manifest, permission grants, install/update/remove | Malicious manifest, path, signature/hash, rollback, and uninstall fixtures |
| 9. Release | Docs/site, upgrade, stable package, support matrix | All blocking gates green on exact release commit and evidence archived |

## Change discipline

Each vertical slice updates source, focused tests, CLI help, README/site entry
points when user behavior changes, and the relevant canonical architecture or
living-state doc. Generated `.repo/` state is maintained by its workflow, not
hand-edited. A hardware-dependent phase may proceed in code while its physical
qualification remains explicitly `UNTESTED`.

## Release channels

Experimental artifacts use separate names, manifests, and documentation from
stable. A release does not promote a backend or distro merely because its
installer completed. Exact source commit, artifact digest, workflow run, test
device, and known limitations are captured before publication.
