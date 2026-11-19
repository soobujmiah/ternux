---
title: "Ternux v3 implementation roadmap"
description: "Dependency-ordered delivery phases and exit gates for Ternux v3."
lang: "en"
---

## Implementation roadmap

**Status: IMPLEMENTING, active v3 work.** The v2.0.1 release and its exact
installation guide are published and verified. V2 remains frozen. Phase 0 is
complete; Phase 1 contracts and security foundations are active. Sequence is
dependency-driven. A phase closes only when its acceptance evidence is
recorded; schedule estimates are intentionally omitted until the baseline and
device capacity are measured.

| Phase | Scope | Exit gate |
|---|---|---|
| 0. Baseline | Published v2.0.1 release, repository, device state, known limitations | **Complete:** exact release facts and version-specific pages verified; evidence links, recovery/support boundary, and owner scope reconciled |
| 1. Contracts | Component ownership, state model, API, security, ADR process, distribution qualification, test plan, APT feasibility | API schemas and threat review accepted; no unresolved ownership conflicts; qualification and release gates are measurable |
| 2. Native core | Guest registry, manager service, structured jobs, CLI parity | Service optional; CLI works offline; lifecycle is per-guest and idempotent |
| 3. Control Center | Local UI, status, start/stop, logs, diagnostics | Loopback/socket security tests, accessibility, low-resource idle profile |
| 4. Workspace | Multi-distro profile/recipe engine, selection flows, theme package | Clean install/remove/update matrix for Debian, Ubuntu, Kali, Alpine; each new profile is gated individually |
| 5. Compute | Capability registry, backend packs, resource policy | Per-device route probes, correctness, fallback, artifact/license and rollback gates |
| 6. AI | Ternux-owned workload registry, runtime integrations, model discovery, job reporting | Artifact provenance, representative task correctness, memory/thermal and performance evidence; no unrelated product dependency |
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
