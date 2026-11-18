---
title: "Ternux v3 architecture"
description: "Future platform architecture and implementation plans for Ternux v3."
lang: "en"
---

## Ternux v3 architecture baseline

**Status: future design; implementation is partial.** On 2026-11-18, the owner
revoked the 2026-11-14 decision that moved the former v3 scope into the next v2
release. Version 2 is frozen to the existing implementation; new capabilities
and architecture remain v3 work. Begin v3 implementation only after v2.0.1 is
published and its release page and guide are verified. Current source has
partial manager and Control Center slices; the full v3 platform is not
implemented.
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

## Status vocabulary

`PROPOSED` means a candidate without owner approval. `DESIGNED` means the
boundary and acceptance criteria are documented. `IMPLEMENTING` means code is
under active change. `IMPLEMENTED` means code exists but its acceptance checks
are not complete. `VERIFIED` means the stated checks passed in the stated
environment. `RELEASED` means the capability shipped in a named release.
Status applies to a specific component and version, never to the whole project
by implication.

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
- LAI remains a separate AI application/runtime. Ternux integrates with LAI's
  published interface; it does not fork or silently duplicate its model store.
- Every performance, accelerator, device, or distro claim names its tested
  device, software version, workload, and evidence level.
