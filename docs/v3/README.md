---
title: "Ternux v3 architecture"
description: "Future platform architecture and implementation plans for Ternux v3."
lang: "en"
---

## Ternux v3 architecture baseline

**Status: v3 development active; implementation is partial.** Version 2 is
frozen to its published implementation. The v2.0.1 release, release page, and
version-specific guide have been published and verified, so the former release
gate is complete. Current source has partial manager and Control Center slices;
the full v3 platform is not implemented. The current v3 foundation work is
documentation, security baselining, and acceptance contracts; no new capability
is considered shipped until its own tests and release evidence pass.
Current implementation and release evidence are tracked in the [project
status](../project/IMPLEMENTATION-STATUS.md) and [v2 release record](../V2-RELEASE-REPORT.md).

## Documents

1. [Product vision](PRODUCT-VISION.md)
2. [System architecture](SYSTEM-ARCHITECTURE.md)
3. [Component architecture](COMPONENT-ARCHITECTURE.md)
4. [Native Control Center](CONTROL-CENTER-ARCHITECTURE.md)
5. [Compute engine](COMPUTE-ENGINE.md)
6. [AI runtime](AI-RUNTIME-ARCHITECTURE.md)
7. [Device Bridge](DEVICE-BRIDGE-ARCHITECTURE.md)
8. [Workspace](WORKSPACE-ARCHITECTURE.md)
9. [Security model](SECURITY-MODEL.md)
10. [API design](API-DESIGN.md)
11. [UX and design system](UX-AND-DESIGN-SYSTEM.md)
12. [Implementation roadmap](IMPLEMENTATION-ROADMAP.md)
13. [Acceptance criteria](ACCEPTANCE-CRITERIA.md)
14. [Architecture Decision Records](ADR/README.md)
15. [APT distribution feasibility](APT-DISTRIBUTION-FEASIBILITY.md)
16. [Distribution expansion and qualification](DISTRIBUTION-ROADMAP.md)
17. [Security roadmap](SECURITY-ROADMAP.md)
18. [Testing strategy](TESTING-STRATEGY.md)
19. [Extension SDK](EXTENSION-SDK.md)

## Status vocabulary

`PROPOSED` means a candidate without owner approval. `DESIGNED` means the
boundary and acceptance criteria are documented. `IMPLEMENTING` means code is
under active change. `IMPLEMENTED` means code exists but its acceptance checks
are not complete. `VERIFIED` means the stated checks passed in the stated
environment. `RELEASED` means the capability shipped in a named release.
`REJECTED` means the owner declined a proposal; retain its ADR identifier for
history, but do not treat it as planned work. Status applies to a specific
component and version, never to the whole project by implication.

## Non-negotiable architecture

- The manager and Control Center run natively in Termux, outside every PRoot
  guest. The basic manager works when no guest exists and never depends on a
  guest daemon for its own lifecycle.
- Guests remain isolated workspaces selected by name. The owner-confirmed v2
  verified baseline is Debian, Ubuntu, Kali Linux, and Alpine; future profiles
  require their own qualification matrix.
- The Linux workspace remains useful offline and with low resources. AI,
  camera, microphone, GPU, and NPU components are optional workloads with
  visible resource and permission costs.
- Android access is brokered through Termux APIs or explicit scoped mounts.
  A guest never receives broader host access merely because an extension asks
  for it.
- Ternux's existing AI tools and workloads remain Ternux-owned. LAI and every
  unrelated product/repository remain outside Ternux scope; no integration or
  dependency is planned without a new explicit owner decision.
- Every performance, accelerator, device, or distro claim names its tested
  device, software version, workload, and evidence level.
