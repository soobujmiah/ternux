---
title: "Ternux next actions"
description: "Ordered, actionable work items for the next Ternux v3 engineering slice."
lang: "en"
---

## Next actions

**Last reviewed:** 2026-11-13 12:26 UTC. This list is ordered by dependency and includes
only work that remains open.

1. Preserve the accepted native-first display contract: native Termux `:0`,
   Debian `:1`, Ubuntu `:2`, Alpine `:3`; build the collision-checked
   registry and staged migration before changing any live v2 display.
2. Implement and test the native Unix-socket service for the three existing
   read-only manager operations. Enforce the v1 request/response/error schemas,
   bounded input, one-response-per-connection behavior, and Termux-UID-private
   socket directory/file permissions. Keep service start explicit; do not add
   boot autostart in this milestone. Test malformed and oversized requests,
   wrong schema versions, unknown operations, concurrent clients, client
   disconnects, stale socket cleanup, and restart recovery.
3. Add service authorization/session runtime and verify local Web UI origin,
   token, and CSRF behavior before any mutation endpoint exists.
4. Implement durable request idempotency and owner-rooted path resolution;
   test duplicate requests, traversal, symlink races, service restart, and
   client disconnects before enabling mutations.
5. Update this page, implementation status, technical debt, and README/site
   navigation in the same change as each visible capability.
6. After the native core and service boundary pass acceptance, choose the
   first guest lifecycle action and exercise start/status/stop against a
   disposable test guest.

The current checkout already implements the read-only JSON operations in the
source CLI; the released 2.0.0 package does not yet include them. Keep that
source/package boundary visible. This list does not imply that a release or
publication has been approved.
