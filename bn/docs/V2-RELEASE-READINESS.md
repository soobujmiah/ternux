---
title: "Ternux v2.0.0 রিলিজ প্রস্তুতি"
description: "Ternux v2-এর তিনটি supported guest profile-এর বর্তমান acceptance gate ও device evidence।"
lang: "bn"
alt_url: "/docs/V2-RELEASE-READINESS.html"
---

**অবস্থা: stable release প্রকাশের জন্য প্রস্তুত**
**Audit তারিখ:** 2026-11-13
**লক্ষ্য:** Ternux 2.0.0
**সর্বশেষ stable release:** v1.4.0; v2.0.0 stable APT ও GitHub release প্রকাশের ধাপে আছে।

Ternux v2 desktop support কেবল **Debian, Ubuntu ও Alpine**-এর জন্য। CLI-তে
অন্য distro recipe থাকলেও সেগুলো v2-qualified নয়।
[`release-gates.json`](https://github.com/soobujmiah/ternux/blob/main/docs/release-gates.json)-এর 20টি gate বর্তমানে
`READY_FOR_OWNER_APPROVAL`; owner stable release অনুমোদন করেছেন। Signed RC
repository, website redeploy-এ repository preservation এবং native Termux
install/remove/reinstall পরীক্ষা pass। Stable `/apt`, v2 tag ও GitHub release
এখন শেষ publication ধাপ। Current exact-main Validate run `43311661213`
`ca0bba9093ecbe838df4b09f09dfee3197814845` commit-এ pass; তিন-guest browser
matrix `43307868038` run-এ pass করেছে।

## বর্তমান acceptance gate

| Gate | অবস্থা | কী করলে বন্ধ হবে |
|---|---|---|
| P1-03 updater safety | **সম্পূর্ণ** | Source/hash pinning, replace করার আগে staging, interrupted update recovery, downgrade guard, concurrency ও symlink fixture pass; v1.4.0 source fixture থেকে v2 migration pass। প্রকাশিত v2 rollback demonstration আবশ্যক নয়। |
| P1-09 default browser | **সম্পূর্ণ** | Clean Debian Trixie, Ubuntu 24.04 ও Alpine 3.24-এর Firefox X11 window check `f963832fb4acf9c3adb873430408ce21ddd29a37` exact merged-main commit-এর Validate run `43307868038`-এ pass করেছে। Ubuntu Snap ছাড়া Mozilla ESR ব্যবহার করে। |
| P1-APT signed Termux package | **সম্পূর্ণ** | Signed RC public tree ও redeploy-এর পর signature/index/hash pass; native Termux install, repository package replacement, removal এবং no-op upgrade resolution pass। v2.0.0 এই repository-র প্রথম package release, তাই আগের APT version থেকে version-delta upgrade নেই। Evidence `release-gates.json` ও `audit/REPOSITORY-STATE.md`-তে আছে। |

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
  `43307868038`-এ matrix pass করেছে। এই Termux host-এ Docker নেই; তাই local
  container pass দাবি করা হচ্ছে না।
- `bash tests/focused.sh`: audit-এ test-hygiene issue পাওয়া গেছে—`py_compile`
  packaged asset-এর ভেতর `__pycache__` লিখছিল। এখন bytecode temporary directory-তে
  যায়। Focused suite exact merged-main Validate run `43307868038`-এ pass করেছে;
  stable release candidate-এর final CI-ও বাধ্যতামূলক।
- `/apt-rc`-এর public path HTTP 200; InRelease signature publish ও regular
  website redeploy-এর পরেও pinned key দিয়ে valid। Native Termux ওই index থেকে
  package এনেছে। Stable `/apt` ও v2 tag/release এখনো প্রকাশের বাকি।

## Release ধাপ

1. Exact merged-main Validate run `43307868038`-এ তিন-profile browser matrix,
   focused test, docs/site build, package checks, repository contract ও generated state pass করেছে।
2. Reviewed product change merge করে deterministic `.repo/` workflow-কে state
   update বানাতে দাও। `.repo/` হাতে edit করবে না।
3. Signed `/apt-rc`, signature/index/checksum, regular website redeploy, native
   Termux package lifecycle ও exact-main CI pass করেছে। Debian, Ubuntu ও Alpine
   guest installed এবং running আছে।
4. Stable `/apt` প্রকাশ করে native source stable-এ বদলাও, signature/index verify
   করো, তারপর `v2.0.0` tag ও GitHub release তৈরি করো। Blocking gate incomplete
   থাকলে stable APT workflow publish বন্ধ করে।
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
