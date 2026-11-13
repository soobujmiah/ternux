---
title: "Ternux v2.0.0 রিলিজ প্রস্তুতি"
description: "Ternux v2-এর তিনটি supported guest profile-এর বর্তমান acceptance gate ও device evidence।"
lang: "bn"
alt_url: "/docs/V2-RELEASE-READINESS.html"
---

**অবস্থা: প্রকাশিত**
**Audit তারিখ:** 2026-11-13
**লক্ষ্য:** Ternux 2.0.0
**সর্বশেষ GitHub release:** [v2.0.0](https://github.com/soobujmiah/ternux/releases/tag/v2.0.0), 2026-11-13-এ প্রকাশিত। Signed stable APT repository-ও live।

Ternux v2 desktop support কেবল **Debian, Ubuntu ও Alpine**-এর জন্য; অন্য named
distro recipe v2-qualified নয়। 20-gate inventory pre-publication approval
state রেকর্ড করে; release-এর আগে সব blocking gate pass করেছে। `v2.0.0` tag ও
GitHub release প্রকাশিত। Exact tag, package hash, CI run, post-publication APT
preservation, support scope এবং device limit জানতে পূর্ণ [v2.0.0 release report](V2-RELEASE-REPORT.md) দেখুন। Exact-main Validate run `43372097795` release commit `9106b04fc8627ae98b1d63c9912a28c8a4677441`-এ pass করেছে.
## বর্তমান acceptance gate

| Gate | অবস্থা | কী করলে বন্ধ হবে |
|---|---|---|
| P1-03 updater safety | **সম্পূর্ণ** | Source/hash pinning, replace করার আগে staging, interrupted update recovery, downgrade guard, concurrency ও symlink fixture pass; v1.4.0 source fixture থেকে v2 migration pass। প্রকাশিত v2 rollback demonstration আবশ্যক নয়। |
| P1-09 default browser | **সম্পূর্ণ** | Clean Debian Trixie, Ubuntu 24.04 ও Alpine 3.24 Firefox X11 window check exact-main Validate run `43372097795`, commit `9106b04fc8627ae98b1d63c9912a28c8a4677441`-এ pass করেছে। Ubuntu Snap ছাড়া Mozilla ESR ব্যবহার করে। |
| P1-APT signed Termux package | **সম্পূর্ণ** | Exact main `faa5f0c4733e82fa0e82c88c6a2cd4531a1c3442`-এর stable signed APT publish workflow `43362569559` সফল। Public `InRelease` fingerprint `E5527F4D5B83037FF77B65AE5E894BBB81168B1D` দিয়ে যাচাই হয়েছে; `Packages.xz` SHA-256 `3bbab20f0119b3c038e14c9a49714e499325b0c7036a899c3304e67b3b39e137`, package SHA-256 `4ef03210c71e3d5671671e9a49fc83f6aebf7cdb5e5a28cb32db61d49e85c89f`। Native `pkg update`, clean package uninstall/install, `dpkg --verify`, এবং default/`db`/`ub`/`alp` JSON verify pass। Evidence `release-gates.json` ও `audit/REPOSITORY-STATE.md`-তে আছে। |

HTP/HMX ও QNN experimental বা research-only; stable v2 প্রতিশ্রুতির বাইরে।
CPU/Vulkan দাবি accelerator plan-এ থাকা নির্দিষ্ট model, task ও SM8735/Adreno
825 evidence-এ সীমাবদ্ধ। অন্য guest recipe ও অন্য Android GPU এই gate-এ অন্তর্ভুক্ত
নয়।

## Device evidence

Reference device: Xiaomi 25053RT47C (Redmi Turbo 4 Pro), Android 16, ARM64,
SM8735 / Adreno 825। Debian `:0`, Ubuntu `:1`, Alpine `:2`-এর আগের session-গুলো
Termux:X11 ও PulseAudio route-সহ READY দেখা গেছে। Session চালু রাখা হয়েছে। তিন
guest-এ live Firefox titlebar-এ close control দেখা গেছে; পরের synthetic Ctrl+Space probe Debian ও Ubuntu-তে engine বদলেছে, Alpine-এ বদলায়নি; আগের focused Alpine GTK/XTest probe-এর সঙ্গে অমিল আছে। Alpine-এর direct helper কাজ করে। Physical Android keyboard behavior যাচাই করা হয়নি।

2026-11-13 live runtime query-তে তিন guest-এ GTK, icon, XFWM theme, `|HMC`
titlebar controls ও Ctrl+Space switch helper binding নিশ্চিত হয়েছে। Assigned
helper প্রতিটি guest-এ IBus engine বদলে আবার আগের engine-এ ফিরেছে। 1800×1900
test window তিন display-এর 640×1386 viewport-এর ভেতরে resize হয়েছে; শুধু
নিজস্ব temporary test window-গুলো বন্ধ হয়েছে। Physical keyboard event delivery
এখনো আলাদা করে unverified।

Window-fit helper-এর client coordinate translation ঠিক করা হয়েছে, EWMH
`_NET_CLIENT_LIST`-কে WINDOW ID হিসেবে পড়ে, stale work area-কে বর্তমান screen
মাপে সীমাবদ্ধ করে এবং valid maximized geometry রাখে। Source ও তিন guest-এর helper
hash এক। Ubuntu-র আগে থেকে খোলা XFCE About window বন্ধ না করে phone viewport-এর
ভেতরে আনা হয়; desktop restart করা হয়নি। বিস্তারিত ও limitation [বর্তমান
audit](../../docs/audit/CURRENT-STATE.md) এবং [device যাচাইয়ে](../../docs/audit/DEVICE-VERIFICATION.md)।

আগের device record-এ এই তিন profile-এ Turnip/Vulkan-backed Zink দেখা গেছে।
Ubuntu ও Alpine-এর জন্য ভুল display number ব্যবহার করা একটি renderer probe বাদ
দেওয়া হয়েছে; সেটিকে সমর্থন বা বিরোধী প্রমাণ ধরা হয়নি। এই ফল অন্য GPU/device-এর
qualification নয়।

## যাচাই snapshot

- `bash tests/update_transaction.sh`: এই audit-এ pinned update, migration,
  interrupted update, recovery, rollback fixture, concurrency ও symlink পরীক্ষা
  pass করেছে।
- `python3 tests/release_gates.py --check --self-test`: 20টি gate valid;
  সব blocking gate সম্পূর্ণ; gate complete হওয়ার পরেই owner authorization গ্রহণ করা হয়।
- `bash tests/firefox_package_matrix.sh`: Debian, Ubuntu ও Alpine-এর জন্য exact-
  head CI-তে যোগ হয়েছে। এটি Xvfb/Openbox-এ GTK Firefox window চালিয়ে দৃশ্যমান X11
  application window map হয়েছে কি না যাচাই করে। Exact merged-main Validate run
  `43372097795` release commit `9106b04fc8627ae98b1d63c9912a28c8a4677441`-এ matrix pass করেছে। এই Termux host-এ Docker নেই; তাই local
  container pass দাবি করা হচ্ছে না।
- `bash tests/focused.sh`: audit-এ test-hygiene issue পাওয়া গেছে—`py_compile`
  packaged asset-এর ভেতর `__pycache__` লিখছিল। এখন bytecode temporary directory-তে
  যায়। Focused suite ও পূর্ণ required CI exact-main run `43372097795`-এ pass।
- Stable publish run `43362569559` exact-main package
  `faa5f0c4733e82fa0e82c88c6a2cd4531a1c3442` sign ও deploy করেছে। Public
  bootstrap, key, `InRelease` এবং `Packages.xz` endpoint HTTP 200; `gpgv`
  signature pinned fingerprint দিয়ে যাচাই করেছে। Native Termux stable index
  নিয়েছে, `ternux` clean uninstall ও install করেছে, `dpkg --verify` এবং default
  plus `db`/`ub`/`alp` verify pass। তিনটি guest আগের PID-তে READY ছিল। GitHub
  v2.0.0 GitHub release এখন প্রকাশিত; [release report](V2-RELEASE-REPORT.md) দেখুন।

## সম্পন্ন release ধাপ

1. PR #189 English/Bengali install ও release documentation update করেছে; সব check pass করে merge হয়েছে।
2. Repository workflow `.repo/` state PR #190-এ তৈরি করেছে; check pass করে merge হয়েছে, কোনো generated file হাতে edit হয়নি।
3. Stable APT signature/index/package, native package lifecycle, guest-specific verification ও website redeploy-তে signed repository preservation pass করেছে।
4. `v2.0.0` tag ও GitHub release asset validated main `9106b04fc8627ae98b1d63c9912a28c8a4677441`-এ প্রকাশিত।
5. চূড়ান্ত প্রমাণ [v2.0.0 release report](V2-RELEASE-REPORT.md)-এ আছে। Architecture ও acceptance plan review-এর পরে v3 implementation শুরু হবে.
## বিস্তারিত audit

- [বর্তমান state ও সিদ্ধান্ত](../../docs/audit/CURRENT-STATE.md)
- [Live device যাচাই](../../docs/audit/DEVICE-VERIFICATION.md)
- [Repository ও প্রকাশনার অবস্থা](../../docs/audit/REPOSITORY-STATE.md)
- [Feature support matrix](../../docs/audit/FEATURE-MATRIX.md)
- [Machine-readable gate](https://github.com/soobujmiah/ternux/blob/main/docs/release-gates.json)

v2.0.0 tag, GitHub release, signed stable APT এবং exact release commit প্রকাশিত।
বিস্তারিত প্রমাণ [release report](V2-RELEASE-REPORT.md)-এ আছে।
