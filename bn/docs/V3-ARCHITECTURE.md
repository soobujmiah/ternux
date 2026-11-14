---
title: "Ternux v3 architecture"
description: "Ternux v3-er Native Termux manager, guest workspace, compute, AI, ebong Android Device Bridge-er design index."
lang: "bn"
alt_url: "/docs/V3-ARCHITECTURE.html"
---

## Ternux platform architecture

এই architecture-টি আগে Ternux v3 নামে পরিকল্পনা করা হয়েছিল। 2026-11-14-এ owner
নির্দেশ দিয়েছেন, এর সম্পূর্ণ planned scope পরের v2-major stable release-এ থাকবে;
আলাদা v3 stable release হবে না। **অবস্থা: design আছে, implementation আংশিক।**
এর scope-এ native Termux manager/Control Center, আলাদা Linux workspace, compute
ও AI workload, Android Device Bridge, security, API, UX এবং acceptance gate আছে।

## English technical specification

Canonical technical specification English-e rakha hoyeche, jate interface,
security boundary ও acceptance terms এক থাকে। [Architecture index](/docs/V3-ARCHITECTURE.html)
দেখুন। কোনো item `DESIGNED` হলেই সেটি code-এ implemented বা device-এ verified
প্রমাণ হয় না।

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
- [Project roadmap](/bn/docs/project/PROJECT-ROADMAP.html)
