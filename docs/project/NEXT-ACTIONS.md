---
title: "Ternux next actions"
description: "Ordered, actionable work items for the next Ternux v3 engineering slice."
lang: "en"
---

## Next actions

**Last reviewed:** 2026-11-13. This list is ordered by dependency and includes
only work that remains open.

1. Implement and test the native Unix-socket service for read-only manager
   operations, enforcing the v1 request/response schemas and private socket
   permissions without starting it automatically.
2. Add service authorization/session runtime and verify local Web UI origin,
   token, and CSRF behavior before any mutation endpoint exists.
3. Implement durable request idempotency and owner-rooted path resolution;
   test duplicate requests, traversal, symlink races, service restart, and
   client disconnects before enabling mutations.
4. Update this page, implementation status, technical debt, and README/site
   navigation in the same change as each visible capability.
5. After the native core and service boundary pass acceptance, choose the
   first guest lifecycle action and exercise start/status/stop against a
   disposable test guest.

The active branch's exact progress is maintained by Git history and CI. This
list does not imply that a release or publication has been approved.
