---
title: "Ternux next actions"
description: "Ordered, actionable work items for the next Ternux v3 engineering slice."
lang: "en"
---

## Next actions

**Last reviewed:** 2026-11-13 16:11 UTC. This list is ordered by dependency and includes
only work that remains open.

1. Complete the display registry: identify owners for socket/lock/server
   collisions, persist registry identity, and implement staged migration.
   New-profile defaults, fail-closed startup guards, and read-only current/target
   reporting are implemented in `main` by PR #210; live display IDs remain
   unchanged pending the migration gate.
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
