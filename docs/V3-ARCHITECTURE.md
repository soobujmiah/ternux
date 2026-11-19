---
title: "Ternux v3 architecture"
description: "A status-labeled overview of the Ternux v3 design and implementation boundary."
lang: "en"
alt_url: "/bn/docs/V3-ARCHITECTURE.html"
---

## V3 architecture overview

This architecture was originally organized as the Ternux v3 plan. On
2026-11-14, the owner temporarily directed its full planned scope into v2; that
decision was revoked on 2026-11-18. The v2.0.1 release gate is now complete.
V3 foundation work is active; architecture and capabilities described here are
still design or partial implementation, not a v2 feature or release claim. It
describes a native Termux manager for independent Linux workspaces, optional
compute and AI workloads, a permission-aware Android Device Bridge, and a
local Control Center. **Designed does not mean implemented or device-verified.**

## Product boundary

- Manager, CLI, Control Center, Device Bridge, and workload registry run in
  Termux, outside every PRoot guest.
- The owner-confirmed v2 baseline is Debian, Ubuntu, Kali Linux, and Alpine;
  future v3 profile expansion requires separate qualification.
- Ternux's existing AI tools and workloads remain Ternux-owned. LAI and every
  unrelated product/repository remain outside Ternux scope; no integration or
  dependency is planned without a new explicit owner decision.
- Camera, microphone, storage, GPU, and NPU operations are optional,
  permission-aware, and separately qualified.
- User files, guest files, workload artifacts, and models have explicit
  ownership. Uninstall does not silently erase data.

## Current v3 foundation work

The v2 release gate is complete. Current foundation artifacts define the
[implementation phases](v3/IMPLEMENTATION-ROADMAP.html),
[APT distribution recommendation](v3/APT-DISTRIBUTION-FEASIBILITY.html),
[distribution qualification matrix](v3/DISTRIBUTION-ROADMAP.html),
[security work order](v3/SECURITY-ROADMAP.html), and
[testing strategy](v3/TESTING-STRATEGY.html). The APT recommendation is to
keep it outside the v3.0 critical path and continue using the verified source
installer. Candidate distros and all architecture capabilities remain
unqualified until their stated gates pass.

## Technical specifications

- [Complete v3 architecture index](v3/README.html)
- [Implementation roadmap](project/PROJECT-ROADMAP.html)
- [Current implementation status](project/IMPLEMENTATION-STATUS.html)
- [Release status](project/RELEASE-STATUS.html)
- [Device verification](project/DEVICE-VERIFICATION.html)
- [Architecture decisions](project/ARCHITECTURE-DECISIONS.html)
- [Technical debt and known limits](project/TECHNICAL-DEBT.html)
- [Next actions](project/NEXT-ACTIONS.html)

## Design decisions

The architecture design records a native manager, explicit guest/data
ownership, and a rejected external-product adapter proposal. See the [ADR index]
(v3/ADR/README.html) for rationale and consequences. The evidence for the
withdrawn v2.0.0 release remains in the [v2 release report]
(V2-RELEASE-REPORT.html).
