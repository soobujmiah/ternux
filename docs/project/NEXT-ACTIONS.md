---
title: "Ternux next actions"
description: "Ordered, actionable work items for the next Ternux v3 engineering slice."
lang: "en"
---

## Next actions

**Last reviewed:** 2026-11-14. This list is ordered by dependency and includes
only work that remains open.

1. Display registry persistence and a migration preview are implemented. The
   preview identifies per-guest `initialize`/`keep`/`move` actions and marks
   active sessions, occupied targets, or invalid registry state as blockers.
   It is read-only and cannot execute a migration. Next, design and test a
   recoverable executor that stages targets, preserves live sessions until an
   explicit switch, and rolls back without changing existing assignments on
   failure. The display report's owner classification remains best-effort, not
   OS-level socket-owner proof.
2. Extend `tx control` from the read-only browser snapshot into the full
   Control Center: service-backed session handling, diagnostics, graphics/audio,
   storage grants, optional workloads, accessible mobile panels, and native
   workspace status. Keep every action read-only until typed authorization and
   immutable preview plans are implemented.
3. Add an opt-in supervisor/lifecycle for the manager socket, with startup,
   stop, crash recovery, resource measurement, and update tests that never
   restart guest sessions.
4. Implement typed, idempotent guest lifecycle jobs with durable progress,
   safe cancellation, confirmation-bound plans, and CLI recovery when the
   service is stopped.
5. Stage the v2-to-v2-major display migration while preserving active guest
   sessions; run the exact migration on the reference device only after the
   non-destructive preview and recovery tests pass.
6. Continue Workspace, Compute, AI, Device Bridge, and extension implementation
   under their acceptance criteria and separate release evidence. Update this
   page, implementation status, README/site navigation, and evidence reports
   with each verified capability.

The read-only Unix-socket service is source-implemented and device-verified,
but is not included in released 2.0.0. Keep that source/package boundary
visible. This list does not imply that a release or publication has been
approved.
