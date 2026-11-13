---
title: "Ternux v2.0.0 release report"
description: "Ternux v2.0.0 release, package hash, supported guest ও device qualification-এর রেকর্ড।"
lang: "bn"
alt_url: "/docs/V2-RELEASE-REPORT.html"
---

**অবস্থা:** 2026-11-13 05:31 UTC-তে প্রকাশিত
**GitHub release:** [v2.0.0](https://github.com/soobujmiah/ternux/releases/tag/v2.0.0)
**Release tag target:** `9106b04fc8627ae98b1d63c9912a28c8a4677441`
**সমর্থিত desktop guest:** Debian, Ubuntu, Alpine

Ternux 2.0.0 হলো Termux-এর stable desktop release। এতে host CLI-এর জন্য
signed stable APT distribution এবং Debian, Ubuntu ও Alpine desktop profile-এর
সমর্থন ও qualification রয়েছে। Attached Termux package host CLI install করে;
নির্বাচিত guest desktop provision করতে `tx install` চালান।

## Release asset ও install

GitHub release-এ signed APT repository-তে থাকা একই stable package যুক্ত আছে:

- `ternux_2.0.0_all.deb` — SHA-256
  `4ef03210c71e3d5671671e9a49fc83f6aebf7cdb5e5a28cb32db61d49e85c89f`
- `SHA256SUMS` — package checksum manifest।

`pkg install ternux` ব্যবহার করতে প্রথমে signed stable repository একবার
bootstrap করুন:

```sh
pkg install curl gnupg
curl -fsSLo "$TMPDIR/ternux-bootstrap.sh" \
  https://soobujmiah.github.io/ternux/apt/bootstrap.sh
bash "$TMPDIR/ternux-bootstrap.sh"
tx install
```

[Termux APT guide](TERMUX-APT.md)-এ update, key verification এবং আলাদা opt-in
release-candidate channel-এর নির্দেশনা আছে।

## Release যাচাই

- `v2.0.0` tag validated main commit
  `9106b04fc8627ae98b1d63c9912a28c8a4677441`-এ সরাসরি নির্দেশ করে।
- Exact-main Validate run [`43372097795`](https://github.com/soobujmiah/ternux/actions/runs/43372097795), package artifact run
  [`43372097797`](https://github.com/soobujmiah/ternux/actions/runs/43372097797), এবং repository contract run
  [`43372097798`](https://github.com/soobujmiah/ternux/actions/runs/43372097798) release commit-এ pass করেছে।
- Stable APT publish run [`43362569559`](https://github.com/soobujmiah/ternux/actions/runs/43362569559) version 2.0.0 package প্রকাশ করেছে। Signed `InRelease` primary key fingerprint `E5527F4D5B83037FF77B65AE5E894BBB81168B1D` দিয়ে valid। `Packages.xz` SHA-256 `3bbab20f0119b3c038e14c9a49714e499325b0c7036a899c3304e67b3b39e137`।
- Stable repository প্রকাশের পরে routine website deploy [`43371001392`](https://github.com/soobujmiah/ternux/actions/runs/43371001392) stable ও RC—দুই signed APT tree এবং indexed package record যাচাই ও preserve করে website deploy করেছে।
- Native Termux প্রকাশিত package নামিয়েছে; hash signed APT index ও release checksum-এর সঙ্গে মিলেছে। Clean `pkg uninstall`/`pkg install`, `dpkg --verify ternux`, `ternux verify`, এবং Debian/Ubuntu/Alpine guest-specific verification pass করেছে।

## সমর্থিত পরিধি

v2 desktop support কেবল ARM64 Android/Termux-এ Debian, Ubuntu ও Alpine-এর
জন্য। Xiaomi Redmi Turbo 4 Pro, Android 16, SM8735 / Adreno 825-এ device
qualification হয়েছে। CI clean guest lifecycle, Firefox window, release gate,
installer behavior ও documentation build যাচাই করে। Device record-এ তিনটি
চলমান display session, GPU ও audio route, theme, titlebar, viewport fit এবং
input configuration-এর তথ্য আছে।

অন্য named PRoot recipe v2-qualified নয়। HTP/HMX ও QNN image generation এখনো
experimental বা research-only। এই এক device-এর ফল অন্য Android বা GPU family
qualify করে না।

## Input ও UI-এর qualification সীমা

Live Debian `:0`, Ubuntu `:1`, এবং Alpine `:2` session তাদের আগের managed PID-তে
READY ছিল। Runtime query-তে তিন guest-এ Ternux GTK, icon, XFWM theme, `|HMC`
titlebar এবং Ctrl+Space helper binding নিশ্চিত হয়েছে। IBus helper সরাসরি
চালালে তিন guest-এই engine বদলেছে।

Alpine-এর keyboard-event probe-এ ভিন্ন ফল এসেছে: আগের focused GTK/XTest probe
engine বদলেছিল, কিন্তু পরের host-generated Ctrl+Space event এবং temporary GTK
entry probe বদলায়নি। পরের probe-তে Debian ও Ubuntu engine বদলেছে। Config-এ
Ctrl+Space এখনো আছে; Android-এর physical keyboard event delivery certified
নয়। এই সীমাবদ্ধতাকে সফল input test হিসেবে দেখানো হয়নি। GTK/XFCE ও পরীক্ষা করা
Firefox window যাচাই করা হয়েছে; ভবিষ্যতের যেকোনো toolkit বা third-party app-এর
সার্বজনীন theme/behavior guarantee নেই।

## প্রমাণ ও নথি

- [v2 readiness ও acceptance record](V2-RELEASE-READINESS.md)
- [Live device verification](../../docs/audit/DEVICE-VERIFICATION.md)
- [Feature ও qualification matrix](../../docs/audit/FEATURE-MATRIX.md)
- [Repository, APT ও package state](../../docs/audit/REPOSITORY-STATE.md)
- [Machine-readable release gates](https://github.com/soobujmiah/ternux/blob/main/docs/release-gates.json)
