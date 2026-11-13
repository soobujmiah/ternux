---
title: "Ternux technical debt"
description: "Known maintenance and engineering debt with impact, evidence, and disposition."
lang: "en"
---

## Technical debt

**Last reviewed:** 2026-11-13. This list separates verified constraints from
future architectural work.

| Item | Impact | Evidence / disposition |
|---|---|---|
| Ternux CLI is a shell-oriented host manager | Harder to expose a rich local API and structured jobs | v3 native manager contract is designed; no service implementation yet |
| Distro installation logic contains package-family-specific branching | New profiles can regress existing guests | Keep Debian/Ubuntu/Alpine as regression matrix; v3 recipe adapter is designed |
| IBus physical Ctrl+Space evidence is inconclusive | Config/helper can work while the physical key route fails | Preserve as a release limitation until physical-device event evidence closes it |
| Theme coverage differs by toolkit and client-side decorations | A selected GTK/XFWM theme does not guarantee every app's custom UI | Add per-toolkit acceptance probes; don't claim universal coverage |
| Hardware acceleration qualification is device-specific | Device names and driver presence do not prove correct/fast execution | Capability, correctness, performance, and release qualification stay separate |
| Existing device tests partly rely on owner-visible GUI state | Not fully reproducible in CI | Preserve exact commands, window IDs, timestamps, and state; add automated probes where safe |
| Legacy generated docs and project status need a single v3 index | Readers can confuse proposal/design/released status | New v3 index and living pages added; site routing and navigation remain to verify |

Debt is removed only when a change and its regression test land. Reclassify
closed rows in the next review rather than deleting their history.
