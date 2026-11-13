---
title: "Ternux project roadmap"
description: "Living roadmap for released v2 maintenance and Ternux v3 development."
lang: "en"
---

## Project roadmap

**Last reviewed:** 2026-11-13 16:11 UTC. **State:** living project record.

The owner's complete v2/v3 assignment is preserved verbatim in the
[repository-only master goal](../../engineering/MASTER-GOAL.md). This is the scope/specification source; current
implementation and qualification status are tracked separately in this roadmap,
the [implementation status](IMPLEMENTATION-STATUS.md), and the dated
[current-state audit](../audit/CURRENT-STATE.md).

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
   rejects occupied socket/lock/server paths and does not reclaim unproven
   sockets. PR #210 merged initial targets and a read-only current/target report;
   central display ownership and staged migration remain open.
2. Current `main` has four read-only native manager CLI operations and a
   device-tested foreground Unix-socket transport; released 2.0.0 does not
   include them. Staged migration, native workspace, and Control Center remain
   open.
3. Add a secured native Control Center client while preserving CLI parity.
4. Connect workspace, compute, AI, and Device Bridge through versioned
   interfaces; qualify each capability independently.
5. Publish verified device and workload evidence before changing stable
   support claims.

The phase gates are in the [v3 roadmap](../v3/IMPLEMENTATION-ROADMAP.md).

## Current next action

Implement display ownership and staged migration without changing live v2 guest
displays before its migration gate. See [next actions](NEXT-ACTIONS.md).
