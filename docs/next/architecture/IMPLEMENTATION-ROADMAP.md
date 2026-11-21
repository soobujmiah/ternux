---
title: "Ternux Next Version implementation roadmap"
description: "Dependency-ordered delivery phases and exit gates for Ternux Next Version."
lang: "en"
---

## Implementation roadmap

**Status: IMPLEMENTING, active Next Version work.** The source archive and its installation guide document the historical tag; the
GitHub Release entry is removed and the package repository is unavailable. the earlier implementation remains a historical reference. Phase 0 is
complete; Phase 1 contracts and security foundations are active. Sequence is
dependency-driven. A phase closes only when its acceptance evidence is
recorded; schedule estimates are intentionally omitted until the baseline and
device capacity are measured.

| Phase | Scope | Exit gate |
|---|---|---|
| 0. Baseline | Published source archive, repository, device state, known limitations | **Complete:** exact release facts and version-specific pages verified; evidence links, recovery/support boundary, and owner scope reconciled |
| 1. Contracts | Component ownership, state model, API, security, ADR process, distribution qualification, test plan, APT feasibility | API schemas and threat review accepted; no unresolved ownership conflicts; qualification and release gates are measurable |
| 2. Native core | Guest registry, manager service, structured jobs, CLI parity | Service optional; CLI works offline; lifecycle is per-guest and idempotent |
| 3. Control Center | Local UI, status, start/stop, logs, diagnostics | Loopback/socket security tests, accessibility, low-resource idle profile |
| 4. Workspace | Multi-distro profile/recipe engine, selection flows, theme package | Clean install/remove/update matrix for Debian, Ubuntu, Kali, Alpine; each new profile is gated individually |
| 5. Compute | Capability registry, backend packs, resource policy | Per-device route probes, correctness, fallback, artifact/license and rollback gates |
| 6. AI | Ternux-owned workload registry, runtime integrations, model discovery, job reporting | Artifact provenance, representative task correctness, memory/thermal and performance evidence; no unrelated product dependency |
| 7. Device Bridge | On-demand camera/mic/storage brokers | Permission, denial, cancellation, file integrity, privacy and per-device checks |
| 8. Extensions | Manifest, permission grants, install/update/remove | Malicious manifest, path, signature/hash, rollback, and uninstall fixtures |
| 9. Release | Docs/site, upgrade, stable package, support matrix | All blocking gates green on exact release commit and evidence archived |

## Next Version milestones

These are acceptance-bounded release milestones, not date promises. A milestone
does not promote a feature or distribution automatically; promotion requires
its own evidence and support decision. Work may overlap only after its named
contracts and dependencies are accepted.

| Milestone | Objective and implementation scope | Dependencies | Acceptance gate | Explicitly out of scope |
|---|---|---|---|---|
| **Phase 0 — Foundation** | Accept component ownership, manager/API/state contracts, installer modularization boundaries, test layers, security threat model and remediation order, distribution qualification process, and the separate APT feasibility decision. Preserve the published source archive behavior and four-profile baseline while building Next Version foundations. | Published source archive baseline; phase 1 contracts; owner review for material architecture decisions. | Contracts and ADRs agree; every Next Version subsystem has an owner and test gate; high-risk recovery, credential, dependency, and action-pinning findings have accepted implementation plans; APT is either deferred or has a gated prototype plan; earlier release regression suite remains green. | Stable APT publication, claiming new distros, replacing existing credentials, broad installer rewrite, or declaring the Next Version platform complete. |
| **Phase 1 — Platform Expansion** | Deliver the optional native manager service, guest lifecycle and state model, supervision/recovery, display allocation, and the first Control Center workflows. Evaluate and qualify candidate guest profiles one at a time. | Phase 0 contracts, native-manager security review, installer and guest ownership tests. | CLI remains usable with the service stopped; manager works with zero guests; socket/API negatives pass; install/start/stop/restart/recovery/uninstall preserve unrelated guests and user data; each advertised candidate passes its complete distro matrix. | Treating a recipe as supported, requiring a guest daemon for host management, systemd/kernel-container claims, or launching all candidate distros at once. |
| **Phase 2 — Compute and Workloads** | Add the capability registry, backend/resource policy, Ternux-owned AI/workload lifecycle, on-demand Device Bridge brokers, and a permissioned Extension SDK prototype. | Stable manager contracts; Phase 1 lifecycle and job model; artifact and permission schemas. | Correctness is separate from detection/performance; workload and extension artifacts verify provenance, architecture, license, and digest; permission grant/deny/revoke and cancellation paths pass; device integrations are qualified on named hardware; rollback and data-preservation fixtures pass. | Unbounded host access, background camera/microphone use, treating app labels as accelerator execution, or integrating unrelated products/repositories. |
| **Phase 3 — Ecosystem Maturity** | Complete developer APIs, automation, extension lifecycle and documentation, broader device qualification, security remediation, and the release/support process. Target eight fully qualified distributions; ten remains a stretch goal. Reconsider APT only if its independent feasibility gates pass. | Phase 1/Phase 2 accepted contracts and implementations; security and distribution evidence; explicit owner decision for any stable APT channel. | Exact-commit CI, release artifact provenance, upgrade/rollback/uninstall, support ownership, bilingual docs, and reference-device evidence pass; each supported distribution meets the full qualification matrix. APT is supported only if every gate in the feasibility study is satisfied. | Fixed delivery dates, promising ten distributions, lowering qualification thresholds, or publishing an unqualified extension/backend/package channel. |

The detailed phases below provide subsystem-level sequencing; this milestone
map groups them into release-sized outcomes. The active milestone is Phase 0
foundation work. Phase 1–Phase 3 remain planned and their gates are not yet complete.

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
