---
title: "Ternux v3 architecture"
description: "The approved architecture baseline and phased delivery plan for Ternux v3."
lang: "en"
---

## Ternux v3 architecture baseline

**Document status: DESIGNED — implementation is not implied.** This set turns
the owner-approved v3 direction into reviewable component boundaries,
interfaces, security rules, and acceptance criteria. It does not change the
v2 release contract. Current implementation and release evidence are tracked
in the [project status](../project/IMPLEMENTATION-STATUS.md) and [v2 release
record](../V2-RELEASE-REPORT.md).

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
- Guests remain isolated workspaces selected by name. Existing Debian,
  Ubuntu, and Alpine profiles remain supported while new profiles require
  explicit evidence.
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
