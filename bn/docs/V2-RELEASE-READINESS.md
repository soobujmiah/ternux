---
title: "Ternux v2.0.0 রিলিজ প্রস্তুতি"
description: "Ternux v2-এর তিনটি supported guest profile-এর বর্তমান acceptance gate ও device evidence।"
lang: "bn"
alt_url: "/docs/V2-RELEASE-READINESS.html"
---

## বর্তমান প্রকাশিত v2.0.1 status — 2026-11-20

**v2.0.1 প্রকাশিত হয়েছে** annotated `v2.0.1` tag থেকে, যা source commit
`5be29360c9ca7e4516366711ec09f7a9b4d56940`-এ resolve হয়। GitHub Release-এ
`ternux-v2.0.1-source.tar.gz` ও `SHA256SUMS` আছে; download করা archive-এর SHA-256
`276cf6ffa8cdd3586a358dcf5d2e0f87292d7d7fd29098045a0922259fc7ff7a` মিলে গেছে।
2026-11-14-এ v3 architecture scope-কে v2-তে আনার সিদ্ধান্ত 2026-11-18-এ
প্রত্যাহার করা হয়েছে। v2 বর্তমান implementation-এ frozen; নতুন distro, architecture,
Control Center capability বা APT যোগ হয়নি। বর্তমান owner-confirmed desktop
baseline Debian, Ubuntu, Kali Linux ও Alpine; evidence-এর গভীরতা সমান নয়। [release audit reconciliation](release/V2-RELEASE-RECONCILIATION.md),
[project roadmap](project/PROJECT-ROADMAP.md), [release status](project/RELEASE-STATUS.md),
[feature matrix](../../docs/audit/FEATURE-MATRIX.md) ও [device record](../../docs/audit/DEVICE-VERIFICATION.md)
দেখুন। নিচের 2026-11-16-এর v2.0.0 acceptance তথ্য historical snapshot; এটি
v2.0.1 release readiness নয়।

## প্রকাশের আগের local evidence snapshot — 2026-11-18

- `python3 tests/window_fit_geometry.py`: geometry/state-এর ১৩টি check pass।
- `bash tests/focused.sh`: ২১১ pass, ০ fail।
- `bash tests/update_transaction.sh`: pinned update, 2.0.0→2.0.1 upgrade,
  1.4.0→2.0.1 migration fixture, rollback, interrupted-update recovery,
  concurrency ও symlink safety pass।
- Astro build: ৯০টি static page তৈরি; finalizer ৫৬টি HTML route পেয়েছে।
- `python3 tests/docs_check.py`: ৬,৫১৮ assertion, ৬২১ internal link ও ২৪টি
  bilingual page pair pass। দুই homepage Prettier দিয়ে format করার পর
  `npm run format:check`-ও pass।
- Debian/XFCE live X11 check, display `:1` (640×1386): আগের
  `xdotool windowsize`-ভিত্তিক পরীক্ষাটি pointer দিয়ে window resize করেনি,
  তাই resize আচরণের যথেষ্ট প্রমাণ ছিল না। পরের অংশে নতুন live pointer test আছে।
- `npm audit --json` website build tree-তে Picomatch 4.0.7 ও 2.3.2-এর মাধ্যমে
  ৯টি high-severity dependency path দেখায়। GitHub Advisory Database
  CVE-2026-112366-এ Picomatch 4.0.7 পর্যন্ত affected এবং patched version নেই
  বলেছে; installed Ternux CLI-তে Node dependency নেই। তাই ঝুঁকিটি website
  build toolchain-এ, guest runtime-এ নয়। যাচাইকৃত নিরাপদ fix না থাকায় dependency
  downgrade বা override করা হয়নি; upstream issue অমীমাংসিত। এটি CI/build-chain
  risk, v2 runtime exploit-এর প্রমাণ নয়।

## Live resize correction and X11 stall investigation — 2026-11-18

আগের live test `xdotool windowsize` ব্যবহার করেছিল; pointer দিয়ে resize
করেনি। তাই সেটি resize bug-এর যথেষ্ট প্রমাণ ছিল না। পুনরায় live test-এ দেখা
গেছে, window fitter resize event-এর সময় launch-time minimum size আবার চাপিয়ে
দিচ্ছিল এবং frame coordinate-এর সঙ্গে `StaticGravity` ব্যবহার করছিল। এতে XFWM-এর
সঙ্গে conflict এবং titlebar-এর উচ্চতার সমান position shift হতে পারত।

Local fix-এ minimum size শুধু প্রথম placement-এ প্রয়োগ হয়; interactive resize-এ
user-এর size ও position বজায় থাকে। Frame coordinate-এর জন্য EWMH
`NorthWestGravity` ব্যবহার হয়। Live Debian/XFCE session-এ অস্থায়ী window-কে
client position `(74, 244)`-এ সরিয়ে pointer দিয়ে `280x240` থেকে `340x300`,
তারপর `380x340` করা হয়েছে। প্রতিটি drag-এর পর এবং এক সেকেন্ড অপেক্ষার পরও
position `(74, 244)` ছিল। Resize-এর সময় helper কোনো correction log করেনি।
Candidate helper `tx distro root debian` দিয়ে install, Debian-এ Python syntax
check এবং `tx restart debian` দিয়ে desktop restart করা হয়েছে।

এই পরীক্ষায় X11 stall reproduce হয়নি। Device: Android 16, Xiaomi `25053RT47C`,
F-Droid Termux `0.119.0-beta.3`, Adreno 825, Zink/Turnip। Termux:X11 চলছিল; ৮০টি
X11 request round-trip-এ min 1.41 ms, median 1.84 ms, p95 2.93 ms, max 4.81 ms
পাওয়া গেছে। Sampling-এর সময় Termux:X11-এর RSS প্রায় 228 MiB এবং host-এ প্রায়
4.1 GiB RAM available ছিল। ছোট এই sample intermittent Android scheduling বা
GPU-driver stall-কে বাদ দেয় না। Upstream
[Termux:X11 documentation](https://github.com/termux/termux-x11#avoiding-slowdowns)
বলেছে, আলাদা X11 app foreground-এ থাকলে Android Termux-কে কম CPU time দিতে পারে।
এর shared-UID workaround GitHub-signed Termux চায়; এই F-Droid install-এর সঙ্গে
compatible নয়।

Termux:Boot install করা আছে। এটি boot-এ script চালাতে এবং `termux-wake-lock`
দিয়ে device sleep আটকাতে পারে; কিন্তু চলমান X11/GPU hang বা আলাদা app-এর CPU
scheduling ঠিক করে না। Termux ও Termux:X11-এর battery **Unrestricted** করার
নির্দেশনা [Troubleshooting](TROUBLESHOOTING.md#x11-slows-down-or-stalls)-এ আছে।

শেষ status sample-এ Ternux ও X11 READY/running ছিল, তবে restart-এর পর কিছুক্ষণ
ready থাকার পরে PulseAudio bridge আবার `pulseaudio_ready=no` হয়েছে। এটি resize
test থেকে আলাদা এবং এখনো তদন্তের বিষয়; `tx verify debian` desktop ও GPU check
pass করেছে। Desktop Termux:X11 খোলা রেখে চালু রাখা হয়েছে।

Standalone ও CLI fallback এখন `f7d2a43d97df2bec90cf0a481926e6f57234cbd9`
immutable local source snapshot-এ pin করা। Deterministic source archive-এর
SHA-256 `2924d17dce9a3971c5765b115c81f13c80f2914a3072c6fd627b012201b123b2`;
`TERNUX_SOURCE_ARCHIVE_OVERRIDE=<archive> bash tests/bootstrap_source_sync.sh`
এই archive দিয়ে pass করেছে। আগে প্রকাশিত commit দিয়ে প্রমাণ হয়েছে যে local
`git archive | gzip -n` format GitHub-এর short-SHA codeload archive digest-এর
সঙ্গে মেলে। নতুন snapshot এখনো GitHub-এ নেই, তাই repository synchronization না
হওয়া পর্যন্ত এর live codeload URL যাচাই করা যাবে না; approval-এর পর
exact-commit CI check আবশ্যক।

এই অংশটি 2026-11-18-এর local অবস্থা ধরে, publication-এর আগের historical
evidence। Published commit ও পরবর্তী verification-এর ফল উপরের reconciliation
report-এ আছে।

## Ctrl zoom shortcut সংশোধন — 2026-11-18

Ctrl zoom কাজ না করার live report পুনরায় তৈরি করা হয়েছে। X11 helper-এর
passive key grab keyboard-এর asynchronous mode ব্যবহার করছিল, পরে
`ReplayKeyboard` ডাকত; ফলে ধরা পড়া key focused application-এ পৌঁছাত না। XFCE
Terminal সক্রিয় থাকলে helper font preference save করার পর পরিচিত zoom shortcut
consume করত, তাই খোলা terminal-এর content-ও resize হত না।

Local fix-এ synchronous keyboard grab-এর পর `xfconf-query` preference I/O-র
আগেই প্রতিটি intercepted key replay হয়। তাই settings service ধীর হলেও X11
keyboard আটকে থাকে না। Live Debian session-এর `xev` window Ctrl+Shift+= কে
`plus` এবং Ctrl+- কে `minus` হিসেবে পেয়েছে। Terminal screenshot compare-এ
zoom-in-এর পর 13.55% pixel difference এবং zoom-out-এর পর baseline-এর সঙ্গে exact
pixel match পাওয়া গেছে। চলমান Debian guest-এর helper local file-এর সঙ্গে মেলে;
SHA-256 `db70293cf69ce8e6b8f7a459a95cfb79b8e0d128cbbd429038a4c7d453809c4d`।
`tx restart debian` দিয়ে Debian restart হয়েছে। X11 session READY, তবে
PulseAudio readiness আবার `no` দেখাচ্ছে; এটি আলাদা অমীমাংসিত সমস্যা।

Geometry ও shortcut-এর pure regression suite-এর ১৩টি case এবং full focused
suite-এর **211/211** pass করেছে। `python3 tests/docs_check.py`-এ 6,518টি
assertion, 620টি internal link ও 24টি bilingual page pair pass করেছে।
`tx verify debian` desktop-service ও Turnip check pass করেছে। এই follow-up-এর
exact-commit CI বাকি; এর আগে merge হওয়া main commit
`f7963c6b7bcacf43cabf30a1da3d5bdbf1ebf490`-এ Validate,
Repository State Contract, Termux APT package artifact ও Repo Knowledge Sync
pass করেছে। Local
Termux Node Android C++ runtime symbol mismatch-এর কারণে চালু হয়নি, তাই তার
`npm run format:check` চলেনি; আগের exact-main CI formatter check pass করেছে এবং
এই follow-up-এ website source file বদলায়নি। Intermittent X11 stall পুনরায়
তৈরি হয়নি; আগের স্বল্প সময়ের response measurement এটি বাদ দেওয়ার জন্য
যথেষ্ট নয়। এই fix এখনো local এবং main বা প্রকাশিত v2 artifact-এ নেই।

Standalone installer ও CLI fallback এখন এই সংশোধিত source-কে
`555ce1374957cf35b7a7afa17bbb720b4529d64a` commit-এ pin করে; short-SHA source
archive-এর SHA-256
`b52347389d70314e2b9118528bab3a19cb982b839d3f4627b2d0a66a5493ce83`।
`tests/bootstrap_source_sync.sh` ওই exact archive দিয়ে pass করেছে। Snapshot push
করার পর installer-এর short-SHA GitHub codeload URL একই SHA-256 এবং প্রত্যাশিত
`ternux-555ce13/` archive root দিয়েছে।

Reversible live comparison-এ helper pause রেখে আলাদা Xmessage window খোলা,
সরানো ও 360x220 মাপে resize করা হয়েছে। Helper চলা এবং pause—দুই অবস্থায়
`xdotool` একই সরানো অবস্থান (78,138) ও resize geometry (360x220) দেখিয়েছে;
এই synthetic test-এ move করার পর recenter হওয়ার অভিযোগ পুনরায় দেখা যায়নি।
শেষে helper resume করে চলমান নিশ্চিত করা হয়েছে। Touch-চালিত বা device-specific
XFWM/X11 সমস্যা এই ফল দিয়ে বাদ যায় না। পুরো helper সরালে launch-time fit/clamp
ও Ctrl zoom shortcut-ও হারাবে, তাই helper delete করার পক্ষে এই test প্রমাণ দেয় না।

## Historical v2.0.0 qualification snapshot

**অবস্থা: Public distribution থেকে withdrawn**
**Audit তারিখ:** 2026-11-16
**লক্ষ্য:** Ternux 2.0.0
**v2 GitHub release:** 2026-11-14-এ withdrawn; [provenance-এর জন্য tag রাখা হয়েছে](https://github.com/soobujmiah/ternux/tree/v2.0.0)। Withdrawal run [43532161200](https://github.com/soobujmiah/ternux/actions/runs/43532161200)-এর পর stable APT path HTTP 404; signed RC এখনো আছে।

Ternux v2 desktop support কেবল **Debian, Ubuntu ও Alpine**-এর জন্য; অন্য named
distro recipe v2-qualified নয়। 20-gate inventory pre-publication approval
state রেকর্ড করে; release-এর আগে সব blocking gate pass করেছে। `v2.0.0` source
tag রাখা হয়েছে; GitHub release ও stable APT distribution 2026-11-14-এ withdrawn
হয়েছে। Exact tag, package hash, CI run, support scope ও device limit জানতে
historical [v2.0.0 release report](V2-RELEASE-REPORT.md) দেখুন। Exact-main
Validate run `43372097795` release commit
`9106b04fc8627ae98b1d63c9912a28c8a4677441`-এ pass করেছে।
## বর্তমান acceptance gate

| Gate | অবস্থা | কী করলে বন্ধ হবে |
|---|---|---|
| P1-03 updater safety | **সম্পূর্ণ** | Source/hash pinning, replace করার আগে staging, interrupted update recovery, downgrade guard, concurrency ও symlink fixture pass; v1.4.0 source fixture থেকে v2 migration pass। প্রকাশিত v2 rollback demonstration আবশ্যক নয়। |
| P1-09 default browser | **সম্পূর্ণ** | Clean Debian Trixie, Ubuntu 24.04 ও Alpine 3.24 Firefox X11 window check exact-main Validate run `43372097795`, commit `9106b04fc8627ae98b1d63c9912a28c8a4677441`-এ pass করেছে। Ubuntu Snap ছাড়া Mozilla ESR ব্যবহার করে। |
| P1-APT signed Termux package | **Release-এ pass; channel withdrawn** | Exact main `faa5f0c4733e82fa0e82c88c6a2cd4531a1c3442`-এর stable signed APT publish workflow `43362569559` সফল। Public `InRelease` fingerprint `E5527F4D5B83037FF77B65AE5E894BBB81168B1D` দিয়ে যাচাই হয়েছে; `Packages.xz` SHA-256 `3bbab20f0119b3c038e14c9a49714e499325b0c7036a899c3304e67b3b39e137`, package SHA-256 `4ef03210c71e3d5671671e9a49fc83f6aebf7cdb5e5a28cb32db61d49e85c89f`। Native `pkg update`, clean package uninstall/install, `dpkg --verify`, এবং default/`db`/`ub`/`alp` JSON verify pass। Evidence `release-gates.json` ও `audit/REPOSITORY-STATE.md`-তে আছে। |

HTP/HMX ও QNN experimental বা research-only; stable v2 প্রতিশ্রুতির বাইরে।
CPU/Vulkan দাবি accelerator plan-এ থাকা নির্দিষ্ট model, task ও SM8735/Adreno
825 evidence-এ সীমাবদ্ধ। অন্য guest recipe ও অন্য Android GPU এই gate-এ অন্তর্ভুক্ত
নয়।

## Device evidence

Reference device: Xiaomi 25053RT47C (Redmi Turbo 4 Pro), Android 16, ARM64,
SM8735 / Adreno 825। Debian `:0`, Ubuntu `:1`, Alpine `:2`-এর আগের session-গুলো
Termux:X11 ও PulseAudio route-সহ READY দেখা গেছে। Session চালু রাখা হয়েছে। তিন
guest-এ live Firefox titlebar-এ close control দেখা গেছে। ২০২৬-১১-১৬ তারিখে
ব্যবহারকারী জানান, ইনস্টল করা সব ডিস্ট্রোতে প্রকৃত কিবোর্ড দিয়ে ভাষা বদলানো
যায়। ওই দিন আল্পাইনের `:4` প্রদর্শনে এক্সএফসিই টার্মিনালকে লক্ষ্য করে কৃত্রিম
`Ctrl+Space` সংকেত পাঠালে আইবাস ইঞ্জিন `xkb:us::eng` →
`m17n:bn:avro-phonetic` → `xkb:us::eng` হয়েছে। আগের অমিলটি এই পরীক্ষায় আর
দেখা যায়নি।

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
  plus `db`/`ub`/`alp` verify pass। তিনটি guest আগের PID-তে READY ছিল। GitHub v2.0.0 release ও stable APT channel 2026-11-14-এ withdrawn হয়েছে;
বর্তমান channel status [APT guide](TERMUX-APT.md)-এ দেখুন।

## সম্পন্ন release ধাপ

1. PR #189 English/Bengali install ও release documentation update করেছে; সব check pass করে merge হয়েছে।
2. Repository workflow `.repo/` state PR #190-এ তৈরি করেছে; check pass করে merge হয়েছে, কোনো generated file হাতে edit হয়নি।
3. Stable APT signature/index/package, native package lifecycle, guest-specific verification ও website redeploy-তে signed repository preservation pass করেছে।
4. `v2.0.0` tag validated main `9106b04fc8627ae98b1d63c9912a28c8a4677441`-এ প্রকাশিত।
5. চূড়ান্ত ঐতিহাসিক প্রমাণ [v2.0.0 release report](V2-RELEASE-REPORT.md)-এ আছে। ২০২৬-১১-১৪-এ former v3 scope-কে পরের v2-major release-এ আনার direction ২০২৬-১১-১৮-এ owner প্রত্যাহার করেছেন। বর্তমান পরিকল্পনা [project roadmap](project/PROJECT-ROADMAP.md)-এ আছে।
## বিস্তারিত audit

- [বর্তমান state ও সিদ্ধান্ত](../../docs/audit/CURRENT-STATE.md)
- [Live device যাচাই](../../docs/audit/DEVICE-VERIFICATION.md)
- [Repository ও প্রকাশনার অবস্থা](../../docs/audit/REPOSITORY-STATE.md)
- [Feature support matrix](../../docs/audit/FEATURE-MATRIX.md)
- [Machine-readable gate](https://github.com/soobujmiah/ternux/blob/main/docs/release-gates.json)

`v2.0.0` source tag provenance-এর জন্য রাখা হয়েছে; GitHub release ও signed
stable APT channel withdrawn। 2026-11-14-এ former v3 scope-কে পরের 2.x release-এ
আনার direction 2026-11-18-এ owner প্রত্যাহার করেছেন। ওই requirement আর প্রযোজ্য
নয়; v3 আলাদা future scope। Historical প্রমাণ [release report](V2-RELEASE-REPORT.md)-এ
আছে; বর্তমান scope [project roadmap](project/PROJECT-ROADMAP.md)-এ।

## Candidate follow-up — ২০২৬-১১-১৯

- Live v1.4.0 release page dedicated guide-এ link করে; tag ও codeload archive
  অনুযায়ী guide-এর installer/version command যাচাই হয়েছে। v2.0.1-এর tag,
  Release page, archive বা checksum এখনও নেই।
- Fresh Ubuntu Resolute, Kali rolling ও Alpine v3.24 install `READY` হয়েছে;
  shared PulseAudio route দিয়ে প্রতিটিতে owner-confirmed দুই-সেকেন্ড test tone
  শোনা গেছে। Termux:API companion ও client package installed নিশ্চিত। Local
  detector fallback আগের false negative ঠিক করে; mic/camera permission ও capture
  পরীক্ষা হয়নি।
- `bash tests/focused.sh`: 212/212। `python3 tests/docs_check.py`: 6,638
  assertion, 632 internal link, 24 bilingual pair। Bash syntax ও
  `git diff --check` pass। `tests/bootstrap_source_sync.sh` পুরোনো pinned
  snapshot-এ local URL/digest correction না থাকায় fail; exact source approval-এর
  পরেই pin refresh হবে।
- PR #298-এর বর্তমান shell/documentation job reconciliation header-এর চারটি
  trailing space-এ fail করেছে; local working tree-তে whitespace সরানো হয়েছে।
  Approved repository update-এর পরে hosted check আবার চালাতে হবে।
- LAI adapter ADR এখন rejected history, planned integration নয়। Ternux v3 AI
  design Ternux-owned scope-এর মধ্যে সীমিত।

## Final local pre-release verification — ২০২৬-১১-১৯

- অনুমোদিত `tx uninstall all --yes`-এর পর reference Termux device-এ local
  checkout থেকে Debian, Ubuntu, Kali ও Alpine install হয়েছে। Initial optional
  workload যাচাইয়ের জন্য Ubuntu guest আরও একবার clean করে শুরু থেকে install
  করেছি: প্রথম interactive menu-তেই `jq` select ও confirmation plan-এ দেখা গেছে;
  একই run-এর optional phase-এ `jq 1.8.1-4ubuntu2` install হয়েছে। এই final pass-এ
  resume বা পরে manual package install ব্যবহার হয়নি।
- Ubuntu-র প্রথম চেষ্টায় optional APT phase regular guest user-এর `sudo` দিয়ে
  stdin থেকে setup script পড়ছিল; এতে sudo password prompt loop হতে পারত। Local
  fix optional APT কাজ guest root PRoot login-এ চালায়। Clean first-run retest-এ
  সব install phase complete হয়েছে, `jq --version` দিয়েছে `jq-1.8.1`।
- চার distro-র `tx verify` pass। `tx doctor --json`-এ ৫৪টি OK, warning/failure
  শূন্য, issue নেই। চারটি XFCE session একসঙ্গে READY হয়েছে; `:1`–`:4` display-তে
  সীমিত সময়ের `xdpyinfo` round-trip pass। পুরনো `:4` lock-এর PID পরে IBus process
  reuse করার ঘটনা reproduce হয়েছে; cleanup এখন PID command line যাচাই করে এবং
  ওই display-র matching Termux:X11 server না থাকলেই orphan lock সরায়।
- `bash tests/focused.sh`: ২১৫ pass, ০ fail। Optional-workload PTY regression-এ
  initial menu থেকে navigation ও number entry দিয়ে `jq` নির্বাচন পরীক্ষা হয়;
  live clean-install run-এ নির্বাচিত workload একই install run-এর optional phase-এ
  পৌঁছেছে। `bash -n` এবং `git diff --check` pass।
  `python3 tests/docs_check.py`-এ ৬,৭৬৮ assertion, ৬৪২ internal link ও
  ২৫ bilingual pair pass; `env -u LD_LIBRARY_PATH npm run format:check`-ও pass।
  Live Debian Xfce Terminal move/resize-এ valid user position resize-এর পর
  ও ৫ সেকেন্ড অপেক্ষার পর একই ছিল; Ctrl-minus font 10 থেকে 8.33 করেছে, Ctrl-plus
  আবার 10 করেছে।
- ৩১২-pixel চওড়া X11 root-এ Firefox ৫১০ pixel চওড়াই থেকেছে, কারণ client/window
  manager helper-এর ছোট size request প্রত্যাখ্যান করেছে। Portrait display-তে
  minimum size screen-এর চেয়ে বড় এমন app-এর জন্য এটি live limitation; tested
  terminal recenter হয়েছে—এমন প্রমাণ নয়।
- চার guest-এর PulseAudio route দিয়ে low-volume tone playback command চালানো
  হয়েছে এবং চার route-ই ready। Tone শারীরিকভাবে শোনা গেছে কি না owner confirmation
  অপেক্ষমাণ। Installer এখনও Termux:API companion detect হয়নি বলে warning দিয়েছে,
  যদিও host-এর `cmd package path`, `pm path`, `pm list packages` পরে
  `com.termux.api` নিশ্চিত করেছে। Optional camera/microphone permission probe
  pass দাবি করার আগে এই অমিল তদন্ত করতে হবে; এই run-এ permission/capture পরীক্ষা
  হয়নি।

### ঐচ্ছিক workload-এর live qualification — ২০২৬-১১-১৯

- Blender + Ternux ADT Build Tools—এই exact জোড়া interactive selector-এ
  চালানো হয়েছে। PTY regression-এ numeric list-এর space-কে Space-toggle হিসেবে
  ভুল বোঝার bug ধরা ও ঠিক করা হয়েছে; এখন জোড়াটি ঠিক
  `blender,adt-build-tools` হিসেবে phase-এ যায়। ADT command-line setup-এর আগে
  guest root হিসেবে JDK, curl, git ও unzip prerequisite install হয়।
- Debian, Ubuntu Resolute ও Kali rolling-এ local phase Blender + Xvfb এবং
  Ternux-এর ADT command-line/build-tools install করেছে। চার guest-এর active Xfce display-তে Blender GUI open ও close smoke test pass।
  Debian, Ubuntu ও Kali-তে Java, `sdkmanager --version`, ADT `aapt2 version` এবং
  চারটিতেই `xvfb-run`-এর অধীনে Blender background smoke test pass। Kali Blender
  5.2 asset add-on-এ প্রথমে `cattrs` ও `requests` missing ছিল; recipe এখন
  `python3-cattr` ও `python3-requests` install করে, clean GUI smoke-এ ওই import
  error আর দেখা যায়নি।
- Alpine v3.24-এ APK দিয়ে Blender workload চলে। Recipe Blender, Xvfb,
  `xvfb-run` ও NumPy install করে; `xvfb-run`-এর অধীনে Blender background ও Xfce GUI smoke test pass; Alpine-এ `py3-requests`-ও যোগ হয়। Alpine-এর musl JDK PRoot-এ “Failed to mark memory page as
  executable” দিয়ে ব্যর্থ হয়; ADT build-tools-এর `aapt2` Alpine-এ অনুপস্থিত
  glibc symbol চায়। `gcompat` পরীক্ষা করেও missing symbol ঠিক হয়নি। তাই Alpine
  selector/installer-এ এখন শুধু Blender দেখায় এবং ADT guest পরিবর্তনের আগেই
  reject করে। আগের compatibility probe-এ Alpine-এ ADT file ও Java package
  install হয়েছিল; স্বচ্ছতার জন্য guest-এ রেখে দেওয়া হয়েছে, মুছে ফেলা হয়নি।
- শেষ Alpine selector, APK recipe, ADT preflight guard ও Blender Python-module
  dependency edit-সহ `bash tests/focused.sh`: 219 pass, 0 fail।
- সব baseline distro-তে Blender + ADT smooth install-এর owner request আংশিক
  পূরণ: তিন APT guest pass; Alpine-এ Blender pass হলেও বর্তমান musl/PRoot runtime-এ
  ADT technically incompatible। এটি owner-visible v2 qualification limitation;
  সব distro-তে ADT pass—এমন দাবি নয়।


## প্রকাশনা যাচাই — 2026-11-19

- Annotated `v2.0.1` tag `5be29360c9ca7e4516366711ec09f7a9b4d56940` commit-এ resolve হয়।
- প্রকাশের আগে exact-commit Validate, repository-state contract ও Termux APT artifact check pass করেছে।
- প্রকাশিত `ternux-v2.0.1-source.tar.gz`-এর SHA-256 `276cf6ffa8cdd3586a358dcf5d2e0f87292d7d7fd29098045a0922259fc7ff7a`; download করা manifest মিলে গেছে।
- GitHub Release-এ শুধু source archive ও checksum manifest আছে। Stable APT withdrawn-ই আছে।
