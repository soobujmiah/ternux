---
title: "Ternux next actions"
description: "Ordered, actionable work items for the next Ternux v3 engineering slice."
lang: "en"
---

## Next actions

**Last reviewed:** 2026-11-13 17:30 UTC. This list is ordered by dependency and includes
only work that remains open.

1. Display registry persistence is implemented: it stores workspace identity,
   current/target display, last lifecycle, and update time, with saved display
   and lifecycle exposed in the read-only snapshot. Implement staged migration
   next. This source revision's read-only
   report matches occupied targets to a unique running guest's saved display
   assignment and labels other collisions as native-reserved or unidentified.
   This is not OS-level socket-owner proof. Live display IDs remain unchanged
   pending the migration gate.
2. Build the native Termux workspace and mobile-first Control Center client on
   `:0`, starting with read-only status and guest selection. Preserve the
   running v2 guest sessions until an explicit staged migration is ready.
3. Add an opt-in supervisor/lifecycle for the manager socket, with startup,
   stop, crash recovery, and update tests that never restart guest sessions.
4. Before adding mutations or a browser adapter, finish authorization, session
   token, origin, and CSRF checks; then implement idempotent guest lifecycle
   jobs with durable progress and safe cancellation.
5. Update this page, implementation status, technical debt, README/site
   navigation, and evidence reports with each capability.
6. Continue Workspace, Compute, AI, and Device Bridge implementation under
   their existing acceptance criteria and separate release evidence.

The read-only Unix-socket service is source-implemented and device-verified,
but is not included in released 2.0.0. Keep that source/package boundary
visible. This list does not imply that a release or publication has been
approved.
