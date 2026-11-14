---
title: "Ternux implementation status"
description: "পরের v2-major release-এর বর্তমান source, CI ও device evidence।"
lang: "bn"
alt_url: "/docs/project/IMPLEMENTATION-STATUS.html"
---

## Implementation status

**Repository baseline:** 2026-11-14. এই status current source, exact CI এবং
device evidence আলাদা করে; historical v2.0.0 package-এর আচরণ এতে অন্তর্ভুক্ত নয়।

| Area | অবস্থা | Evidence / বাকি gate |
|---|---|---|
| v2.0.0 distribution | WITHDRAWN | Git tag provenance-এর জন্য রাখা; GitHub Release সরানো ও stable APT বন্ধ। [Release status](/docs/project/RELEASE-STATUS.html) দেখুন। |
| Debian / Ubuntu / Alpine desktop | Recipe implement করা; তিন guest-ই reference device-এ running | Device qualification নির্দিষ্ট Redmi Turbo 4 Pro/SM8735/Adreno 825-এ সীমিত। Physical keyboard ও অন্য hardware এখনো unqualified। |
| Installer onboarding ও UI | বর্তমান source-এ IMPLEMENTED | Multi-guest install আগে shell, username ও workload choice সংগ্রহ করে; শেষে প্রতিটি guest-এর start ও shell command দেখায়। 80x24 screen-এ বড় ASCII wordmark ও compact device/graphics panel। Local UI renderer 56/56; focused suite 190/190। |
| Native Control Center | PARTIAL | Current working source-এ random loopback port, expiring bearer token, action-এর same-origin/CSRF check, state-bound confirmation এবং durable start/stop job record আছে। Backend test-এ idempotency, restart reconciliation ও display guard আছে। Working branch-এর authenticated API দিয়ে live Ubuntu ও Alpine stop/start pass করেছে; পরে তিন guest-ই running দেখা গেছে। Rendered browser interaction এখনো verify হয়নি। Debian display migration করে source-managed CLI restart pass হয়েছে; পুরো browser workflow যাচাই বাকি। Native Android client, supervisor, cancellation, diagnostics ও graphics/audio/storage/workload panel বাকি। |
| Native manager ও migration | Source-এ IMPLEMENTED; একবার live migration/restart verify | State-bound plan, exclusive lock, active-session/shared-lock blocker, rollback journal ও recovery আছে। 2026-11-14-এ সব guest থামিয়ে reference device-এ Debian `:1`-এ migrate করে তিন guest-ই `:1/:2/:3`-এ READY restart হয়েছে। Full clean lifecycle matrix বাকি। |
| Workspace profile engine | PARTIAL; 15 profile recipe | Multi-guest precollection আছে; প্রতিটি advertised guest-এর clean install/update/resume/restart/stop/uninstall evidence সম্পূর্ণ করতে হবে। |
| Compute ও AI | DESIGNED / আলাদা optional artifact | Platform-wide runtime correctness বা accelerator support দাবি করা হয় না। |
| Camera/microphone Device Bridge | NOT_IMPLEMENTED | Permission-aware broker ও failure-path evidence বাকি। |
| Termux package downloader | বর্তমান source-এ fallback fix | Package bootstrap curl চালু কি না পরীক্ষা করে; curl ভাঙা বা download fail হলে wget চেষ্টা করে। Partial Termux upgrade ঠিক করতে apt update && apt full-upgrade নির্দেশনা আছে। |

Focused migration, multi-distro lifecycle, browser, package bootstrap, UI render ও
documentation tests current source-এ pass করেছে। Installer/UI change PR #235 এবং
generated-state PR #236 main-এ merge হয়েছে; exact-main Validate, package ও
repository-contract checks pass করেছে। Stable channel withdrawn-ই থাকবে।

## সীমাবদ্ধতা

- Physical Android Ctrl+Space delivery-এর evidence conflicting; configuration
  বা helper call একা physical keyboard behavior প্রমাণ করে না।
- Desktop qualification কেবল নথিভুক্ত device ও তিন guest-এর জন্য; অন্য device
  বা distro-তে দাবি প্রযোজ্য নয়।
- Current source ও withdrawn 2.0.0 package আলাদা artifact। Source feature
  package-এ থাকা বোঝায় না।
- Service foreground-এ চলে; background supervisor এখনো নেই। বিস্তারিত [next
  actions](/bn/docs/project/NEXT-ACTIONS.html)-এ আছে।
