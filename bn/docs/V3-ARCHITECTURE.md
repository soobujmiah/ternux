---
title: "Ternux v3 architecture"
description: "Ternux v3-er Native Termux manager, guest workspace, compute, AI, ebong Android Device Bridge-er design index."
lang: "bn"
alt_url: "/docs/V3-ARCHITECTURE.html"
---

## Ternux v3 architecture

**Obostha: design complete korar kaj cholche; implementation hoye geche emon
noy.** Ei v3 baseline-e native Termux manager/Control Center, alada Linux
workspace, compute o AI workload, Android Device Bridge, security, API, UX, ebong
acceptance gate-er design thakbe.

## English technical specification

Architecture-er canonical detailed specification English-e rakha hocche jate
interface, security boundary, and acceptance terms ek rokom thake. [V3
architecture index porun](/docs/V3-ARCHITECTURE.html). Ei specification-e je item
`DESIGNED`, seta code-e implemented ba device-e verified dhora jabe na.

## Product boundary

- Manager ebong Control Center Termux host-e cholbe; guest-er bhitore noy.
- Debian, Ubuntu, Alpine-er existing v2 behavior compatibility baseline.
- CPU/GPU/NPU, AI, camera/microphone sob optional ebong evidence-gated.
- LAI alada thakbe; Ternux tar model store automatically copy/delete korbe na.
- `/sdcard` explicit grant-e guest theke use kora jabe; uninstall media delete
  korbe na.

## Status page

- [Implementation status](/docs/project/IMPLEMENTATION-STATUS.html)
- [Release status](/docs/project/RELEASE-STATUS.html)
- [Device verification](/docs/project/DEVICE-VERIFICATION.html)
- [Next actions](/docs/project/NEXT-ACTIONS.html)
