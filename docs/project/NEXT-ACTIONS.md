---
title: "Ternux next actions"
description: "Ordered, actionable work items for the next Ternux v3 engineering slice."
lang: "en"
---

## Next actions

**Last reviewed:** 2026-11-13. This list is ordered by dependency and includes
only work that remains open.

1. Add the v3 architecture docs to the site with correct nested routes and
   English/Bangla entry-point links; build and inspect the generated pages.
2. Review architecture and ADR content against current source and remove any
   accidental claim that v3 designs are already implemented.
3. Design and test service authorization, request compatibility, errors,
   idempotency, and owner-scoped filesystem access before enabling mutations.
4. Update this page, implementation status, technical debt, and README/site
   navigation in the same change as each visible capability.
5. After the native core and service boundary pass acceptance, choose the
   first guest lifecycle action and exercise start/status/stop against a
   disposable test guest.

The active branch's exact progress is maintained by Git history and CI. This
list does not imply that a release or publication has been approved.
