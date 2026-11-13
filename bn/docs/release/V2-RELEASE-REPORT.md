---
title: "Ternux v2.0.0 release ও বর্তমান audit"
description: "প্রকাশিত v2.0.0 release-এর সঙ্গে বর্তমান source, package, CI, website ও device evidence মিলিয়ে তৈরি প্রতিবেদন।"
lang: "bn"
alt_url: "/docs/release/V2-RELEASE-REPORT.html"
---

**Release:** 2026-11-13 05:31 UTC-তে প্রকাশিত  
**Tag target:** `9106b04fc8627ae98b1d63c9912a28c8a4677441`  
**বর্তমান-state audit snapshot:** 2026-11-13 11:04 UTC  
**ওই snapshot-এ main:** `ed326b58d76b8abba05434eb516135b84d7d3858`

এই নথিতে অপরিবর্তনীয় release artifact এবং release-এর পরের source ও device
state আলাদা করে দেখানো হয়েছে। পরের `main`-এর code v2.0.0 package-এ আছে—এমন
দাবি করা হচ্ছে না।

## Release ফল

Ternux v2.0.0 হলো Termux-এর প্রকাশিত stable host CLI ও Linux desktop release।
v2-তে সমর্থিত desktop guest হলো ARM64 Android-এ Debian, Ubuntu ও Alpine।
Debian-এর পরীক্ষার প্রমাণ সবচেয়ে বিস্তৃত; Ubuntu ও Alpine-ও সমর্থিত, তবে
তাদের qualification তুলনামূলক কম বিস্তৃত। Physical device evidence Xiaomi
Redmi Turbo 4 Pro (`25053RT47C`), Android 16, SM8735 / Adreno 825-এ সীমিত।

প্রকাশের সময়কার মূল রেকর্ড [পুরোনো release report](../../../docs/V2-RELEASE-REPORT.md)-এ
রাখা আছে। Machine-readable gate হলো
[repository gate inventory](https://github.com/soobujmiah/ternux/blob/main/docs/release-gates.json),
আর owner-approved পরিধি আছে [release readiness report](../../../docs/V2-RELEASE-READINESS.md)-এ।

## Release package ও repository

- GitHub release: [Ternux v2.0.0](https://github.com/soobujmiah/ternux/releases/tag/v2.0.0)
- Tag target: `9106b04fc8627ae98b1d63c9912a28c8a4677441`
- Package: `ternux_2.0.0_all.deb`
- Package SHA-256: `4ef03210c71e3d5671671e9a49fc83f6aebf7cdb5e5a28cb32db61d49e85c89f`
- `SHA256SUMS` release package-এর checksum manifest।
- Stable Termux APT primary-key fingerprint:
  `E5527F4D5B83037FF77B65AE5E894BBB81168B1D`
- Stable `Packages.xz` SHA-256:
  `3bbab20f0119b3c038e14c9a49714e499325b0c7036a899c3304e67b3b39e137`

`.deb` package Termux host CLI install করে। `pkg install ternux`-এর আগে একবার
signed repository bootstrap করতে হয়; package install-এর পরে নির্বাচিত guest
তৈরি করতে `tx install` চালান। [Signed APT guide](../../docs/TERMUX-APT.md)
দেখুন। Stable repository opt-in RC channel থেকে আলাদা।

## Release যাচাই

- Release commit-এর exact-main `Validate` run
  [`43372097795`](https://github.com/soobujmiah/ternux/actions/runs/43372097795),
  package-artifact run
  [`43372097797`](https://github.com/soobujmiah/ternux/actions/runs/43372097797),
  এবং repository-contract run
  [`43372097798`](https://github.com/soobujmiah/ternux/actions/runs/43372097798)
  pass করেছে।
- Stable APT publication run
  [`43362569559`](https://github.com/soobujmiah/ternux/actions/runs/43362569559)
  version 2.0.0 package ও signed index প্রকাশ করেছে।
- Clean Firefox package/runtime matrix Debian, Ubuntu ও Alpine-এর জন্য pass
  করেছে। এতে অন্য ১২টি named distro recipe qualify হয় না।
- Native Termux package manager দিয়ে package lifecycle যাচাই হয়েছে; package
  integrity ও guest verification command pass করেছে, এবং owner-এর আগের guest
  root ও running session সংরক্ষিত ছিল।
- v2.0.0 release gate হিসেবে v1.4.0 থেকে v2.0.0-তে published rollback demo
  বাধ্যতামূলক নয়। v1.4.0 release artifact এখনো পাওয়া যায়; ভবিষ্যৎ upgrade-এ
  integrity, data protection ও recovery evidence প্রয়োজন।

## Release-এর পর repository ও website snapshot

v2 tag-এর পরে `main` source এগিয়েছে। Product commit
`4b44e5a7799e8518f89edb910c6b7b79f938b6de` দুই homepage-এ curl, wget ও signed
APT setup command, companion-app link এবং v2/v3 status panel যোগ করেছে। এর
main `Validate` run
[`43411550433`](https://github.com/soobujmiah/ternux/actions/runs/43411550433),
package artifact run
[`43411550393`](https://github.com/soobujmiah/ternux/actions/runs/43411550393),
এবং Repo Knowledge Sync run
[`43411550426`](https://github.com/soobujmiah/ternux/actions/runs/43411550426)
pass করেছে। Generated-state PR #201 merge হয়ে
`ed326b58d76b8abba05434eb516135b84d7d3858` হয়েছে। ওই exact main commit-এ
Validate run
[`43412683916`](https://github.com/soobujmiah/ternux/actions/runs/43412683916),
Termux APT artifact run
[`43412683743`](https://github.com/soobujmiah/ternux/actions/runs/43412683743),
এবং repository-state contract run
[`43412683675`](https://github.com/soobujmiah/ternux/actions/runs/43412683675)
pass করেছে।

Pages deployment
[`43411586659`](https://github.com/soobujmiah/ternux/actions/runs/43411586659)
সফলভাবে website প্রকাশ করেছে এবং stable ও RC signed APT repository অক্ষত
রেখেছে। Deploy-এর পর দুই ভাষার homepage-এ curl, wget ও APT copyable command
পাওয়া গেছে; APT bootstrap URL HTTP 200 দিয়েছে। এই deploy website বদলেছে, v2.0.0
package নয়।

## Reference device snapshot

2026-11-13 10:49 UTC-তে installed host package ছিল `ternux 2.0.0`; stable APT
candidate-ও 2.0.0। তিনটি desktop session `READY`: Debian `:0` / PID 18218,
Ubuntu `:1` / PID 14129, Alpine `:2` / PID 26946। প্রতিটি `tx verify` pass
করেছে এবং guest service check ও Turnip payload present জানিয়েছে।

এই command lifecycle/service probe ও driver presence যাচাই করে। এই snapshot-এ
renderer নির্বাচন বা Vulkan workload সম্পন্ন হওয়া প্রমাণ হয় না। আগের GUI
session restart করা হয়নি; camera, microphone, audio playback বা visual app
check-ও আবার চালানো হয়নি। আগের workload evidence ও তার সীমা
[device report](../../../docs/audit/DEVICE-VERIFICATION.md)-এ রাখা আছে।

নতুন read-only manager JSON command `main` source-এ আছে এবং source থেকে চালিয়ে
দেখা হয়েছে। Installed v2.0.0 package-এ module-টি নেই; `tx manager` দিলে
`Unknown command: manager` আসে। Unix-socket manager service বা graphical
Control Center এখনো চলে না। [Implementation status](../../../docs/project/IMPLEMENTATION-STATUS.md)
দেখুন।

## Qualification-এর সীমা

- IBus helper/configuration আছে, তবে Alpine-এর synthetic Ctrl+Space probe-এ
  পরস্পরবিরোধী ফল পাওয়া গেছে; Android physical keyboard যাচাই হয়নি।
- Theme, window-fit ও Firefox titlebar evidence নির্দিষ্ট GTK/XFCE ও পরীক্ষিত
  app-এর; সব toolkit বা ভবিষ্যৎ third-party window-এর নয়।
- `tx verify`-তে Turnip present আসা বর্তমান renderer, Vulkan correctness বা
  performance-এর প্রমাণ নয়।
- সরাসরি `/dev/video*` webcam streaming নেই; Ternux Camera on-demand
  Termux:API still capture ব্যবহার করে।
- HTP/HMX এবং QNN এখনো experimental/research-only। Stable Diffusion CPU/Vulkan
  preview extension। এগুলো stable base feature নয়।
- বাকি ১২টি distro recipe ও অন্য Android device v2-qualified নয়।

## প্রমাণের সূচি

- [বর্তমান v2 ও post-release report](../../docs/release/V2-RELEASE-REPORT.md)
- [Repository-state audit](../../../docs/audit/REPOSITORY-STATE.md)
- [Device-verification record](../../../docs/audit/DEVICE-VERIFICATION.md)
- [Feature matrix](../../../docs/audit/FEATURE-MATRIX.md)
- [বর্তমান project roadmap](../../../docs/project/PROJECT-ROADMAP.md)
- [ঐতিহাসিক v2 release-readiness report](../../../docs/V2-RELEASE-READINESS.md)
