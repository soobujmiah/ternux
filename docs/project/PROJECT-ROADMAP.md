---
title: "Ternux project roadmap"
description: "Living roadmap for released v2 maintenance and Ternux v3 development."
lang: "en"
---

## Project roadmap

**Last reviewed:** 2026-11-13. **State:** living project record.

## Released

- Ternux v2.0.0 is published with a signed Termux APT package and stable
  release record. Its exact claims and dated evidence are in the
  [v2 release report](../V2-RELEASE-REPORT.md).
- Debian, Ubuntu, and Alpine are the v2-supported desktop profiles on the
  documented reference device. The current installed v2 CLI's device
  verification labels may lag newer source evidence; see
  [release status](RELEASE-STATUS.md).

## In progress: v3 foundation

1. Finish and review the v3 architecture/specification set.
2. Implement the native manager core/API without guest dependency.
3. Add a secured native Control Center client while preserving CLI parity.
4. Refactor workspace, compute, AI, and Device Bridge behind versioned
   interfaces; qualify each capability independently.
5. Publish verified device and workload evidence before changing stable
   support claims.

The phase gates are in the [v3 roadmap](../v3/IMPLEMENTATION-ROADMAP.md).

## Current next action

Complete the architecture/docs baseline, verify its site build and links, then
select the first native-manager vertical slice with a focused acceptance test.
See [next actions](NEXT-ACTIONS.md).
