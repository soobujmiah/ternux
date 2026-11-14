---
title: "Ternux project roadmap"
description: "Living roadmap for the next v2-major platform release."
lang: "en"
alt_url: "/bn/docs/project/PROJECT-ROADMAP.html"
---

## Project roadmap

**Last reviewed:** 2026-11-14. **State:** active owner-directed release plan.

The owner directs the next stable release to remain in the v2 major and include
the complete platform architecture formerly planned for v3. This page tracks
implementation and qualification against that scope.

## Release status

- Ternux v2.0.0 was withdrawn on 2026-11-14. The GitHub Release object is
  absent and the public stable APT index returns HTTP 404. The `v2.0.0` source
  tag remains for provenance and must not be reused.
- The next stable release stays in the v2 major. The planned v3 platform
  architecture and its acceptance gates are now required scope for that next
  2.x release; there will be no separate v3 stable release.
- The stable APT channel stays withdrawn until the implementation and
  exact-release gates are complete. The opt-in `/apt-rc` channel remains a
  candidate-testing channel.
- The supported desktop matrix remains Debian, Ubuntu, and Alpine. The latest
  managed reference-device follow-up reinstalled Ubuntu and Alpine, retained
  Debian, and observed all three sessions concurrently READY; see the updated
  [device verification record](../audit/DEVICE-VERIFICATION.md).

## Required platform scope

The architecture dossier under [`../v3/`](../v3/README.md) remains the detailed
specification. Its work is sequenced by dependencies and is release-blocking for
the next v2-major stable release:

1. **Native manager and migration:** host-owned registry, structured jobs, CLI parity, optional supervised service, safe display/session ownership, and staged migration that preserves working guests.
2. **Control Center:** secured local status, start/stop, logs, diagnostics, accessibility, and low-resource behavior; CLI remains usable without it.
3. **Workspace:** collect every selected guest's username and shell before any guest install begins; then install/update/recover/remove Debian, Ubuntu, and Alpine independently, with user data and unrelated guests preserved.
4. **Compute and AI:** capability registry, backend and workload ownership, CPU/GPU correctness, failure recovery, resource policy, and LAI integration through its documented interface.
5. **Android Device Bridge:** permission-aware camera, microphone, and scoped storage operations, including deny/cancel/failure paths.
6. **Extensions:** validated manifests, scoped permissions, integrity/provenance checks, rollback, repair, and safe uninstall.
7. **Release integration:** align package metadata, CLI help, bilingual docs/site, security review, exact-commit CI, clean device installation, and three-guest lifecycle evidence.

A phase is complete only when its acceptance criteria have reproducible evidence. A source implementation, build, installer completion, or one-device check does not qualify the whole platform.

## Current implementation evidence

Current source contains native manager operations, a foreground Unix-socket
service, an initial loopback-only read-only browser dashboard (tx control),
and an explicit journaled display migration executor. Migration focused tests,
three-guest lifecycle/browser CI, and exact-main post-merge CI passed; the live
reference-device switch remains unapplied while its guest sessions run. The full
Control Center and service supervision remain incomplete. Multi-guest onboarding
collects the shared shell, each selected guest username, and workload choice
before the first guest transaction. Debian, Ubuntu, and Alpine are installed and
currently running on the reference device. The 2026-11-14 main-source managed restart,
synthetic GUI input, and short three-guest soak passed; the clean browser matrix
also passed in CI. These checks do not complete the broader clean lifecycle or
release gates. Details are in [implementation status](IMPLEMENTATION-STATUS.md),
[current-state audit](../audit/CURRENT-STATE.md), and [device verification](../audit/DEVICE-VERIFICATION.md).

## Next actions

The dependency-ordered engineering list is maintained in [next actions](NEXT-ACTIONS.md).
The stable channel remains withdrawn until every required gate passes on the
exact new 2.x release candidate.
