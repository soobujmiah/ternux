---
title: "Ternux v3 compute engine"
description: "Capability discovery and safe selection of CPU, Vulkan, GPU, and device NPU routes."
lang: "en"
---

## Compute engine

**Status: DESIGNED.** Capability detection, runtime installation, backend
selection, workload execution, and performance qualification are separate
states. No one state implies another.

## Capability record

Each discovered route records: backend identifier, device/driver identity,
architecture, runtime and driver versions, supported operations, memory
budget, provenance, detection method, last probe result, and evidence level.
Sensitive device identifiers are minimized in exported reports. A device
model string alone never marks a route usable.

## Selection chain

For graphics and compute requests the engine evaluates only installed
compatible routes, in user-configurable order. A failed initialization
produces a diagnostic and may move to a declared fallback (for example,
Turnip/Zink, VirGL, then llvmpipe for the supported desktop graphics path).
The current v2 route remains the compatibility baseline until a v3 route
passes its own guest/device acceptance tests. The selected route is written to
the session/job record and exposed to the application environment only for
that session; no global driver variable is set for incompatible GPUs.

## Runtime packs

Driver and compute packs are versioned, signed or checksum-pinned manifests
with architecture, ABI, source, license inventory, install destinations,
conflicts, post-install probes, and rollback instructions. Install stages
files and validates them before activation. Removal reports shared files and
does not delete files owned by another pack.

## Resource policy

Jobs declare minimum RAM, disk, accelerator memory, thread count, expected
duration range, and whether they can be interrupted. Defaults leave capacity
for Android and the desktop. The engine can warn or defer work on thermal or
memory pressure; it may not claim performance based on an unmeasured device.
The user can choose CPU/GPU/NPU explicitly where supported.

## Evidence levels

`detected` means a device/driver was identified. `available` means a runtime
can initialize. `executed` means the named operation completed.
`correctness-verified` means output passed a stated reference check.
`measured` means a reproducible workload and numeric result were captured.
`qualified` means all release-specific correctness, stability, resource, and
recovery gates passed on the stated device class. See the
[acceptance criteria](ACCEPTANCE-CRITERIA.md).
