---
title: "Ternux v3 architecture"
description: "A status-labeled overview of the Ternux v3 design and implementation boundary."
lang: "en"
alt_url: "/bn/docs/V3-ARCHITECTURE.html"
---

## V3 architecture overview

Ternux v3 is designed as a native Termux manager for independent Linux
workspaces, optional compute and AI workloads, a permission-aware Android
Device Bridge, and a local Control Center. The detailed specifications are
linked below. **Designed does not mean implemented or device-verified.**

## Product boundary

- Manager, CLI, Control Center, Device Bridge, and workload registry run in
  Termux, outside every PRoot guest.
- Debian, Ubuntu, and Alpine v2 behavior remains the compatibility baseline.
- LAI remains separate; Ternux integrates only through a documented API and
  does not automatically move or delete LAI's models.
- Camera, microphone, storage, GPU, and NPU operations are optional,
  permission-aware, and separately qualified.
- User files, guest files, workload artifacts, and models have explicit
  ownership. Uninstall does not silently erase data.

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

The v3 design records a native manager, explicit guest/data ownership, and
LAI integration through an adapter. See the [ADR index](v3/ADR/README.html)
for rationale and consequences. The release evidence for the already-shipped
v2 remains in the [v2 release report](V2-RELEASE-REPORT.html).
