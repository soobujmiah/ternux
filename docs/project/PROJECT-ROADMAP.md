---
title: "Ternux project roadmap"
description: "Living roadmap for released v2 maintenance and Ternux v3 development."
lang: "en"
---

## Project roadmap

**Last reviewed:** 2026-11-13 14:42 UTC. **State:** living project record.

## Released

- Ternux v2.0.0 is published with a signed Termux APT package and stable
  release record. Its exact claims and dated evidence are in the
  [current v2 report](../release/V2-RELEASE-REPORT.md) and
  [release-time record](../V2-RELEASE-REPORT.md).
- Debian, Ubuntu, and Alpine are the v2-supported desktop profiles on the
  documented reference device. The installed v2.0.0 package and current `main`
  source are distinct artifacts; see [release status](RELEASE-STATUS.md) and
  [implementation status](IMPLEMENTATION-STATUS.md).

## In progress: v3 foundation

1. Architecture, API, security, UX, acceptance documents, and five ADRs are
   published. New guest profiles default to Debian/Ubuntu/Alpine `:1`/`:2`/`:3`
   with native `:0` reserved; saved v2 assignments remain unchanged. Startup
   rejects occupied X11 paths and does not reclaim unproven sockets. Keep
   validating these contracts against the live native Termux runtime.
2. Current source has four read-only native manager CLI operations and a
   device-tested foreground Unix-socket transport; released 2.0.0 does not
   include them. Central display registry, manager API reporting, staged
   migration, native workspace, and Control Center remain open.
3. Add a secured native Control Center client while preserving CLI parity.
4. Connect workspace, compute, AI, and Device Bridge through versioned
   interfaces; qualify each capability independently.
5. Publish verified device and workload evidence before changing stable
   support claims.

The phase gates are in the [v3 roadmap](../v3/IMPLEMENTATION-ROADMAP.md).

## Current next action

Complete the display registry/API and staged migration design without changing
live v2 guest displays. See [next actions](NEXT-ACTIONS.md).
