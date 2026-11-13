---
title: "Ternux technical debt"
description: "Known maintenance and engineering debt with impact, evidence, and disposition."
lang: "en"
---

## Technical debt

**Last reviewed:** 2026-11-13 12:26 UTC. This list separates verified constraints from
future architectural work.

| Item | Impact | Evidence / disposition |
|---|---|---|
| Ternux CLI is a shell-oriented host manager | Harder to expose a rich local API and structured jobs | v3 native manager contract is designed; no service implementation yet |
| Distro installation logic contains package-family-specific branching | New profiles can regress existing guests | Keep Debian/Ubuntu/Alpine as regression matrix; v3 recipe adapter is designed |
| IBus physical Ctrl+Space evidence is inconclusive | Config/helper can work while the physical key route fails | Preserve as a release limitation until physical-device event evidence closes it |
| Theme coverage differs by toolkit and client-side decorations | A selected GTK/XFWM theme does not guarantee every app's custom UI | Add per-toolkit acceptance probes; don't claim universal coverage |
| Hardware acceleration qualification is device-specific | Device names and driver presence do not prove correct/fast execution | Capability, correctness, performance, and release qualification stay separate |
| Existing device tests partly rely on owner-visible GUI state | Not fully reproducible in CI | Preserve exact commands, window IDs, timestamps, and state; add automated probes where safe |
| Released v2.0.0 package differs from post-release `main` source | Users of the stable package do not have newer read-only manager JSON commands | Keep stable-package/source boundaries explicit; any package delivery needs a separately versioned release and exact-head validation |
| Package metadata describes the original Debian-first scope | The installed package description can imply a Debian-only manager despite v2's three supported profiles | Correct package metadata in a separately versioned, fully validated follow-up package; do not republish changed bytes under version 2.0.0 |
| Stable doctor does not reliably follow the active guest | The installed v2.0.0 package can produce false missing-container and GPU warnings | Fix merged to main as `b26010d`; 185 focused checks and exact-main CI pass. A future package release is needed to deliver it to installed v2.0.0 users. |

Debt is removed only when a change and its regression test land. Reclassify
closed rows in the next review rather than deleting their history.
