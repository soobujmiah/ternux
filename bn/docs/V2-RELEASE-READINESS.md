---
title: "Ternux v2.0.0 রিলিজ প্রস্তুতি"
description: "Ternux v2-এর তিনটি supported guest profile-এর বর্তমান acceptance gate ও device evidence।"
lang: "bn"
alt_url: "/docs/V2-RELEASE-READINESS.html"
---

**অবস্থা: GitHub release তৈরির জন্য প্রস্তুত**
**Audit তারিখ:** 2026-11-13
**লক্ষ্য:** Ternux 2.0.0
**সর্বশেষ GitHub release:** v1.4.0। Ternux 2.0.0 signed stable APT repository-তে প্রকাশিত; GitHub tag ও release এখনো তৈরি হয়নি।

Ternux v2 desktop support কেবল **Debian, Ubuntu ও Alpine**-এর জন্য। CLI-তে
অন্য distro recipe থাকলেও সেগুলো v2-qualified নয়।
[`release-gates.json`](https://github.com/soobujmiah/ternux/blob/main/docs/release-gates.json)-এর 20টি gate বর্তমানে
`READY_FOR_OWNER_APPROVAL`; owner release অনুমোদন করেছেন। Signed RC ও stable
repository, website preservation, native Termux package lifecycle এবং তিন
profile-এর browser CI pass করেছে। Stable APT publication সম্পন্ন; এখন শুধু
`v2.0.0` GitHub tag/release ও final release report বাকি। Exact-main Validate
run `43362104082` commit `faa5f0c4733e82fa0e82c88c6a2cd4531a1c3442`-এ pass করেছে;
এতে তিন-profile browser matrix ও পূর্ণ documentation suite আছে।

## বর্তমান acceptance gate

| Gate | অবস্থা | কী করলে বন্ধ হবে |
|---|---|---|
| P1-03 updater safety | **সম্পূর্ণ** | Source/hash pinning, replace করার আগে staging, interrupted update recovery, downgrade guard, concurrency ও symlink fixture pass; v1.4.0 source fixture থেকে v2 migration pass। প্রকাশিত v2 rollback demonstration আবশ্যক নয়। |
| P1-09 default browser | **সম্পূর্ণ** | Clean Debian Trixie, Ubuntu 24.04 ও Alpine 3.24 Firefox X11 window check exact-main Validate run `43362104082`, commit `faa5f0c4733e82fa0e82c88c6a2cd4531a1c3442`-এ pass করেছে। Ubuntu Snap ছাড়া Mozilla ESR ব্যবহার করে। |
| P1-APT signed Termux package | **সম্পূর্ণ** | Exact main `faa5f0c4733e82fa0e82c88c6a2cd4531a1c3442`-এর stable signed APT publish workflow `43362569559` সফল। Public `InRelease` fingerprint `E5527F4D5B83037FF77B65AE5E894BBB81168B1D` দিয়ে যাচাই হয়েছে; `Packages.xz` SHA-256 `3bbab20f0119b3c038e14c9a49714e499325b0c7036a899c3304e67b3b39e137`, package SHA-256 `4ef03210c71e3d5671671e9a49fc83f6aebf7cdb5e5a28cb32db61d49e85c89f`। Native `pkg update`, clean package uninstall/install, `dpkg --verify`, এবং default/`db`/`ub`/`alp` JSON verify pass। Evidence `release-gates.json` ও `audit/REPOSITORY-STATE.md`-তে আছে। |

HTP/HMX ও QNN experimental বা research-only; stable v2 প্রতিশ্রুতির বাইরে।
CPU/Vulkan দাবি accelerator plan-এ থাকা নির্দিষ্ট model, task ও SM8735/Adreno
825 evidence-এ সীমাবদ্ধ। অন্য guest recipe ও অন্য Android GPU এই gate-এ অন্তর্ভুক্ত
নয়।

## Device evidence

Reference device: Xiaomi 25053RT47C (Redmi Turbo 4 Pro), Android 16, ARM64,
SM8735 / Adreno 825। Debian `:0`, Ubuntu `:1`, Alpine `:2`-এর আগের session-গুলো
Termux:X11 ও PulseAudio route-সহ READY দেখা গেছে। Session চালু রাখা হয়েছে। তিন
guest-এ live Firefox titlebar-এ close control দেখা গেছে; synthetic XTest
Ctrl+Space দিয়ে বাংলা input engine বদলেছে। Synthetic key event physical keyboard
behavior প্রমাণ করে না।

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
  `43362104082`-এ matrix pass করেছে। এই Termux host-এ Docker নেই; তাই local
  container pass দাবি করা হচ্ছে না।
- `bash tests/focused.sh`: audit-এ test-hygiene issue পাওয়া গেছে—`py_compile`
  packaged asset-এর ভেতর `__pycache__` লিখছিল। এখন bytecode temporary directory-তে
  যায়। Focused suite ও পূর্ণ required CI exact-main run `43362104082`-এ pass।
- Stable publish run `43362569559` exact-main package
  `faa5f0c4733e82fa0e82c88c6a2cd4531a1c3442` sign ও deploy করেছে। Public
  bootstrap, key, `InRelease` এবং `Packages.xz` endpoint HTTP 200; `gpgv`
  signature pinned fingerprint দিয়ে যাচাই করেছে। Native Termux stable index
  নিয়েছে, `ternux` clean uninstall ও install করেছে, `dpkg --verify` এবং default
  plus `db`/`ub`/`alp` verify pass। তিনটি guest আগের PID-তে READY ছিল। GitHub
  tag/release এখনো বাকি।

## Release ধাপ

1. Exact-main Validate run `43362104082`-এ তিন-profile browser matrix,
   focused test, docs/site build, package checks ও repository contract pass করেছে।
2. Reviewed product change merge করে deterministic `.repo/` workflow-কে state
   update বানাতে দাও। `.repo/` হাতে edit করবে না।
3. Signed `/apt-rc` ও stable `/apt` publication, signature/index/checksum,
   native clean package install, guest-specific verify এবং exact-main CI pass
   করেছে। Debian, Ubuntu ও Alpine guest আগের PID-তে installed ও running আছে।
4. Exact validated main commit-এ `v2.0.0` tag ও GitHub release তৈরি করে verified
   Termux package ও checksum attach করুন; এরপর final release report publish
   করুন। Blocking gate অসম্পূর্ণ হলে stable APT workflow publish বন্ধ করে।
5. v2 শেষ হলে পূর্ণ v3 architecture ও acceptance plan প্রকাশ ও review করো। v3
   design v2 deliverable নয়।

## বিস্তারিত audit

- [বর্তমান state ও সিদ্ধান্ত](../../docs/audit/CURRENT-STATE.md)
- [Live device যাচাই](../../docs/audit/DEVICE-VERIFICATION.md)
- [Repository ও প্রকাশনার অবস্থা](../../docs/audit/REPOSITORY-STATE.md)
- [Feature support matrix](../../docs/audit/FEATURE-MATRIX.md)
- [Machine-readable gate](https://github.com/soobujmiah/ternux/blob/main/docs/release-gates.json)

Stable tag, GitHub release, signed APT URL এবং exact release commit না থাকা পর্যন্ত
v2 released বলা যাবে না।
