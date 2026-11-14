---
title: "Ternux next actions"
description: "Ordered engineering work for the next v2-major platform release."
lang: "en"
alt_url: "/bn/docs/project/NEXT-ACTIONS.html"
---

## Next actions

**Last reviewed:** 2026-11-14. This list tracks open implementation and evidence
work for the next v2-major release. The stable channel remains withdrawn.

1. Extend the partial native Control Center: authenticated, confirmation-bound
   desktop start/stop and durable job records are implemented in working source;
   complete device-browser validation, logs, diagnostics,
   graphics/audio/storage/workload panels, accessible mobile layouts, and a
   useful low-resource idle profile. CLI operation must remain available
   without Python or the browser.
2. Add optional manager-service supervision with startup, health, stop, and crash
   recovery. Service updates must not restart guest sessions.
3. Harden typed, idempotent lifecycle jobs with durable progress, safe
   cancellation, retained-job policy, and CLI recovery when the service is
   stopped. The current start/stop slice journals before execution and marks
   interrupted work for reconciliation; cancellation is not available. Preserve per-guest state and unrelated PRoot guests.
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
source. The state-bound plan revalidates under an exclusive lock; active guests,
another managed session holding the shared lock, and unsafe targets block
execution. The journal supports rollback and `--recover`. On 2026-11-14 the
reference-device migration was applied with all guests stopped; Debian's
launcher was regenerated for `:1`, then Debian, Ubuntu, and Alpine restarted
READY on `:1/:2/:3`. The broader clean install/update/resume/restart/stop/uninstall
matrix remains open. Owner classification remains best-effort, not proof of
OS-level socket ownership.

The read-only Unix-socket service and browser dashboard, including the current
working-branch desktop action slice, are source features, not part of the
withdrawn 2.0.0 package. This roadmap records implementation work;
it does not approve a release or publication.
