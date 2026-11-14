---
title: "Ternux next actions"
description: "Ordered engineering work for the next v2-major platform release."
lang: "en"
alt_url: "/bn/docs/project/NEXT-ACTIONS.html"
---

## Next actions

**Last reviewed:** 2026-11-14. This list tracks open implementation and evidence
work for the next v2-major release. The stable channel remains withdrawn.

1. Finish the native Control Center: add authenticated, confirmation-bound
   lifecycle actions, logs, diagnostics, graphics/audio/storage/workload panels,
   accessible mobile layouts, and a useful low-resource idle profile. The
   current source dashboard is read-only; CLI operation must remain available
   without Python or the browser.
2. Add optional manager-service supervision with startup, health, stop, and crash
   recovery. Service updates must not restart guest sessions.
3. Complete typed, idempotent lifecycle jobs with durable progress, safe
   cancellation, confirmation-bound plans, and CLI recovery when the service is
   stopped. Preserve per-guest state and unrelated PRoot guests.
4. Finish the Workspace acceptance matrix: clean install, update, resume,
   restart, stop, and uninstall for Debian, Ubuntu, and Alpine. Multi-guest
   onboarding now gathers the shared shell and every username/workload before
   the first guest transaction; preserve that precollection contract.
5. Continue Compute, AI, Device Bridge, and extension work under their
   acceptance criteria, with correctness, permission, failure, rollback, and
   device evidence kept separate.
6. Audit and align package metadata, CLI help, English/Bengali docs, website,
   security review, exact-commit CI, and clean reference-device installation.
   Keep the stable channel withdrawn until every required gate passes on the
   exact 2.x release candidate.

## Completed source slice: display migration

The native display registry and explicit migration executor are implemented in
source. `tx manager migrate --apply sha256:PLAN_ID` revalidates the state-bound
plan under an exclusive lock; active guests and unsafe targets block execution.
The journal supports rollback and `--recover`. Focused migration regressions and
three-guest lifecycle/browser CI passed on PR #233 and merge commit
`376abe08a936c2fcbf161fc779d3c101e8255e99`. The reference device currently has
Debian, Ubuntu, and Alpine desktops running, so the destructive live assignment
switch has not been applied. Its saved `:0/:2/:3` assignments remain unchanged.
Owner classification remains best-effort, not proof of OS-level socket ownership.

The read-only Unix-socket service and browser dashboard are source features, not
part of the withdrawn 2.0.0 package. This roadmap records implementation work;
it does not approve a release or publication.
